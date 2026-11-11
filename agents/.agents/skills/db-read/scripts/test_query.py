"""Offline safety tests. Never connect to production."""
import contextlib
import io
import json
import ssl
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
                self.assertTrue(query.validate_sql(sql))

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
        with patch.object(query, "get_credentials") as credentials:
            for sql in forbidden:
                with self.subTest(sql=sql), self.assertRaises(query.SafeError):
                    query.investigate("ppo", sql)
            credentials.assert_not_called()

    def test_limits(self):
        self.assertTrue(query.validate_sql("SELECT 1").endswith("LIMIT 201"))
        self.assertTrue(query.validate_sql("SELECT 1 LIMIT 3").endswith("LIMIT 3"))
        self.assertTrue(query.validate_sql("SELECT 1 LIMIT 9999").endswith("LIMIT 201"))

    def fake_connection(self, rows=None, tls=True, readonly=True):
        connection = MagicMock()
        cursor = connection.cursor.return_value
        cursor.fetchone.side_effect = [("Ssl_cipher", "TLS_CIPHER" if tls else ""), (int(readonly),)]
        cursor.description = [("value",)]
        cursor.fetchmany.return_value = rows if rows is not None else [(1,)]
        return connection

    def run_fake(self, connection, **kwargs):
        fields = {"hostname": "HOST_SENTINEL", "username": "USER_SENTINEL", "password": "PASSWORD_SENTINEL"}
        with patch.object(query, "get_credentials", return_value=(fields, 3306)), \
             patch.object(query.pymysql, "connect", return_value=connection) as connect:
            result = query.investigate("ppo", "SELECT 1", **kwargs)
            context = connect.call_args.kwargs["ssl"]
            self.assertEqual(context.verify_mode, ssl.CERT_NONE)
            self.assertFalse(context.check_hostname)
            self.assertFalse(connect.call_args.kwargs["local_infile"])
            return result

    def test_session_setup_and_cleanup(self):
        connection = self.fake_connection()
        result = self.run_fake(connection)
        executed = [call.args[0] for call in connection.cursor.return_value.execute.call_args_list]
        self.assertIn("SET SESSION max_execution_time = 10000", executed)
        self.assertLess(executed.index("START TRANSACTION READ ONLY"), executed.index("SELECT 1 LIMIT 201"))
        self.assertTrue(result["read_only"])
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_tls_and_readonly_failure_close(self):
        for kwargs in ({"tls": False}, {"readonly": False}):
            connection = self.fake_connection(**kwargs)
            with self.assertRaises(query.SafeError):
                self.run_fake(connection)
            connection.close.assert_called_once()
            self.assertNotIn("SELECT 1 LIMIT 201", [c.args[0] for c in connection.cursor.return_value.execute.call_args_list])

    def test_error_suppression_and_cleanup(self):
        connection = self.fake_connection()
        connection.cursor.return_value.execute.side_effect = pymysql.OperationalError(2013, "PASSWORD_SENTINEL USER_SENTINEL HOST_SENTINEL")
        with self.assertRaises(query.SafeError) as caught:
            self.run_fake(connection)
        self.assertNotIn("SENTINEL", str(caught.exception))
        self.assertIn("2013", str(caught.exception))
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()

    def test_result_redaction_and_caps(self):
        result = self.run_fake(self.fake_connection([("PASSWORD_SENTINEL USER_SENTINEL HOST_SENTINEL",)] * 201))
        self.assertTrue(result["truncated"])
        self.assertEqual(len(result["rows"]), 200)
        self.assertNotIn("SENTINEL", json.dumps(result))
        result = self.run_fake(self.fake_connection([("x" * query.MAX_BYTES,)]))
        self.assertTrue(result["truncated"])
        self.assertLessEqual(len(json.dumps(result).encode()), query.MAX_BYTES)

    def test_1password_errors_never_emit_output(self):
        for payload, status in [("PASSWORD_SENTINEL", 1), ("PASSWORD_SENTINEL", 0), ('{"fields":[]}', 0)]:
            process = MagicMock(returncode=status, stdout=payload, stderr="PASSWORD_SENTINEL")
            captured = io.StringIO()
            with patch.object(query.subprocess, "run", return_value=process), \
                 contextlib.redirect_stdout(captured), contextlib.redirect_stderr(captured):
                with self.assertRaises(query.SafeError) as caught:
                    query.get_credentials("pay")
            self.assertEqual(captured.getvalue(), "")
            self.assertNotIn("SENTINEL", str(caught.exception))


if __name__ == "__main__":
    unittest.main()
