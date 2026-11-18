#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pymysql==1.2.4", "cryptography==50.0.2", "sqlglot==30.30.0"]
# ///
"""Run one read-only DQS SELECT from stdin and return JSON."""

import argparse
import datetime
import decimal
import json
import logging
import shutil
import ssl
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pymysql
import sqlglot
from sqlglot import exp

import dqs_credentials

MAX_ROWS = 10000
BATCH_SIZE = 1000
MAX_SQL_BYTES = 64 * 1024
# A positive syntax allowlist: new parser nodes fail closed.
NODES = set(
    """Select Union Subquery With CTE From Table TableAlias Column Identifier
Star Alias Literal Null Boolean Paren Tuple Join Where Group Having Order Ordered
Limit Offset Distinct And Or Not EQ NEQ GT GTE LT LTE Is In Between Like ILike Escape
Add Sub Mul Div IntDiv Mod Neg BitwiseAnd BitwiseOr BitwiseXor Case When If
Cast DataType DataTypeParam Interval Var Window WindowSpec Partition Over
JSONPath JSONPathRoot JSONPathKey JSONPathSubscript JSONPathWildcard""".split()
)
FUNCTIONS = set(
    """COUNT SUM AVG MIN MAX COALESCE NULLIF IF IFNULL CASE CAST
ABS CEIL FLOOR ROUND POW SQRT MOD SIGN GREATEST LEAST
LOWER UPPER LENGTH CHAR_LENGTH CONCAT CONCAT_WS SUBSTRING TRIM LTRIM RTRIM
REPLACE LEFT RIGHT LOCATE STR_POSITION
CURRENT_DATE CURRENT_TIMESTAMP CURRENT_TIME DATE DATE_ADD DATE_SUB DATE_DIFF
DATEDIFF TIMESTAMPDIFF TIME_TO_STR STR_TO_TIME YEAR MONTH DAY DAY_OF_MONTH
HOUR MINUTE SECOND EXTRACT TS_OR_DS_TO_DATE
JSON_EXTRACT JSON_EXTRACT_SCALAR JSON_ARRAY_LENGTH JSON_TYPE JSON_CONTAINS
ROW_NUMBER RANK DENSE_RANK LAG LEAD FIRST_VALUE LAST_VALUE""".split()
)
ANONYMOUS_FUNCTIONS = {
    "NOW",
    "UTC_TIMESTAMP",
    "UTC_DATE",
    "JSON_UNQUOTE",
    "DATE_FORMAT",
}


class SafeError(Exception):
    """An error whose message is safe to expose in JSON diagnostics."""


def prepare_sql(sql, *, fetch_all=False, raw=False):
    """Validate every mode, then apply only the selected limit/rewrite policy."""
    if not sql.strip() or len(sql.encode()) > MAX_SQL_BYTES:
        raise SafeError("Provide one SELECT of at most 64 KiB.")
    try:
        tokens = sqlglot.Dialect.get_or_raise("mysql").tokenize(sql)
        if any(t.comments for t in tokens):
            raise SafeError("SQL comments and hints are not supported.")
        statements = sqlglot.parse(
            sql, read="mysql", error_level=sqlglot.ErrorLevel.RAISE
        )
        if len(statements) != 1 or not isinstance(
            statements[0], (exp.Select, exp.Union)
        ):
            raise SafeError("Only one SELECT statement is allowed.")
        tree = statements[0]
        for node in tree.walk():
            if isinstance(node, exp.Func):
                name = (
                    node.name.upper()
                    if isinstance(node, exp.Anonymous)
                    else node.sql_name()
                )
                allowed = (
                    ANONYMOUS_FUNCTIONS
                    if isinstance(node, exp.Anonymous)
                    else FUNCTIONS
                )
                if name not in allowed:
                    raise SafeError("Function is outside the read-only allowlist.")
            elif type(node).__name__ not in NODES:
                raise SafeError("SQL contains unsupported or unsafe syntax.")
        # Bound the server result, not just what gets printed. Fetch one extra row
        # to distinguish complete results from truncation.
        limit = tree.args.get("limit")
        if limit is not None:
            value = limit.expression
            if (
                not isinstance(value, exp.Literal)
                or value.is_string
                or not str(value.this).isdigit()
            ):
                raise SafeError("LIMIT must be a nonnegative integer literal.")
            bound = min(int(value.this), MAX_ROWS + 1)
        else:
            bound = MAX_ROWS + 1
        if raw:
            return sql
        if not fetch_all:
            tree = tree.limit(bound)
        return tree.sql(dialect="mysql", unsupported_level=sqlglot.ErrorLevel.RAISE)
    except SafeError:
        raise
    except Exception:
        raise SafeError(
            "SQL could not be safely parsed; simplify the SELECT."
        ) from None


def sanitize_value(value, secrets):
    """Make values JSON-compatible and redact connection secrets before staging."""
    if value is None or isinstance(value, (bool, int, float)):
        return value
    if isinstance(value, bytes):
        return "[binary omitted]"
    if isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
        value = value.isoformat()
    elif isinstance(value, (decimal.Decimal, datetime.timedelta)):
        value = str(value)
    elif isinstance(value, (list, tuple)):
        return [sanitize_value(x, secrets) for x in value]
    else:
        value = str(value)
    for secret in sorted(secrets, key=len, reverse=True):
        if secret:
            value = value.replace(secret, "[redacted]")
    return value


def configure_read_only_session(connection):
    """Verify TLS and establish a read-only transaction before executing user SQL."""
    cursor = connection.cursor()
    cursor.execute("SHOW SESSION STATUS LIKE 'Ssl_cipher'")
    tls = cursor.fetchone()
    if not tls or not tls[1]:
        raise SafeError("Server did not negotiate TLS; connection closed.")
    cursor.execute(
        "SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION'"
    )
    cursor.execute("SET SESSION max_execution_time = 10000")
    cursor.execute("SET SESSION lock_wait_timeout = 5")
    cursor.execute("SET SESSION TRANSACTION READ ONLY")
    cursor.execute("SELECT @@session.transaction_read_only")
    if cursor.fetchone()[0] != 1:
        raise SafeError("Read-only session could not be verified.")
    cursor.execute("START TRANSACTION READ ONLY")
    cursor.close()


def write_result_rows(cursor, output, secrets, row_limit):
    """Write the rows array incrementally; the caller appends result metadata."""
    output.write('{"rows":[')
    count = 0
    truncated = False
    while batch := cursor.fetchmany(BATCH_SIZE):
        for row in batch:
            if row_limit is not None and count >= row_limit:
                truncated = True
                continue
            if count:
                output.write(",")
            json.dump(sanitize_value(row, secrets), output, ensure_ascii=True)
            count += 1
    output.write("]")
    return count, truncated


def investigate(
    sql,
    output,
    *,
    database=None,
    explain=False,
    db_key=None,
    fetch_all=False,
    raw=False,
):
    """Execute a validated read and stage JSON; the caller publishes it on success."""
    validated = prepare_sql(sql, fetch_all=fetch_all, raw=raw)
    if not db_key:
        raise SafeError("DQS requires an exact --db-key from the KVM database list.")
    try:
        fields, port = dqs_credentials.load_credentials(db_key)
    except dqs_credentials.CredentialError as error:
        raise SafeError(str(error)) from None
    secrets = [fields.get(k, "") for k in ("password", "username", "hostname")]
    connection = None
    started = time.monotonic()
    try:
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        connection = pymysql.connect(
            host=fields["hostname"],
            port=port,
            user=fields["username"],
            password=fields["password"],
            database=database or fields.get("database") or None,
            ssl=context,
            connect_timeout=10,
            read_timeout=15,
            write_timeout=15,
            local_infile=False,
            client_flag=0,
            autocommit=False,
            charset="utf8mb4",
        )
        configure_read_only_session(connection)
        cursor = connection.cursor(pymysql.cursors.SSCursor)
        cursor.execute(("EXPLAIN " if explain else "") + validated)
        columns = sanitize_value([d[0] for d in cursor.description], secrets)
        row_limit = None if (fetch_all or raw or explain) else MAX_ROWS
        count, truncated = write_result_rows(cursor, output, secrets, row_limit)
        cursor.close()
        result = {
            "target": "dqs",
            "columns": columns,
            "row_count": count,
            "elapsed_seconds": round(time.monotonic() - started, 3),
            "tls": {"encrypted": True, "certificate_verified": False},
            "read_only": True,
            "truncated": truncated,
            "db_key": sanitize_value(db_key, secrets),
            "credential_role": "rw",
        }
        if truncated:
            result["hint"] = "Use --fetch-all to retrieve beyond 10000 rows."
        # Append metadata to the object opened by write_result_rows.
        output.write("," + json.dumps(result, ensure_ascii=True)[1:] + "\n")
        return result
    except SafeError:
        raise
    except pymysql.MySQLError as error:
        code = error.args[0] if error.args and type(error.args[0]) is int else None
        raise SafeError(
            "MySQL operation failed"
            + (f" (code {code})" if code else "")
            + "; check access, database selection, query syntax, or time limits."
        ) from None
    except Exception:
        raise SafeError(
            "Connection or query failed; no raw diagnostic is emitted to protect credentials."
        ) from None
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


def run_offline_tests():
    """Fail closed before credential access; never expose captured test output."""
    directory = Path(__file__).resolve().parent
    test_modules = ("test_dqs_credentials", "test_query")
    if not all((directory / f"{name}.py").is_file() for name in test_modules):
        raise SafeError("Required offline tests are missing; database access stopped.")
    try:
        result = subprocess.run(
            [sys.executable, "-m", "unittest", *test_modules],
            cwd=directory,
            capture_output=True,
            timeout=60,
            check=False,
        )
    except Exception:
        raise SafeError(
            "Offline tests could not run; database access stopped."
        ) from None
    if result.returncode:
        raise SafeError(
            "Offline tests failed; database access stopped. "
            "Run test_dqs_credentials and test_query locally for details."
        )


def main():
    logging.disable(logging.CRITICAL)
    parser = argparse.ArgumentParser(
        description=__doc__,
        epilog="Connection: KVM_HOST and the selected DQS rw credentials. All modes enforce read-only SQL.",
    )
    parser.add_argument(
        "--database",
        metavar="SCHEMA",
        help="Override the credential entry's default schema",
    )
    parser.add_argument(
        "--db-key",
        required=True,
        metavar="KEY",
        help="Credential key from dqs_credentials.py --list",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--explain",
        action="store_true",
        help="Return the query plan without executing the SELECT",
    )
    mode.add_argument(
        "--fetch-all",
        action="store_true",
        help="Remove the helper's 10000-row cap",
    )
    mode.add_argument(
        "--raw",
        action="store_true",
        help="Validate and execute the original SELECT unchanged, without a row cap",
    )
    args = parser.parse_args()
    try:
        run_offline_tests()
        sql = sys.stdin.read(MAX_SQL_BYTES + 1)
        # TemporaryFile is private and removed on close, including error exits.
        with tempfile.TemporaryFile(mode="w+", encoding="utf-8") as output:
            investigate(
                sql,
                output,
                database=args.database,
                explain=args.explain,
                db_key=args.db_key,
                fetch_all=args.fetch_all,
                raw=args.raw,
            )
            output.seek(0)
            shutil.copyfileobj(output, sys.stdout)
        return 0
    except SafeError as error:
        print(json.dumps({"error": str(error)}), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('{"error":"Cancelled; connection closed."}', file=sys.stderr)
        return 130
    except Exception:
        print(
            '{"error":"Unexpected failure; diagnostic suppressed to protect credentials."}',
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
