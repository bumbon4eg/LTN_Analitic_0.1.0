local tools = require("tools")

local LTN_INTERFACE = "logistic-train-network"

local actions = {}

-- Вспомогательные функции
local function ensure_storage()
    storage.active_deliveries = storage.active_deliveries or {}
end

local function get_active_delivery(train_id)
    ensure_storage()
    return storage.active_deliveries[train_id]
end

local function set_active_delivery(train_id, delivery_data, order_id, state)
    ensure_storage()

    storage.active_deliveries[train_id] = {
        delivery = delivery_data,
        order_id = order_id,
        state = state
    }
end

local function remove_active_delivery(train_id)
    ensure_storage()

    storage.active_deliveries[train_id] = nil
end

local function set_active_state(train_id, state)
    local active = get_active_delivery(train_id)

    if not active then
        return false
    end

    active.state = state
    return true
end

local function check_state(train_id, expected_states)
    local active = get_active_delivery(train_id)

    if not active then
        log("Active delivery not found for train: " .. tostring(train_id))
        return nil
    end

    local current_state = active.state

    for _, expected_state in ipairs(expected_states) do
        if current_state == expected_state then
            return active
        end
    end

    log("Unexpected delivery state for train " .. tostring(train_id) .. ": " .. tostring(current_state))
    return nil
end

local function get_action_payload(order_id, action_name, delivery_data)
    if not delivery_data then
        return nil
    end

    return tools.get_action_data(
        order_id,
        action_name,
        delivery_data.from_id,
        delivery_data.to_id
    )
end

local function log_payload(label, payload)
    if payload then
        log("========== " .. label .. " ==========")
        log(serpent.block(payload))
    end
end

-- Обработка событий
local function on_delivery_completed(event)
    log("========== LTN DELIVERY COMPLETED ==========")

    local train_id = event.train_id
    local active = check_state(train_id, {"accepted"})

    if not active then
        return
    end

    local action = get_action_payload(
        active.order_id,
        "complete",
        active.delivery
    )

    log_payload("COMPLETE ACTION", action)
    remove_active_delivery(train_id)
end

local function on_delivery_created(train_id, delivery_data)
    if not delivery_data then
        return
    end

    local current_cargo = tools.get_train_cargo(train_id)

    if not current_cargo then
        log("Could not get cargo for train: " .. tostring(train_id))
        return
    end

    ensure_storage()
    storage.next_order_id = storage.next_order_id or 1

    local order_id = storage.next_order_id
    storage.next_order_id = storage.next_order_id + 1

    local order = tools.get_order_data(
        order_id,
        train_id,
        delivery_data.started,
        delivery_data.network_id,
        current_cargo
    )

    local action = get_action_payload(
        order_id,
        "create",
        delivery_data
    )

    set_active_delivery(train_id, delivery_data, order_id, "created")

    log_payload("ORDER CREATED", order)
    log_payload("CREATE ACTION", action)
end

local function on_dispatcher_updated(event)
    local new_deliveries = event.new_deliveries or {}
    local deliveries = event.deliveries or {}

    for _, train_id in ipairs(new_deliveries) do
        local delivery_data = deliveries[train_id]

        if delivery_data then
            on_delivery_created(train_id, delivery_data)
        end
    end
end

local function on_delivery_pickup_complete(event)
    log("========== LTN PICKUP COMPLETE ==========")

    local train_id = event.train_id
    local active = check_state(train_id, {"created"})

    if not active then
        return
    end

    local action = get_action_payload(
        active.order_id,
        "accept",
        active.delivery
    )

    log_payload("ACCEPT ACTION", action)

    set_active_state(train_id, "accepted")
end

local function on_delivery_failed(event)
    log("========== LTN DELIVERY FAILED ==========")

    local train_id = event.train_id
    local active = check_state(train_id, {"created", "accepted", "reassigned"})

    if not active then
        return
    end

    local action = get_action_payload(
        active.order_id,
        "error",
        active.delivery
    )

    log_payload("ERROR ACTION", action)
    remove_active_delivery(train_id)
end

local function on_delivery_reassigned(event)
    log("========== LTN DELIVERY REASSIGNED ==========")

    local old_train_id = event.old_train_id
    local new_train_id = event.new_train_id

    ensure_storage()

    local old_active = get_active_delivery(old_train_id)

    if not old_active or not old_active.delivery then
        log("Delivery not found for old train: " .. tostring(old_train_id))
        return
    end

    local action = get_action_payload(
        old_active.order_id,
        "reassigned",
        old_active.delivery
    )

    log_payload("REASSIGNED ACTION", action)

    storage.active_deliveries[old_train_id] = nil

    storage.active_deliveries[new_train_id] = old_active
end

local function on_dispatcher_no_train_found()
    log("========== LTN DISPATCHER NO TRAIN FOUND ==========")
end

-- Связующие функции
local function register_ltn_event(event_name, callback)
    if not remote.interfaces[LTN_INTERFACE] then
        return false
    end

    local interface = remote.interfaces[LTN_INTERFACE]

    if not interface or interface[event_name] == nil then
        return false
    end

    local event_id = remote.call(LTN_INTERFACE, event_name)

    if event_id then
        script.on_event(event_id, callback)
        return true
    end

    return false
end

function actions.register_ltn_events()
    if not remote.interfaces[LTN_INTERFACE] then
        log("LTN interface not found")
        return
    end

    register_ltn_event("on_dispatcher_updated", on_dispatcher_updated)
    register_ltn_event("on_delivery_pickup_complete", on_delivery_pickup_complete)
    register_ltn_event("on_delivery_failed", on_delivery_failed)
    register_ltn_event("on_delivery_reassigned", on_delivery_reassigned)
    register_ltn_event("on_dispatcher_no_train_found", on_dispatcher_no_train_found)
    register_ltn_event("on_delivery_completed", on_delivery_completed)
end

local function debug_active_deliveries()

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

            debug_data.from_id =
                active.delivery.from_id

            debug_data.to_id =
                active.delivery.to_id

            debug_data.network_id =
                active.delivery.network_id

            debug_data.started =
                active.delivery.started

        else

            debug_data.ERROR =
                "Invalid active_delivery format"

        end

        game.print(
            serpent.block(debug_data)
        )

        log(
            serpent.block(debug_data)
        )
    end
end

function actions.debug_active_deliveries()
    debug_active_deliveries()
end

function actions.debug_clear_active_deliveries()

    storage.active_deliveries = {}

    game.print(
        "Active deliveries storage cleared."
    )

    log(
        "========== ACTIVE DELIVERIES CLEARED =========="
    )
end

return actions
