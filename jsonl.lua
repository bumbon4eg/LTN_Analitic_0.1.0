local buffer = require("buffer")
local storage_api = require("storage")

local jsonl = {}

---@type string
local FILE_NAME = "LTN_Analitic/data.jsonl"

-- Версия протокола, используемая для сериализации данных.
---@type integer
local PROTOCOL_VERSION = 1

---@return nil
local function ensure_storage()
    storage_api.ensure()

    storage.jsonl = storage.jsonl or {
        sequence = 0
    }
end

---@return SequenceId
local function get_next_sequence()
    ensure_storage()

    storage.jsonl.sequence = storage.jsonl.sequence + 1

    return storage.jsonl.sequence
end

---@return WorldId
local function get_world_id()
    storage_api.ensure_world_id()
    return storage.world_id
end

---@return JsonlPacket
function jsonl.build_packet()

    ---@type SendData
    local data = buffer.collect_send_data()

    ---@type JsonlPacket
    local packet = {
        protocol_version = PROTOCOL_VERSION,
        world_id = get_world_id(),
        sequence = get_next_sequence(),
        tick = data.tick,
        orders = data.orders,
        actions = data.actions,
        trains = data.trains,
        stations = data.stations
    }

    return packet
end

---@return JsonlWriteResult
function jsonl.write()

    local packet = jsonl.build_packet()

    ---@type string
    local json = helpers.table_to_json(packet)

    helpers.write_file(
        FILE_NAME,
        json .. "\n",
        true
    )

    buffer.clear_send_buffer()

    return true
end

---@return nil
function jsonl.register()
    script.on_nth_tick(360, jsonl.write)
end

return jsonl