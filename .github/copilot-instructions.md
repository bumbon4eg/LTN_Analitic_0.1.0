# Factorio Mod Development

## Target
This project is a Factorio 2.0 mod.

Use the Factorio 2.0 API.
Do not use Factorio 2.1 APIs unless explicitly requested.

## Factorio API

Use the official Factorio API documentation as the primary source:

https://lua-api.factorio.com/

Never invent Factorio API methods, events, properties, classes, or fields.

If you are unsure whether an API exists, say so and verify it before using it.

## Lua

Factorio uses a modified version of Lua 5.2.

Do not assume that arbitrary standard Lua libraries are available.

## Architecture

The project is split into modules.

control.lua
- initialization
- configuration changes
- main event registration

actions.lua
- LTN events
- order lifecycle
- action processing

tools.lua
- helper functions
- train data
- station data
- cargo data
- order data
- action data

Do not move unrelated logic between files unless necessary.

## LTN

This mod uses Logistic Train Network (LTN).

Do not invent LTN API functions or events.
Verify LTN API usage before suggesting changes.

## Persistent state

Use Factorio's `storage` for persistent runtime state.

Be careful about save/load compatibility.

## Code changes

When modifying existing code:

1. Preserve the existing architecture.
2. Make the smallest necessary change.
3. Do not rewrite unrelated code.
4. Preserve existing variable and function names unless there is a good reason to change them.
5. Explain why a change is necessary.

## Debugging

When fixing a bug:

1. Identify the likely cause.
2. Identify the exact problematic code.
3. Explain the cause.
4. Propose the smallest fix.
5. Only then suggest larger architectural changes.