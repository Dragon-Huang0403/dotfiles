#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pymysql==1.2.4", "cryptography==50.0.2", "sqlglot==30.30.0"]
# ///
"""Bounded, read-only MySQL investigation. Never print raw dependency errors."""
import argparse
import datetime
import decimal
import json
import logging
import ssl
import subprocess
import sys
import time

import pymysql
import sqlglot
from sqlglot import exp

import kvm

TARGETS = {"pay": "Pay Prod", "ppo": "PPO Prod"}
MAX_ROWS = 200
MAX_BYTES = 1024 * 1024
MAX_SQL_BYTES = 64 * 1024
# A positive syntax allowlist: new parser nodes fail closed.
NODES = set("""Select Union Subquery With CTE From Table TableAlias Column Identifier
Star Alias Literal Null Boolean Paren Tuple Join Where Group Having Order Ordered
Limit Offset Distinct And Or Not EQ NEQ GT GTE LT LTE Is In Between Like ILike Escape
Add Sub Mul Div IntDiv Mod Neg BitwiseAnd BitwiseOr BitwiseXor Case When If
Cast DataType DataTypeParam Interval Var Window WindowSpec Partition Over
JSONPath JSONPathRoot JSONPathKey JSONPathSubscript JSONPathWildcard""".split())
FUNCTIONS = set("""COUNT SUM AVG MIN MAX COALESCE NULLIF IF IFNULL CASE CAST
ABS CEIL FLOOR ROUND POW SQRT MOD SIGN GREATEST LEAST
LOWER UPPER LENGTH CHAR_LENGTH CONCAT CONCAT_WS SUBSTRING TRIM LTRIM RTRIM
REPLACE LEFT RIGHT LOCATE STR_POSITION
CURRENT_DATE CURRENT_TIMESTAMP CURRENT_TIME DATE DATE_ADD DATE_SUB DATE_DIFF
DATEDIFF TIMESTAMPDIFF TIME_TO_STR STR_TO_TIME YEAR MONTH DAY DAY_OF_MONTH
HOUR MINUTE SECOND EXTRACT TS_OR_DS_TO_DATE
JSON_EXTRACT JSON_EXTRACT_SCALAR JSON_ARRAY_LENGTH JSON_TYPE JSON_CONTAINS
ROW_NUMBER RANK DENSE_RANK LAG LEAD FIRST_VALUE LAST_VALUE""".split())
ANONYMOUS_FUNCTIONS = {"NOW", "UTC_TIMESTAMP", "UTC_DATE", "JSON_UNQUOTE", "DATE_FORMAT"}


class SafeError(Exception):
    pass


def validate_sql(sql):
    if not sql.strip() or len(sql.encode()) > MAX_SQL_BYTES:
        raise SafeError("Provide one SELECT of at most 64 KiB.")
    try:
        tokens = sqlglot.Dialect.get_or_raise("mysql").tokenize(sql)
        if any(t.comments for t in tokens):
            raise SafeError("SQL comments and hints are not supported.")
        statements = sqlglot.parse(sql, read="mysql", error_level=sqlglot.ErrorLevel.RAISE)
        if len(statements) != 1 or not isinstance(statements[0], (exp.Select, exp.Union)):
            raise SafeError("Only one SELECT statement is allowed.")
        tree = statements[0]
        for node in tree.walk():
            if isinstance(node, exp.Func):
                name = node.name.upper() if isinstance(node, exp.Anonymous) else node.sql_name()
                allowed = ANONYMOUS_FUNCTIONS if isinstance(node, exp.Anonymous) else FUNCTIONS
                if name not in allowed:
                    raise SafeError("Function is outside the read-only allowlist.")
            elif type(node).__name__ not in NODES:
                raise SafeError("SQL contains unsupported or unsafe syntax.")
        # Bound the server result, not just what gets printed. Fetch one extra row
        # to distinguish complete results from truncation.
        limit = tree.args.get("limit")
        if limit is not None:
            value = limit.expression
            if not isinstance(value, exp.Literal) or value.is_string or not str(value.this).isdigit():
                raise SafeError("LIMIT must be a nonnegative integer literal.")
            bound = min(int(value.this), MAX_ROWS + 1)
        else:
            bound = MAX_ROWS + 1
        return tree.limit(bound).sql(dialect="mysql", unsupported_level=sqlglot.ErrorLevel.RAISE)
    except SafeError:
        raise
    except Exception:
        raise SafeError("SQL could not be safely parsed; simplify the SELECT.") from None


def get_credentials(target):
    try:
        result = subprocess.run(
            ["op", "item", "get", TARGETS[target], "--vault", "Employee", "--format", "json"],
            capture_output=True, text=True, timeout=60, check=False,
        )
        if result.returncode:
            raise SafeError("1Password access failed; check app unlock, CLI authentication, and sandbox access.")
        item = json.loads(result.stdout)
        fields = {f["id"]: f.get("value", "") for f in item.get("fields", [])}
        if not all(isinstance(fields.get(k), str) and fields[k] for k in ("hostname", "username", "password")):
            raise SafeError("1Password item lacks required connection fields.")
        port = int(fields.get("port") or 3306)
        if not 1 <= port <= 65535:
            raise ValueError()
        return fields, port
    except SafeError:
        raise
    except Exception:
        raise SafeError("Unable to load connection fields from 1Password.") from None


def clean(value, secrets):
    if value is None or isinstance(value, (bool, int, float)):
        return value
    if isinstance(value, bytes):
        return "[binary omitted]"
    if isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
        value = value.isoformat()
    elif isinstance(value, (decimal.Decimal, datetime.timedelta)):
        value = str(value)
    elif isinstance(value, (list, tuple)):
        return [clean(x, secrets) for x in value]
    else:
        value = str(value)
    for secret in sorted(secrets, key=len, reverse=True):
        if secret:
            value = value.replace(secret, "[redacted]")
    return value


def investigate(target, sql, database=None, explain=False, db_key=None,
                kvm_host=None, credential_role="ro"):
    validated = validate_sql(sql)
    if target == "dqs":
        if not db_key:
            raise SafeError("DQS requires an exact --db-key from the KVM database list.")
        try:
            fields, port = kvm.credentials(db_key, kvm_host, credential_role)
        except kvm.CredentialError as error:
            raise SafeError(str(error)) from None
    else:
        fields, port = get_credentials(target)
    secrets = [fields.get(k, "") for k in ("password", "username", "hostname")]
    connection = None
    started = time.monotonic()
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        connection = pymysql.connect(
            host=fields["hostname"], port=port, user=fields["username"], password=fields["password"],
            database=database or fields.get("database") or None,
            ssl=context, connect_timeout=10, read_timeout=15, write_timeout=15,
            local_infile=False, client_flag=0, autocommit=False, charset="utf8mb4",
        )
        cursor = connection.cursor()
        cursor.execute("SHOW SESSION STATUS LIKE 'Ssl_cipher'")
        tls = cursor.fetchone()
        if not tls or not tls[1]:
            raise SafeError("Server did not negotiate TLS; connection closed.")
        cursor.execute("SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'")
        cursor.execute("SET SESSION max_execution_time = 10000")
        cursor.execute("SET SESSION lock_wait_timeout = 5")
        cursor.execute("SET SESSION TRANSACTION READ ONLY")
        cursor.execute("SELECT @@session.transaction_read_only")
        if cursor.fetchone()[0] != 1:
            raise SafeError("Read-only session could not be verified.")
        cursor.execute("START TRANSACTION READ ONLY")
        cursor.execute(("EXPLAIN " if explain else "") + validated)
        columns = clean([d[0] for d in cursor.description], secrets)
        rows = clean(cursor.fetchmany(MAX_ROWS + 1), secrets)
        result = {"target": target, "columns": columns, "rows": rows[:MAX_ROWS],
                  "elapsed_seconds": round(time.monotonic() - started, 3),
                  "tls": {"encrypted": True, "certificate_verified": False},
                  "read_only": True, "truncated": len(rows) > MAX_ROWS}
        if target == "dqs":
            result.update(db_key=db_key, credential_role=credential_role)
        # Reserve space for metadata, including the truncation indicator.
        while len(json.dumps(result, ensure_ascii=True).encode()) > MAX_BYTES:
            if not result["rows"]:
                raise SafeError("Result metadata exceeds the output limit.")
            result["rows"].pop()
            result["truncated"] = True
        return result
    except SafeError:
        raise
    except pymysql.MySQLError as error:
        code = error.args[0] if error.args and type(error.args[0]) is int else None
        raise SafeError("MySQL operation failed" + (f" (code {code})" if code else "") +
                        "; check access, database selection, query syntax, or time limits.") from None
    except Exception:
        raise SafeError("Connection or query failed; no raw diagnostic is emitted to protect credentials.") from None
    finally:
        if connection is not None:
            try:
                connection.rollback()
            except Exception:
                pass
            try:
                connection.close()
            except Exception:
                pass


def main():
    logging.disable(logging.CRITICAL)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True, choices=[*TARGETS, "dqs"])
    parser.add_argument("--database")
    parser.add_argument("--db-key")
    parser.add_argument("--kvm-host", help="SSH host (defaults to $KVM from .booking.zshrc)")
    parser.add_argument("--credential-role", choices=["ro", "rw"], default="ro")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--explain", action="store_true")
    args = parser.parse_args()
    if args.target != "dqs" and (args.db_key or args.credential_role != "ro" or args.kvm_host is not None):
        parser.error("KVM options require --target dqs")
    try:
        sql = "SELECT 1" if args.check else sys.stdin.read(MAX_SQL_BYTES + 1)
        result = investigate(args.target, sql, args.database, args.explain,
                             args.db_key, args.kvm_host, args.credential_role)
        print(json.dumps(result, ensure_ascii=True))
        return 0
    except SafeError as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('{"error":"Cancelled; connection closed."}', file=sys.stderr)
        return 130
    except Exception:
        print('{"error":"Unexpected failure; diagnostic suppressed to protect credentials."}', file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
