local storage_api = {}

---@return nil
function storage_api.ensure()
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
