"""Private KVM credential retrieval; only database names may be printed."""
import argparse
import json
import os
import subprocess
import sys


class CredentialError(Exception):
    pass


def load_databases(host=None):
    if host is None:
        host = os.environ.get("KVM")
    if not host:
        raise CredentialError("KVM is unset or empty; load .booking.zshrc in your shell or pass --kvm-host.")
    if not host or host.startswith("-") or any(c.isspace() for c in host):
        raise CredentialError("Invalid KVM host.")
    try:
        result = subprocess.run(
            ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", host,
             "cat /var/run/secrets/booking.com/db.json"],
            capture_output=True, text=True, timeout=30, check=False,
        )
        if result.returncode:
            raise ValueError()
        databases = json.loads(result.stdout)["database"]
        if not isinstance(databases, dict) or not databases:
            raise ValueError()
        return databases
    except Exception:
        raise CredentialError(
            "KVM credential lookup failed. If sandbox access was denied, retry with network approval. "
            "Otherwise run ssh -A ssh.booking.com interactively to refresh SSH fingerprint/access, "
            "then retry. Raw output suppressed."
        ) from None


def credentials(key, host=None, role="ro"):
    if role not in ("ro", "rw"):
        raise CredentialError("Choose the ro or rw credential role.")
    databases = load_databases(host)
    entry = databases.get(key, {}).get(role)
    if not isinstance(entry, dict):
        raise CredentialError("Database key or credential role is unavailable; list database keys first.")
    if not entry.get("host"):
        raise CredentialError(
            "Selected credentials have no direct host. Do not treat roster fields as direct hosts; "
            "resolve the roster through a documented workflow or explicitly choose the DQS rw role."
        )
    if not all(isinstance(entry.get(k), str) and entry[k] for k in ("host", "username", "password", "database")):
        raise CredentialError("KVM credentials lack required connection fields.")
    try:
        port = int(entry.get("port") or 3306)
        if not 1 <= port <= 65535:
            raise ValueError()
    except Exception:
        raise CredentialError("KVM credentials contain an invalid port.") from None
    return {"hostname": entry["host"], "username": entry["username"],
            "password": entry["password"], "database": entry["database"]}, port


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kvm-host", help="SSH host (defaults to $KVM from .booking.zshrc)")
    args = parser.parse_args()
    try:
        print(json.dumps({"databases": sorted(load_databases(args.kvm_host))}))
        return 0
    except CredentialError as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
