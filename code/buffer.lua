local storage_api = require("storage")

local buffer = {}

---@return nil
local function ensure_storage()
    storage_api.ensure()
end

---@param order OrderData
---@return nil
local function buffer_active_order(order)
    ensure_storage()

    table.insert(storage.send_buffer.active_orders, order)
end

---@param order_id OrderId
---@param current_content CargoData
---@return nil
local function update_active_order_content(order_id, current_content)
    ensure_storage()

    for _, order in ipairs(storage.send_buffer.active_orders) do
        if order.id == order_id then
            order.current_content = current_content
            return
        end
    end
end

---@param event OrderEventData
---@return nil
local function buffer_order_event(event)
    ensure_storage()

    table.insert(storage.send_buffer.order_events, event)
end

---@param train_data TrainData|nil
---@return nil
local function buffer_train(train_data)
    ensure_storage()

    if not train_data or not train_data.id then
        return
    end

    storage.send_buffer.trains[train_data.id] = train_data
end

---@param station_data StationData|nil
---@return nil
local function buffer_station(station_data)
    ensure_storage()

    if not station_data or not station_data.id then
        return
    end

    storage.send_buffer.stations[station_data.id] = station_data
end

---@return nil
local function clear_send_buffer()
    ensure_storage()

    storage.send_buffer.active_orders = {}
    storage.send_buffer.order_events = {}
    storage.send_buffer.trains = {}
    storage.send_buffer.stations = {}
end

---@return SendData
local function collect_send_data()
    ensure_storage()

    local data = {
        tick = game.tick,
        active_orders = {},
        order_events = {},
        trains = {},
        stations = {}
    }

    for _, order in ipairs(storage.send_buffer.active_orders) do
        table.insert(data.active_orders, order)
    end

    for _, event in ipairs(storage.send_buffer.order_events) do
        table.insert(data.order_events, event)
    end

    for id, train in pairs(storage.send_buffer.trains) do
        data.trains[id] = train
    end

    for id, station in pairs(storage.send_buffer.stations) do
        data.stations[id] = station
    end

    return data
end

---@param order OrderData
---@return nil
function buffer.buffer_active_order(order)
    buffer_active_order(order)
end

---@param order_id OrderId
---@param current_content CargoData
---@return nil
function buffer.update_active_order_content(order_id, current_content)
    update_active_order_content(order_id, current_content)
end

---@param event OrderEventData
---@return nil
function buffer.buffer_order_event(event)
    buffer_order_event(event)
end

---@param train_data TrainData|nil
---@return nil
function buffer.buffer_train(train_data)
    buffer_train(train_data)
end

---@param station_data StationData|nil
---@return nil
function buffer.buffer_station(station_data)
    buffer_station(station_data)
end

---@return nil
function buffer.clear_send_buffer()
    clear_send_buffer()
end

---@return SendData
function buffer.collect_send_data()
    return collect_send_data()
end

return buffer