local tools = require("tools")

local LTN_INTERFACE = "logistic-train-network"

local actions = {}

local function ensure_storage()
    storage.active_deliveries = storage.active_deliveries or {}
end

local function get_active_delivery(train_id)
    ensure_storage()
    return storage.active_deliveries[train_id]
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

local function on_delivery_completed(event)
    log("========== LTN DELIVERY COMPLETED ==========")

    local train_id = event.train_id
    local active = get_active_delivery(train_id)

    if not active or not active.delivery then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local action = get_action_payload(
        active.order_id,
        "complete",
        active.delivery
    )

    log_payload("COMPLETE ACTION", action)
    storage.active_deliveries[train_id] = nil
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

    storage.active_deliveries[train_id] = {
        delivery = delivery_data,
        order_id = order_id
    }

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
    local active = get_active_delivery(train_id)

    if not active or not active.delivery then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local action = get_action_payload(
        active.order_id,
        "accept",
        active.delivery
    )

    log_payload("ACCEPT ACTION", action)
end

local function on_delivery_failed(event)
    log("========== LTN DELIVERY FAILED ==========")

    local train_id = event.train_id
    local active = get_active_delivery(train_id)

    if not active or not active.delivery then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local action = get_action_payload(
        active.order_id,
        "error",
        active.delivery
    )

    log_payload("ERROR ACTION", action)
    storage.active_deliveries[train_id] = nil
end

local function on_delivery_reassigned(event)
    log("========== LTN DELIVERY REASSIGNED ==========")

    local old_train_id = event.old_train_id
    local new_train_id = event.new_train_id

    ensure_storage()

    local active = storage.active_deliveries[old_train_id]

    if not active or not active.delivery then
        log("Delivery not found for old train: " .. tostring(old_train_id))
        return
    end

    local action = get_action_payload(
        active.order_id,
        "reassigned",
        active.delivery
    )

    log_payload("REASSIGNED ACTION", action)

    storage.active_deliveries[old_train_id] = nil
    storage.active_deliveries[new_train_id] = active
end

local function on_dispatcher_no_train_found()
    log("========== LTN DISPATCHER NO TRAIN FOUND ==========")
end

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

return actions
