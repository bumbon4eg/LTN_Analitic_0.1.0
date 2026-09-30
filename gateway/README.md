# LTN Analytics Gateway

Gateway is a standalone Python desktop application. It reads JSONL snapshots
written by the Factorio mod and imports orders and order events into PostgreSQL.
It does not run inside Factorio and is not included in the mod archive.

## Requirements

- Windows 10/11 with Python 3.10 or newer.
- PostgreSQL reachable from the machine running the gateway.
- Python dependencies listed in [requirements.txt](requirements.txt).

Tkinter is included with the standard Windows Python distribution.

## Install and run

From the repository root:

```powershell
python -m venv gateway/.venv
gateway/.venv/Scripts/python.exe -m pip install -r gateway/requirements.txt
gateway/.venv/Scripts/python.exe gateway/main.py
```

On first launch, the setup wizard asks for the JSONL source and database
connection. Later launches open the dashboard, where you can test the connection,
edit all settings on one page, or start an import. Network operations run off the
UI thread.

## Configuration

The default source is:

```text
%APPDATA%\Factorio\script-output\LTN_Analitic\data.jsonl
```

Settings and local import statistics are saved to:

```text
%APPDATA%\LTN_Analitics_gateway\config.conf
```

The `.conf` file contains JSON, including the source path, PostgreSQL fields,
SSL/TLS selection, and dashboard counters. Passwords are stored as plain text in
this per-user file; restrict access with Windows account permissions and do not
share it. The password field has an explicit reveal control.

SSL/TLS is off by default for compatibility. When enabled, the gateway verifies
the server certificate chain and hostname. Install a private CA into the Windows
trust store if your database uses one; do not disable certificate verification to
bypass TLS errors.

Legacy `.env` settings are used only when the AppData config does not exist.
`.env_template` documents those optional environment variables; it is not the
normal first-run setup path.

## Import behavior

The gateway reads non-empty JSONL lines and reports malformed JSON with its line
number. It converts each packet into Pydantic models, initializes database tables
from SQLAlchemy metadata, and inserts orders and events in batches of 500.
PostgreSQL `ON CONFLICT DO NOTHING` makes repeated imports safe; event rows are
inserted only when their order exists. The source file is not removed after import.

The dashboard counters report rows actually inserted, not duplicate records
skipped by the database.

## Packet compatibility

The packet contract is shared with the Factorio mod and described by
[`schemas/packet.schema.json`](../schemas/packet.schema.json). `protocol_version`
identifies the JSONL format, not the mod release. Update the Lua serializer,
schemas, gateway models/conversion, and documentation together when the packet
contract changes. See [the data contract](../docs/data-contract.md).
