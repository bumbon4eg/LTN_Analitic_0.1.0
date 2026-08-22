local buffer = require("buffer")

local jsonl = {}

---@type string
local FILE_NAME = "LTN_Analitic/data.jsonl"

---@type integer
local PROTOCOL_VERSION = 1

---@return nil
local function ensure_storage()
    storage.jsonl = storage.jsonl or {
        sequence = 0
    }
end

---@return SequenceId
local function get_next_sequence()
    ensure_storage()

    storage.jsonl.sequence =
        storage.jsonl.sequence + 1

    return storage.jsonl.sequence
end

---@return JsonlWriteResult
function jsonl.write()

    ---@type SendData
    local data = buffer.collect_send_data()

    local has_data =
        #data.orders > 0
        or #data.actions > 0
        or #data.trains > 0
        or #data.stations > 0

    if not has_data then
        return false
    end

    ---@type JsonlPacket
    local packet = {
        protocol_version = PROTOCOL_VERSION,
        sequence = get_next_sequence(),
        tick = data.tick,

        orders = data.orders,
        actions = data.actions,
        trains = data.trains,
        stations = data.stations
    }

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