local actions = require("actions")
local buffer = require("buffer")

local debug = {}

local function ensure_storage()
    storage.active_deliveries = storage.active_deliveries or {}
end

local function show_active_deliveries()
    ensure_storage()

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

local function show_send_buffer()
    ensure_storage()

    local orders_count = #storage.send_buffer.orders
    local actions_count = #storage.send_buffer.actions

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
        .. "Orders: " .. tostring(orders_count) .. "\n"
        .. "Actions: " .. tostring(actions_count) .. "\n"
        .. "Trains: " .. tostring(trains_count) .. "\n"
        .. "Stations: " .. tostring(stations_count)
    )

    log("========== SEND BUFFER ==========")
    log(serpent.block(storage.send_buffer))
end

local function show_send_data()
    local data = buffer.collect_send_data()

    game.print("========== SEND DATA ==========\n" .. serpent.block(data))

    log("========== SEND DATA ==========")
    log(serpent.block(data))
end

function debug.show_active_deliveries()
    show_active_deliveries()
end

function debug.clear_active_deliveries()
    storage.active_deliveries = {}

    game.print("Active deliveries storage cleared.")

    log("========== ACTIVE DELIVERIES CLEARED ==========")
end

function debug.show_send_buffer()
    show_send_buffer()
end

function debug.show_send_data()
    show_send_data()
end

return debug
