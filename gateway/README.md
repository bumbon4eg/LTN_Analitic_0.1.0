# Gateway

`gateway` is the external Python application that reads JSONL snapshots produced by the Factorio mod and writes their data to the database.

The gateway is intentionally separate from the Factorio mod. It is not copied into the Factorio mod archive and does not run inside Factorio.

## Data source

The current entry point reads:

```text
%APPDATA%/Factorio/script-output/LTN_Analitic/data.jsonl
```

Each non-empty line is parsed as one JSON packet. The packet contract is shared with the mod through the repository schemas, especially [packet.schema.json](../schemas/packet.schema.json).

## Requirements

- Python 3.10 or newer is recommended.
- PostgreSQL or a compatible database configured for the gateway models.
- Dependencies from [requirements.txt](requirements.txt).

## Configuration

Copy `.env_template` to `.env` and provide the database connection values:

```dotenv
DB_USER="YOUR_DB_USERNAME"
DB_PASSWORD="YOUR_DB_PASSWORD"
DB_HOST="YOUR_DB_HOST"
DB_PORT="YOUR_DB_PORT"
DB_NAME="YOUR_DB_NAME"
```

Environment loading is handled by the gateway configuration layer. Never commit real credentials.

## Install and run

From the `gateway` directory:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env_template .env
python main.py
```

The gateway initializes the database tables, reads the JSONL file, converts packets to application schemas, and inserts orders and order events in batches.

## Protocol versioning

The packet contains `protocol_version`. It identifies the JSONL contract, not the Factorio mod version.

When making a backward-compatible change, keep the existing protocol version and make the gateway tolerate the new optional field. When changing field names, types, required fields, nesting, or semantics, increment the protocol major version and update together:

1. `code/jsonl.lua` packet construction;
2. `schemas/packet.schema.json` and dependent schemas;
3. the gateway Pydantic schemas and transformations;
4. this README and the main architecture documentation.

The gateway should reject or quarantine packets with unsupported protocol versions rather than silently importing incorrect data. `world_id` separates worlds, while `sequence_number` detects gaps and duplicates within one world.

## Scope boundary

The gateway may evolve independently, but its input contract is shared with the Factorio mod. Do not change the gateway and mod packet format in isolation.
