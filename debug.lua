local buffer = require("buffer")
local storage_api = require("storage")
local jsonl = require("jsonl")

local debug = {}

---@return nil
function debug.show_world_id()
    local world_id = storage_api.ensure_world_id()

    game.print("World ID: " .. world_id)
    log("World ID: " .. world_id)
end

---@return nil
function debug.regenerate_world_id()
    local world_id = storage_api.ensure_world_id(true)

    game.print("World ID regenerated: " .. world_id)
    log("World ID regenerated: " .. world_id)
end

---@return nil
local function show_active_deliveries()
    storage_api.ensure()

    local count = 0

    for _ in pairs(storage.active_deliveries) do
        count = count + 1
    end

    game.print(
        "========== ACTIVE DELIVERIES: "
        .. tostring(count)
        .. " =========="
    )

    if count == 0 then
        game.print("No active deliveries.")
        return
    end

    for train_id, active in pairs(storage.active_deliveries) do

        local debug_data = {
            train_id = train_id,
            order_id = active.order_id,
            state = active.state
        }

        if active.delivery then
            debug_data.from_id = active.delivery.from_id
            debug_data.to_id = active.delivery.to_id
            debug_data.network_id = active.delivery.network_id
            debug_data.started = active.delivery.started
        else
            debug_data.ERROR = "Invalid active_delivery format"
        end

        game.print(serpent.block(debug_data))

        log(serpent.block(debug_data))
    end
end

---@return nil
local function show_send_buffer()
    storage_api.ensure()

    local orders_count = #storage.send_buffer.active_orders
    local events_count = #storage.send_buffer.order_events

    local trains_count = 0
    for _ in pairs(storage.send_buffer.trains) do
        trains_count = trains_count + 1
    end

    local stations_count = 0
    for _ in pairs(storage.send_buffer.stations) do
        stations_count = stations_count + 1
    end

    game.print(
        "========== SEND BUFFER ==========\n"
        .. "Active Orders: " .. tostring(orders_count) .. "\n"
        .. "Order Events: " .. tostring(events_count) .. "\n"
        .. "Trains: " .. tostring(trains_count) .. "\n"
        .. "Stations: " .. tostring(stations_count)
    )

    log("========== SEND BUFFER ==========")
    log(serpent.block(storage.send_buffer))
end

---@return nil
local function show_send_data()
    local data = buffer.collect_send_data()

    game.print("========== SEND DATA ==========\n" .. serpent.block(data))

    log("========== SEND DATA ==========")
    log(serpent.block(data))
end

---@return nil
local function clear_active_deliveries()

    storage.active_deliveries = {}

    game.print("Active deliveries storage cleared.")
    log("========== ACTIVE DELIVERIES CLEARED ==========")
end

---@return nil
local function clear_send_buffer()

    buffer.clear_send_buffer()

    game.print("Send buffer cleared.")
    log("========== SEND BUFFER CLEARED ==========")
end

---@param order_id string|number|nil
---@return nil
local function show_order(order_id)
    storage_api.ensure()

    order_id = tonumber(order_id)

    if not order_id then
        game.print("Invalid order id.")
        return
    end

    local found = false

    -- Ищем сам Order
    for _, order in ipairs(
        storage.send_buffer.active_orders
    ) do

        if order.id == order_id then
            found = true
            game.print("========== ORDER ==========\n" .. serpent.block(order))
            break
        end
    end

    -- Ищем Events этого Order
    local order_events = {}

    for _, event in ipairs(
        storage.send_buffer.order_events
    ) do

        if event.order_id == order_id then
            table.insert(order_events, event)
        end
    end

    if #order_events > 0 then
        found = true
        game.print("========== ORDER EVENTS ==========\n" .. serpent.block(order_events))
    end

    if not found then
        game.print("Order not found in send buffer: " .. tostring(order_id))
    end
end

---@return nil
function debug.write_jsonl_now()

    local success = jsonl.write()

    if success then
        game.print("JSONL packet written.")
    else
        game.print("JSONL buffer is empty.")
    end
end

-- Связующие функции для отладки
---@return nil
function debug.show_active_deliveries()
    show_active_deliveries()
end

---@return nil
function debug.clear_active_deliveries()
    clear_active_deliveries()
end

---@return nil
function debug.show_send_buffer()
    show_send_buffer()
end

---@return nil
function debug.show_send_data()
    show_send_data()
end

---@return nil
function debug.clear_send_buffer()
    clear_send_buffer()
end

---@param order_id string|number|nil
---@return nil
function debug.show_order(order_id)
    show_order(order_id)
end

return debug