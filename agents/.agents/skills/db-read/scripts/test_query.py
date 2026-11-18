"""Offline safety tests. Never connect to live databases."""
import contextlib
import io
import json
import ssl
import subprocess
import tempfile
from pathlib import Path
import unittest
from unittest.mock import MagicMock, patch

import pymysql
import query


class QueryTests(unittest.TestCase):
    def test_allowed_queries(self):
        for sql in [
            "SELECT 1", "SELECT id, status FROM offers WHERE property_id = 123 LIMIT 10",
            "SELECT status, COUNT(*) FROM offers GROUP BY status",
            "WITH x AS (SELECT id FROM offers) SELECT * FROM x",
            "SELECT id FROM a UNION ALL SELECT id FROM b",
            "SELECT a.id FROM a JOIN b ON a.id=b.id WHERE a.id IN (SELECT id FROM c)",
            "SELECT NOW(), COALESCE(x,0), JSON_EXTRACT(doc, '$.status') FROM t",
            "SELECT table_name FROM information_schema.tables WHERE table_schema='example'",
            "SELECT 'DELETE; -- this is a literal'", "SELECT 1;",
        ]:
            with self.subTest(sql=sql):
                self.assertTrue(query.prepare_sql(sql))

    def test_rejected_before_credentials(self):
        forbidden = [
            "DELETE FROM t", "UPDATE t SET a=1", "INSERT INTO t VALUES(1)",
            "DROP TABLE t", "CREATE TEMPORARY TABLE t(a INT)", "CALL proc()",
            "SET autocommit=1", "COMMIT", "START TRANSACTION READ WRITE",
            "SELECT 1; DELETE FROM t", "SELECT * FROM t FOR UPDATE",
            "SELECT * FROM t LOCK IN SHARE MODE", "SELECT 1 INTO OUTFILE '/tmp/a'",
            "SELECT 1 INTO DUMPFILE '/tmp/a'", "SELECT 1 INTO @x", "SELECT @x:=1",
            "SELECT @@session.sql_mode", "SELECT LOAD_FILE('/tmp/a')", "SELECT SLEEP(1)",
            "SELECT BENCHMARK(10,1)", "SELECT GET_LOCK('x',1)", "SELECT RELEASE_LOCK('x')",
            "SELECT unknown_func()", "SELECT db.COUNT(*)", "SELECT db.foo()",
            "SELECT /*+ MAX_EXECUTION_TIME(0) */ 1", "SELECT 1 /*! INTO OUTFILE '/tmp/a' */",
            "/*!50000 SELECT 1 */", "SELECT /* harmless */ 1", "EXPLAIN ANALYZE SELECT 1",
            "SHOW PROCESSLIST", "SELECT * FROM t LIMIT @x", "nonsense",
            "SELECT * FROM (SELECT SLEEP(2)) x", "WITH x AS (DELETE FROM t) SELECT * FROM x",
        ]
        with patch.object(query.dqs_credentials, "load_credentials") as credentials:
            for sql in forbidden:
                for mode in ({}, {"raw": True}, {"fetch_all": True}):
                    with self.subTest(sql=sql, mode=mode), self.assertRaises(query.SafeError):
                        query.investigate(sql, io.StringIO(), db_key="example", **mode)
            credentials.assert_not_called()

    def test_limits_and_raw_preservation(self):
        self.assertTrue(query.prepare_sql("SELECT 1").endswith("LIMIT 10001"))
        for n in (0, 3, 10000):
            self.assertTrue(query.prepare_sql(f"SELECT 1 LIMIT {n}").endswith(f"LIMIT {n}"))
        self.assertTrue(query.prepare_sql("SELECT 1 LIMIT 99999").endswith("LIMIT 10001"))
        for sql in ("SELECT id FROM t LIMIT 3 OFFSET 2", "SELECT id FROM t LIMIT 2, 3"):
            self.assertEqual(query.prepare_sql(sql), "SELECT id FROM t LIMIT 3 OFFSET 2")
        self.assertEqual(query.prepare_sql("SELECT 1", fetch_all=True), "SELECT 1")
        self.assertEqual(query.prepare_sql("SELECT 1 LIMIT 20000", fetch_all=True), "SELECT 1 LIMIT 20000")
        sql = "  select id FROM t limit 2, 3;\n"
        self.assertEqual(query.prepare_sql(sql, raw=True), sql)
        for raw in (False, True):
            with self.assertRaises(query.SafeError):
                query.prepare_sql("SELECT SLEEP(1)", raw=raw)

    def fake_connection(self, rows=None, tls=True, readonly=True):
        connection = MagicMock()
        setup, stream = MagicMock(), MagicMock()
        connection.cursor.side_effect = [setup, stream]
        setup.fetchone.side_effect = [("Ssl_cipher", "TLS_CIPHER" if tls else ""), (int(readonly),)]
        stream.description = [("value",)]
        rows = rows if rows is not None else [(1,)]
        batches = [rows[i:i + query.BATCH_SIZE] for i in range(0, len(rows), query.BATCH_SIZE)]
        stream.fetchmany.side_effect = batches + [[]]
        connection.setup_cursor = setup
        connection.stream_cursor = stream
        return connection

    def run_fake(self, connection, sql="SELECT 1", **kwargs):
        fields = {"hostname": "HOST_SENTINEL", "username": "USER_SENTINEL", "password": "PASSWORD_SENTINEL"}
        output = io.StringIO()
        with patch.object(query.dqs_credentials, "load_credentials", return_value=(fields, 3306)), \
             patch.object(query.pymysql, "connect", return_value=connection) as connect:
            query.investigate(sql, output, db_key="example", **kwargs)
            context = connect.call_args.kwargs["ssl"]
            self.assertEqual(context.verify_mode, ssl.CERT_NONE)
            self.assertFalse(context.check_hostname)
            self.assertFalse(connect.call_args.kwargs["local_infile"])
            return json.loads(output.getvalue())

    def test_session_setup_and_cleanup(self):
        connection = self.fake_connection()
        result = self.run_fake(connection)
        executed = [call.args[0] for call in connection.setup_cursor.execute.call_args_list]
        self.assertIn("SET SESSION max_execution_time = 10000", executed)
        self.assertEqual(executed[-1], "START TRANSACTION READ ONLY")
        connection.stream_cursor.execute.assert_called_once_with("SELECT 1 LIMIT 10001")
        self.assertEqual(connection.cursor.call_args.args, (query.pymysql.cursors.SSCursor,))
        self.assertTrue(result["read_only"])
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_tls_and_readonly_failure_close(self):
        for kwargs in ({"tls": False}, {"readonly": False}):
            connection = self.fake_connection(**kwargs)
            with self.assertRaises(query.SafeError):
                self.run_fake(connection)
            connection.close.assert_called_once()
            connection.stream_cursor.execute.assert_not_called()

    def test_error_suppression_and_cleanup(self):
        connection = self.fake_connection()
        connection.setup_cursor.execute.side_effect = pymysql.OperationalError(2013, "PASSWORD_SENTINEL USER_SENTINEL HOST_SENTINEL")
        with self.assertRaises(query.SafeError) as caught:
            self.run_fake(connection)
        self.assertNotIn("SENTINEL", str(caught.exception))
        self.assertIn("2013", str(caught.exception))
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_row_boundaries_and_batches(self):
        for size in (0, 1000, 10000, 10001):
            connection = self.fake_connection([(i,) for i in range(size)])
            result = self.run_fake(connection)
            self.assertEqual(result["rows"], [[i] for i in range(min(size, 10000))])
            self.assertEqual(result["row_count"], min(size, 10000))
            self.assertEqual(result["truncated"], size > 10000)
            self.assertEqual("hint" in result, size > 10000)
            self.assertTrue(all(c.args == (1000,) for c in connection.stream_cursor.fetchmany.call_args_list))
            connection.stream_cursor.execute.assert_called_once()

    def test_unbounded_modes_and_explain(self):
        for mode in ({"fetch_all": True}, {"raw": True}, {"explain": True}):
            connection = self.fake_connection([(1,)] * 10005)
            result = self.run_fake(connection, **mode)
            self.assertEqual(result["row_count"], 10005)
            self.assertFalse(result["truncated"])
            expected = "EXPLAIN SELECT 1 LIMIT 10001" if mode.get("explain") else "SELECT 1"
            connection.stream_cursor.execute.assert_called_once_with(expected)
        connection = self.fake_connection()
        sql = "  select 1;\n"
        self.run_fake(connection, sql=sql, raw=True)
        connection.stream_cursor.execute.assert_called_once_with(sql)
        self.assertEqual(connection.setup_cursor.execute.call_count, 7)

    def test_result_redaction_and_large_output(self):
        result = self.run_fake(self.fake_connection([("PASSWORD_SENTINEL USER_SENTINEL HOST_SENTINEL",)]))
        self.assertNotIn("SENTINEL", json.dumps(result))
        value = "x" * (1024 * 1024 + 1)
        result = self.run_fake(self.fake_connection([(value,)]))
        self.assertFalse(result["truncated"])
        self.assertEqual(result["rows"], [[value]])

    def test_cli_rejects_removed_options_and_conflicts(self):
        for args in (["--target", "dqs"], ["--credential-role", "rw"],
                     ["--kvm-host", "host"], ["--raw", "--fetch-all"],
                     ["--raw", "--explain"], ["--check"]):
            with self.subTest(args=args), patch("sys.argv", ["query.py", "--db-key", "example", *args]), \
                 patch.object(query, "run_offline_tests") as tests, \
                 contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                query.main()
            tests.assert_not_called()

    def test_cli_tests_precede_investigation_in_every_mode(self):
        for mode in ([], ["--raw"], ["--fetch-all"], ["--explain"]):
            events = []
            def investigate(sql, output, **kwargs):
                events.append("query")
                output.write('{"rows":[]}')
            with patch("sys.argv", ["query.py", "--db-key", "example", *mode]), \
                 patch("sys.stdin", io.StringIO("SELECT 1")), \
                 patch.object(query, "run_offline_tests", side_effect=lambda: events.append("tests")), \
                 patch.object(query, "investigate", side_effect=investigate), \
                 contextlib.redirect_stdout(io.StringIO()) as output:
                self.assertEqual(query.main(), 0)
            self.assertEqual(events, ["tests", "query"])
            self.assertEqual(json.loads(output.getvalue()), {"rows": []})

    def test_preflight_failures(self):
        for response in (MagicMock(returncode=1), subprocess.TimeoutExpired("tests", 60)):
            with patch.object(query.subprocess, "run") as run:
                if isinstance(response, Exception):
                    run.side_effect = response
                else:
                    run.return_value = response
                with self.assertRaises(query.SafeError):
                    query.run_offline_tests()
        with patch.object(Path, "is_file", return_value=False), \
             patch.object(query.subprocess, "run") as run, self.assertRaises(query.SafeError):
            query.run_offline_tests()
        run.assert_not_called()
        with patch.object(query.subprocess, "run", return_value=MagicMock(returncode=0)) as run:
            query.run_offline_tests()
            self.assertEqual(run.call_args.args[0], [query.sys.executable, "-m", "unittest", "test_dqs_credentials", "test_query"])

    def test_failed_preflight_prevents_credentials(self):
        with patch("sys.argv", ["query.py", "--db-key", "example"]), \
             patch.object(query, "run_offline_tests", side_effect=query.SafeError("Offline tests failed")), \
             patch.object(query.dqs_credentials, "load_credentials") as credentials, \
             contextlib.redirect_stdout(io.StringIO()) as output, \
             contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(query.main(), 1)
        credentials.assert_not_called()
        self.assertEqual(output.getvalue(), "")

    def test_staging_failure_rolls_back_and_closes(self):
        connection = self.fake_connection()
        output = MagicMock()
        output.write.side_effect = OSError("private path")
        with patch.object(query.dqs_credentials, "load_credentials", return_value=({"hostname": "h", "username": "u", "password": "p"}, 3306)), \
             patch.object(query.pymysql, "connect", return_value=connection), \
             self.assertRaises(query.SafeError) as caught:
            query.investigate("SELECT 1", output, db_key="example")
        self.assertNotIn("private path", str(caught.exception))
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_fetch_failure_emits_no_partial_result_and_closes_staging(self):
        connection = self.fake_connection()
        connection.stream_cursor.fetchmany.side_effect = [[(1,)], pymysql.OperationalError(2013, "SECRET")]
        with tempfile.TemporaryFile(mode="w+", encoding="utf-8") as staged:
            with patch("sys.argv", ["query.py", "--db-key", "example"]), \
                 patch.object(query, "run_offline_tests"), \
                 patch("sys.stdin", io.StringIO("SELECT 1")), \
                 patch.object(query.dqs_credentials, "load_credentials", return_value=({"hostname": "h", "username": "u", "password": "p"}, 3306)), \
                 patch.object(query.pymysql, "connect", return_value=connection), \
                 patch.object(query.tempfile, "TemporaryFile", return_value=staged), \
                 contextlib.redirect_stdout(io.StringIO()) as output, \
                 contextlib.redirect_stderr(io.StringIO()) as error:
                self.assertEqual(query.main(), 1)
            self.assertTrue(staged.closed)
        self.assertEqual(output.getvalue(), "")
        self.assertNotIn("SECRET", error.getvalue())
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()


if __name__ == "__main__":
    unittest.main()
