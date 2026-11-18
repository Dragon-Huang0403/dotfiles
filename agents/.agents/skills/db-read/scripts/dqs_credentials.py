"""List DQS database credential keys; retrieve connection secrets privately."""

import argparse
import json
import os
import subprocess
import sys


class CredentialError(Exception):
    """A sanitized credential error safe to report to the caller."""


def _load_credential_entries():
    """Read the credential document over SSH without exposing its contents."""
    host = os.environ.get("KVM_HOST")
    if not host:
        raise CredentialError("KVM_HOST is unset or empty; export it before running the helper.")
    if host.startswith("-") or any(c.isspace() for c in host):
        raise CredentialError("Invalid KVM_HOST.")

    try:
        result = subprocess.run(
            [
                "ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", host,
                "cat /var/run/secrets/booking.com/db.json",
            ],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        if result.returncode:
            raise ValueError()
    except Exception:
        raise CredentialError(
            "KVM credential lookup failed. If sandbox access was denied, retry with network approval. "
            "Otherwise run ssh -A ssh.booking.com interactively to refresh SSH fingerprint/access, "
            "then retry. Raw output suppressed."
        ) from None

    try:
        entries = json.loads(result.stdout)["database"]
        if not isinstance(entries, dict) or not entries:
            raise ValueError()
        return entries
    except Exception:
        raise CredentialError("KVM returned an empty or invalid credential document; raw output suppressed.") from None


def load_credentials(key):
    """Return the fixed rw entry and port; callers must enforce read-only SQL."""
    database = _load_credential_entries().get(key)
    entry = database.get("rw") if isinstance(database, dict) else None
    if not isinstance(entry, dict):
        raise CredentialError("Database key or rw credentials are unavailable; list database keys first.")
    if not entry.get("host"):
        raise CredentialError("DQS rw credentials have no direct host.")
    required_fields = ("host", "username", "password", "database")
    if not all(isinstance(entry.get(k), str) and entry[k] for k in required_fields):
        raise CredentialError("KVM credentials lack required connection fields.")
    try:
        value = entry.get("port", 3306)
        if isinstance(value, bool) or not str(value).isdigit():
            raise ValueError()
        port = int(value)
        if not 1 <= port <= 65535:
            raise ValueError()
    except (TypeError, ValueError):
        raise CredentialError("KVM credentials contain an invalid port.") from None
    return {
        "hostname": entry["host"],
        "username": entry["username"],
        "password": entry["password"],
        "database": entry["database"],
    }, port


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--list", action="store_true", required=True,
        help="List credential keys accepted by query.py --db-key (not schemas)",
    )
    parser.parse_args()
    try:
        print(json.dumps({"database_keys": sorted(_load_credential_entries())}))
        return 0
    except CredentialError as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
