"""Offline credential selection and disclosure checks."""
import contextlib
import io
import json
import unittest
from unittest.mock import MagicMock, patch

import dqs_credentials
import query


class CredentialTests(unittest.TestCase):
    def setUp(self):
        self.entry = {"host": "HOST_SENTINEL", "username": "USER_SENTINEL",
                      "password": "PASSWORD_SENTINEL", "database": "example"}
        self.databases = {"example": {"ro": {"roster": "ROSTER_SENTINEL"}, "rw": self.entry}}

    def test_host_comes_only_from_kvm_host(self):
        result = MagicMock(returncode=0, stdout=json.dumps({"database": self.databases}))
        with patch.dict(dqs_credentials.os.environ, {"KVM_HOST": "environment-kvm", "KVM": "old-kvm"}), \
             patch.object(dqs_credentials.subprocess, "run", return_value=result) as run:
            dqs_credentials._load_credential_entries()
            self.assertEqual(run.call_args.args[0][-2], "environment-kvm")

    def test_missing_or_invalid_environment_fails_before_ssh(self):
        for environment in ({}, {"KVM": "old-kvm"}, {"KVM_HOST": ""},
                            {"KVM_HOST": "-option"}, {"KVM_HOST": "two hosts"}):
            with patch.dict(dqs_credentials.os.environ, environment, clear=True), \
                 patch.object(dqs_credentials.subprocess, "run") as run, \
                 self.assertRaises(dqs_credentials.CredentialError) as caught:
                dqs_credentials._load_credential_entries()
            run.assert_not_called()
            self.assertIn("KVM_HOST", str(caught.exception))

    def test_fixed_rw_credentials_and_no_fallback(self):
        with patch.object(dqs_credentials, "_load_credential_entries", return_value=self.databases):
            fields, port = dqs_credentials.load_credentials("example")
            self.assertEqual(fields["hostname"], self.entry["host"])
            self.assertEqual(port, 3306)
            with self.assertRaises(dqs_credentials.CredentialError):
                dqs_credentials.load_credentials("missing")
        for entry in ({"ro": self.entry}, {"rw": {"roster": "roster"}}, {"rw": None}):
            with patch.object(dqs_credentials, "_load_credential_entries", return_value={"example": entry}), \
                 self.assertRaises(dqs_credentials.CredentialError):
                dqs_credentials.load_credentials("example")

    def test_listing_only_prints_keys(self):
        output = io.StringIO()
        with patch.object(dqs_credentials, "_load_credential_entries", return_value=self.databases), \
             patch("sys.argv", ["dqs_credentials.py", "--list"]), contextlib.redirect_stdout(output):
            self.assertEqual(dqs_credentials.main(), 0)
        self.assertEqual(json.loads(output.getvalue()), {"database_keys": ["example"]})

    def test_failures_do_not_leak_credentials(self):
        for status, payload in [(1, "PASSWORD_SENTINEL"), (0, "PASSWORD_SENTINEL"), (0, '{}')]:
            result = MagicMock(returncode=status, stdout=payload, stderr="PASSWORD_SENTINEL")
            with patch.dict(dqs_credentials.os.environ, {"KVM_HOST": "test-kvm"}), \
                 patch.object(dqs_credentials.subprocess, "run", return_value=result), \
                 self.assertRaises(dqs_credentials.CredentialError) as caught:
                dqs_credentials._load_credential_entries()
            self.assertNotIn("SENTINEL", str(caught.exception))
            if status:
                self.assertIn("ssh -A ssh.booking.com", str(caught.exception))
            else:
                self.assertIn("invalid credential document", str(caught.exception))

    def test_listing_requires_explicit_flag_before_ssh(self):
        with patch("sys.argv", ["dqs_credentials.py"]), \
             patch.object(dqs_credentials, "_load_credential_entries") as load, \
             contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
            dqs_credentials.main()
        load.assert_not_called()

    def test_port_validation(self):
        for value in ("3307", 3307):
            entry = {**self.entry, "port": value}
            with patch.object(dqs_credentials, "_load_credential_entries", return_value={"example": {"rw": entry}}):
                self.assertEqual(dqs_credentials.load_credentials("example")[1], 3307)
        for value in (0, -1, 65536, True, 3.5, "bad", None):
            entry = {**self.entry, "port": value}
            with patch.object(dqs_credentials, "_load_credential_entries", return_value={"example": {"rw": entry}}), \
                 self.assertRaises(dqs_credentials.CredentialError):
                dqs_credentials.load_credentials("example")

    def test_dqs_validates_sql_before_ssh(self):
        with patch.object(dqs_credentials, "_load_credential_entries") as load, self.assertRaises(query.SafeError):
            query.investigate("DELETE FROM t", io.StringIO(), db_key="example")
        load.assert_not_called()

if __name__ == "__main__":
    unittest.main()
