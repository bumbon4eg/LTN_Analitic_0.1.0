local storage_api = require("storage")

local buffer = {}

---@return nil
local function ensure_storage()
    storage_api.ensure()
end

---@param order OrderData
---@return nil
local function buffer_order(order)
    ensure_storage()

    table.insert(storage.send_buffer.orders, order)
end

---@param action ActionData
---@return nil
local function buffer_action(action)
    ensure_storage()

    table.insert(storage.send_buffer.actions, action)
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

    storage.send_buffer.orders = {}
    storage.send_buffer.actions = {}
    storage.send_buffer.trains = {}
    storage.send_buffer.stations = {}
end

---@return SendData
local function collect_send_data()
    ensure_storage()

    local data = {
        tick = game.tick,
        orders = {},
        actions = {},
        trains = {},
        stations = {}
    }

    for _, order in ipairs(storage.send_buffer.orders) do
        table.insert(data.orders, order)
    end

    for _, action in ipairs(storage.send_buffer.actions) do
        table.insert(data.actions, action)
    end

    for _, train_data in pairs(storage.send_buffer.trains) do
        table.insert(data.trains, train_data)
    end

    for _, station_data in pairs(storage.send_buffer.stations) do
        table.insert(data.stations, station_data)
    end

    return data
end

---@param order OrderData
---@return nil
function buffer.buffer_order(order)
    buffer_order(order)
end

---@param action ActionData
---@return nil
function buffer.buffer_action(action)
    buffer_action(action)
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
