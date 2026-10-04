# LTN Analitic

Standalone analytics mod for **Factorio 2.0** and Logistic Train Network. It records delivery, order, train, station, and event data as versioned JSONL packets in Factorio's `script-output`. The mod has no database connection and does not require the companion Gateway to run.

![LTN Analitic](thumbnail.png)

## Requirements

- Factorio 2.0
- Logistic Train Network 2.0.0 or newer
- Optional compatibility mods listed in [info.json](info.json)

## JSONL recording

Recording is enabled by default. Change **Settings → Mod settings → LTN Analitic → Write JSONL snapshots to script-output** to pause or resume it. Turning recording off clears the pending buffer; events from the paused period are not exported when recording resumes.

Default output path on Windows:

```text
%APPDATA%\Factorio\script-output\LTN_Analitic\data.jsonl
```

Useful in-game commands:

These commands are designed for runtime inspection and troubleshooting while a save is running. They help confirm that data collection, buffer filling, and JSONL export remain consistent with the expected LTN lifecycle.

| Command | Purpose |
| --- | --- |
| `/ltn_debug_world_id` | Prints the persistent `world_id` for the current save. Useful for confirming that multiple JSONL batches belong to the same world and for debugging cross-save or migration issues. |
| `/ltn_regenerate_world_id` | Generates a new persistent `world_id` for the current save and logs the change. Use only when you intentionally want to split a new data stream from the previous world history. |
| `/ltn_debug_orders` | Displays active deliveries currently tracked in `storage.active_deliveries`, including train id, order id, and delivery state. This is the quickest way to sanity-check whether LTN deliveries are being observed correctly. |
| `/ltn_clear_active` | Clears the active delivery table in storage. Useful for resetting stale state after a problematic save or debugging an unexpected backlog after a mod reload. |
| `/ltn_debug_buffer` | Lists the current send buffer totals and raw buffer content. It shows how many orders, order events, trains, and stations are queued for export before the next JSONL write. |
| `/ltn_debug_send_data` | Prints the assembled payload that would be written to JSONL. This is the most direct check that train/station snapshots, active orders, and order events are collected in the expected format. |
| `/ltn_clear_buffer` | Clears the in-memory send buffer immediately. Use this when you want to reset queued data without restarting the save or when debugging stale queued packets. |
| `/ltn_debug_order <id>` | Looks up a specific order id in the send buffer and prints its entry plus matching order events. This is useful for tracing a single delivery through the export pipeline. |
| `/ltn_debug_jsonl` | Prints JSONL status: whether recording is enabled or disabled, the next sequence number, and the pending counts in orders/events/trains/stations. This is the main diagnostic command for export state. |
| `/ltn_write_jsonl` | Forces a JSONL flush immediately when recording is enabled. If the mod setting is disabled, the command reports that no file was written and exits without exporting anything. |

See [troubleshooting](docs/troubleshooting.md) for output and save-migration guidance.

## Companion Gateway

The optional [LTN Analytics Gateway](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway) is a separate application that imports the mod's JSONL into PostgreSQL. It is not included in the Factorio mod and has its own documentation in that project's repository. The Gateway repository currently provides source code; check its [Releases page](https://github.com/Zorngeist-Qual/LTN-Analytics-Gateway/releases) for binary packages.

## Mod development

The source Lua files are in `code/`; Factorio expects runtime Lua files at the root of the installed mod folder. Local staging instructions, architecture, and the JSONL contract are documented here:

- [Installation and local staging](docs/installation.md)
- [Mod architecture](docs/architecture.md)
- [Factorio implementation](docs/factorio-mod.md)
- [JSONL data contract and schemas](docs/data-contract.md)
- [Development and release checks](docs/development.md)
- [Companion Gateway links](docs/gateway.md)

## Repository layout

```text
code/       Factorio Lua sources, including settings.lua
locale/     English and Russian setting labels
schemas/    JSON Schema for the JSONL contract
docs/       Mod installation and technical documentation
info.json   Factorio mod metadata
```
