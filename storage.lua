local uuid = require("UUID_V4")

local storage_api = {}

---@param world_id string|nil
---@return boolean
function storage_api.is_valid_world_id(world_id)
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

    storage.send_buffer = storage.send_buffer or {
        orders = {},
        actions = {},
        trains = {},
        stations = {}
    }

    storage.next_order_id = storage.next_order_id or 1
end

return storage_api
