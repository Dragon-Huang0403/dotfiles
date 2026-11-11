"""Offline credential selection and disclosure checks."""
import contextlib
import io
import json
import unittest
from unittest.mock import MagicMock, patch

import kvm
import query


class KvmTests(unittest.TestCase):
    def setUp(self):
        self.entry = {"host": "HOST_SENTINEL", "username": "USER_SENTINEL",
                      "password": "PASSWORD_SENTINEL", "database": "example"}
        self.databases = {"example": {"ro": {"roster": "ROSTER_SENTINEL"}, "rw": self.entry}}

    def test_host_defaults_to_environment_and_allows_override(self):
        result = MagicMock(returncode=0, stdout=json.dumps({"database": self.databases}))
        with patch.dict(kvm.os.environ, {"KVM": "environment-kvm"}), \
             patch.object(kvm.subprocess, "run", return_value=result) as run:
            kvm.load_databases()
            self.assertEqual(run.call_args.args[0][-2], "environment-kvm")
            kvm.load_databases("override-kvm")
            self.assertEqual(run.call_args.args[0][-2], "override-kvm")

    def test_missing_environment_fails_before_ssh(self):
        for environment in ({}, {"KVM": ""}):
            with patch.dict(kvm.os.environ, environment, clear=True), \
                 patch.object(kvm.subprocess, "run") as run, \
                 self.assertRaises(kvm.CredentialError) as caught:
                kvm.load_databases()
            run.assert_not_called()
            self.assertIn(".booking.zshrc", str(caught.exception))

    def test_no_automatic_rw_fallback(self):
        with patch.object(kvm, "load_databases", return_value=self.databases):
            with self.assertRaises(kvm.CredentialError):
                kvm.credentials("example")
            fields, port = kvm.credentials("example", role="rw")
            self.assertEqual(fields["hostname"], self.entry["host"])
            self.assertEqual(port, 3306)
            with self.assertRaises(kvm.CredentialError):
                kvm.credentials("missing", role="rw")

    def test_listing_only_prints_keys(self):
        output = io.StringIO()
        with patch.object(kvm, "load_databases", return_value=self.databases), \
             patch("sys.argv", ["kvm.py"]), contextlib.redirect_stdout(output):
            self.assertEqual(kvm.main(), 0)
        self.assertEqual(json.loads(output.getvalue()), {"databases": ["example"]})

    def test_failures_do_not_leak_credentials(self):
        for status, payload in [(1, "PASSWORD_SENTINEL"), (0, "PASSWORD_SENTINEL"), (0, '{}')]:
            result = MagicMock(returncode=status, stdout=payload, stderr="PASSWORD_SENTINEL")
            with patch.object(kvm.subprocess, "run", return_value=result), \
                 self.assertRaises(kvm.CredentialError) as caught:
                kvm.load_databases("test-kvm")
            self.assertNotIn("SENTINEL", str(caught.exception))
            self.assertIn("ssh -A ssh.booking.com", str(caught.exception))

    def test_dqs_validates_sql_before_ssh(self):
        with patch.object(kvm, "load_databases") as load, self.assertRaises(query.SafeError):
            query.investigate("dqs", "DELETE FROM t", db_key="example", credential_role="rw")
        load.assert_not_called()

    def test_dqs_uses_same_readonly_session(self):
        connection = MagicMock()
        cursor = connection.cursor.return_value
        cursor.fetchone.side_effect = [("Ssl_cipher", "TLS_CIPHER"), (1,)]
        cursor.description = [("value",)]
        cursor.fetchmany.return_value = [(1,)]
        with patch.object(kvm, "load_databases", return_value=self.databases), \
             patch.object(query.pymysql, "connect", return_value=connection):
            result = query.investigate("dqs", "SELECT 1", db_key="example", credential_role="rw")
        self.assertTrue(result["read_only"])
        statements = [call.args[0] for call in cursor.execute.call_args_list]
        self.assertLess(statements.index("START TRANSACTION READ ONLY"), statements.index("SELECT 1 LIMIT 201"))
        connection.rollback.assert_called_once()
        connection.close.assert_called_once()


if __name__ == "__main__":
    unittest.main()
