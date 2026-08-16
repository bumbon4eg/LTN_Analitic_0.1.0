local tools = require("tools")

local LTN_INTERFACE = "logistic-train-network"

local actions = {}

local function on_delivery_completed(event)

    log("========== LTN DELIVERY COMPLETED ==========")

    local train_id = event.train_id
    storage.active_deliveries = storage.active_deliveries or {}
    local active = storage.active_deliveries[train_id]

    if not active then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local delivery_data = active.delivery
    local order_id = active.order_id

    local action = tools.get_action_data(
        order_id,
        "complete",
        delivery_data.from_id,
        delivery_data.to_id
    )

    log("========== COMPLETE ACTION ==========")
    log(serpent.block(action))

    storage.active_deliveries[train_id] = nil
end

local function on_delivery_created(train_id, delivery_data)

    if not delivery_data then
        return
    end

    storage.active_deliveries = storage.active_deliveries or {}
    storage.next_order_id = storage.next_order_id or 1
    local order_id = storage.next_order_id
    storage.next_order_id = storage.next_order_id + 1

    local current_cargo = tools.get_train_cargo(train_id)

    if not current_cargo then
        log("Could not get cargo for train: " .. tostring(train_id))
        return
    end

    local order = tools.get_order_data(
        order_id,
        train_id,
        delivery_data.started,
        delivery_data.network_id,
        current_cargo
    )

    local action = tools.get_action_data(
        order_id,
        "create",
        delivery_data.from_id,
        delivery_data.to_id
    )

    storage.active_deliveries[train_id] = {
        delivery = delivery_data,
        order_id = order_id
    }

    log("========== ORDER CREATED ==========")
    log(serpent.block(order))

    log("========== CREATE ACTION ==========")
    log(serpent.block(action))
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
    local active = storage.active_deliveries[train_id]

    if not active then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local order_id = active.order_id
    local delivery_data = active.delivery

    if not delivery_data then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local action = tools.get_action_data(
        order_id,
        "accept",
        delivery_data.from_id,
        delivery_data.to_id
    )

    log("========== ACCEPT ACTION ==========")
    log(serpent.block(action))
end

local function on_delivery_failed(event)

    log("========== LTN DELIVERY FAILED ==========")

    local train_id = event.train_id
    local active = storage.active_deliveries[train_id]

    if not active then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local order_id = active.order_id
    local delivery_data = active.delivery

    if not delivery_data then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local action = tools.get_action_data(
        order_id,
        "error",
        delivery_data.from_id,
        delivery_data.to_id
    )

    log("========== ERROR ACTION ==========")
    log(serpent.block(action))

    storage.active_deliveries[train_id] = nil
end

local function on_delivery_reassigned(event)

    log("========== LTN DELIVERY REASSIGNED ==========")

    local old_train_id = event.old_train_id
    local new_train_id = event.new_train_id

    storage.active_deliveries = storage.active_deliveries or {}

    local active = storage.active_deliveries[old_train_id]

    if not active then
        log("Delivery not found for old train: " .. tostring(old_train_id))
        return
    end

    local order_id = active.order_id
    local delivery_data = active.delivery

    local action = tools.get_action_data(
        order_id,
        "reassigned",
        delivery_data.from_id,
        delivery_data.to_id
    )

    log("========== REASSIGNED ACTION ==========")
    log(serpent.block(action))

    storage.active_deliveries[old_train_id] = nil
    storage.active_deliveries[new_train_id] = active
end

local function on_dispatcher_no_train_found(event)
    log("========== LTN DISPATCHER NO TRAIN FOUND ==========")
end

function actions.register_ltn_events()
    if not remote.interfaces[LTN_INTERFACE] then
        log("LTN interface not found")
        return
    end

    local event_id = remote.call(
        LTN_INTERFACE,
        "on_dispatcher_updated"
    )

    script.on_event(event_id, on_dispatcher_updated)

    local pickup_complete_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_pickup_complete"
    )

    script.on_event(pickup_complete_event_id, on_delivery_pickup_complete)

    local delivery_failed_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_failed"
    )

    script.on_event(delivery_failed_event_id, on_delivery_failed)

    local delivery_reassigned_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_reassigned"
    )

    script.on_event(delivery_reassigned_event_id, on_delivery_reassigned)

    local delivery_reject_event_id = remote.call(
        LTN_INTERFACE,
        "on_dispatcher_no_train_found"
    )

    script.on_event(delivery_reject_event_id, on_dispatcher_no_train_found)

    local delivery_completed_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_completed"
    )

    script.on_event(delivery_completed_event_id, on_delivery_completed)
end

return actions
