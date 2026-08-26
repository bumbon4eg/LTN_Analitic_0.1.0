local uuid = require("UUID_V4")

local storage_api = {}

---@param world_id string|nil
---@return boolean
function storage_api.is_valid_world_id(world_id)
    -- Проверяем, что world_id является строкой и соответствует формату UUID v4
    return type(world_id) == "string"
        and string.match(
            world_id,
            "^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-"
            .. "[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-"
            .. "4[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-"
            .. "[89aAbB][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]%-"
            .. "[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$")
        ~= nil
end

---@param force boolean|nil
---@return WorldId
function storage_api.ensure_world_id(force)
    if force or not storage_api.is_valid_world_id(storage.world_id) then
        storage.world_id = uuid.new()
    end
    return storage.world_id
end

---@return nil
function storage_api.ensure()
    storage_api.ensure_world_id()

    storage.active_deliveries = storage.active_deliveries or {}

    if not storage.send_buffer then
        storage.send_buffer = {
            active_orders = {},
            order_events = {},
            trains = {},
            stations = {}
        }
    else  -- Гарантируем, что все поля send_buffer существуют, даже если они были удалены или повреждены.
        if storage.send_buffer.active_orders == nil then
            storage.send_buffer.active_orders = {}
        end
        if storage.send_buffer.order_events == nil then
            storage.send_buffer.order_events = {}
        end
        if storage.send_buffer.trains == nil then
            storage.send_buffer.trains = {}
        end
        if storage.send_buffer.stations == nil then
            storage.send_buffer.stations = {}
        end

        storage.send_buffer.orders = nil
        storage.send_buffer.actions = nil
    end

    storage.next_order_id = storage.next_order_id or 1
    storage.next_event_id = storage.next_event_id or 1

    if not storage.jsonl then
        storage.jsonl = { sequence_number = 0 }
    else
        if storage.jsonl.sequence_number == nil then
            storage.jsonl.sequence_number = 0
        end
    end
end

return storage_api