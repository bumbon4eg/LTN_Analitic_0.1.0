local buffer = require("buffer")
local storage_api = require("storage")

local jsonl = {}

---@type string
local FILE_NAME = "LTN_Analitic/data.jsonl"
local WRITE_SETTING = "ltn-analytic-write-jsonl"

-- Версия протокола в формате "major.minor", где major и minor - целые числа.
---@type string
local PROTOCOL_VERSION = "1.0"

---@return nil
local function ensure_storage()
    storage_api.ensure()

    storage.jsonl = storage.jsonl or {
        sequence_number = 0
    }
end

---@return SequenceId
local function get_next_sequence()
    ensure_storage()

    storage.jsonl.sequence_number = storage.jsonl.sequence_number + 1

    return storage.jsonl.sequence_number
end

---@return WorldId
local function get_world_id()
    storage_api.ensure_world_id()
    return storage.world_id
end

---@return boolean
function jsonl.is_enabled()
    local setting = settings.global[WRITE_SETTING]
    return setting == nil or setting.value
end

---@param event table
---@return nil
function jsonl.on_runtime_mod_setting_changed(event)
    if event.setting == WRITE_SETTING then
        buffer.clear_send_buffer()
    end
end

---@return JsonlPacket
function jsonl.build_packet()

    ---@type SendData
    local data = buffer.collect_send_data()

    ---@type JsonlPacket
    local packet = {
        protocol_version = PROTOCOL_VERSION,
        world_id = get_world_id(),
        sequence_number = get_next_sequence(),
        tick = data.tick,
        active_orders = data.active_orders,
        order_events = data.order_events,
        trains = data.trains,
        stations = data.stations
    }

    return packet
end

---@return JsonlWriteResult
function jsonl.write()
    if not jsonl.is_enabled() then
        buffer.clear_send_buffer()
        return false
    end

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
    script.on_event(
        defines.events.on_runtime_mod_setting_changed,
        jsonl.on_runtime_mod_setting_changed
    )
end

return jsonl