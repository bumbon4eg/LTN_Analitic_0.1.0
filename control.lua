local tools = require("tools")

local LTN_INTERFACE = "logistic-train-network"


-- ========================================
-- CREATE DELIVERY
-- ========================================

local function on_delivery_created(train_id, delivery_data)

    if not delivery_data then
        return
    end

    storage.active_deliveries = storage.active_deliveries or {}
    storage.active_deliveries[train_id] = delivery_data

    local action_id = tools.get_next_action_id()

    local action = tools.get_action_data(
        action_id,
        "create",
        delivery_data.from_id,
        delivery_data.to_id
    )

    log("========== DELIVERY CREATED ==========")
    log(serpent.block(action))
end


-- ========================================
-- LTN DISPATCHER UPDATED
-- ========================================

local function on_dispatcher_updated(event)

    local new_deliveries = event.new_deliveries or {}
    local deliveries = event.deliveries or {}

    -- LTN может вызывать это событие постоянно.
    -- Само событие ничего не создаёт.
    -- Обрабатываем только действительно новые доставки.

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
    storage.active_deliveries = storage.active_deliveries or {}
    local delivery_data = storage.active_deliveries[train_id]

    if not delivery_data then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    -- ========================================
    -- ACTION: ACCEPT
    -- ========================================

    local action_id = tools.get_next_action_id()

    local action = tools.get_action_data(
        action_id,
        "accept",
        delivery_data.from_id,
        delivery_data.to_id
    )

    -- ========================================
    -- ФИЗИЧЕСКИЙ ГРУЗ ПОЕЗДА
    -- ========================================

    local current_cargo = tools.get_train_cargo(train_id)

    if not current_cargo then
        log("Could not get cargo for train: " .. tostring(train_id))
        return
    end

    -- ========================================
    -- ORDER
    -- ========================================

    local order = tools.get_order_data(
        action_id,
        train_id,
        delivery_data.started,
        delivery_data.network_id,
        current_cargo
    )

    log("========== ACCEPT ACTION ==========")
    log(serpent.block(action))

    log("========== ORDER ==========")
    log(serpent.block(order))

    -- Доставка больше не нужна в active_deliveries
    storage.active_deliveries[train_id] = nil
end

local function on_delivery_failed(event)

    log("========== LTN DELIVERY FAILED ==========")

    local train_id = event.train_id
    storage.active_deliveries = storage.active_deliveries or {}
    local delivery_data = storage.active_deliveries[train_id]

    if not delivery_data then
        log("Delivery not found for train: " .. tostring(train_id))
        return
    end

    local action_id = tools.get_next_action_id()

    local action = tools.get_action_data(
        action_id,
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

    -- Находим доставку у старого поезда
    local delivery_data = storage.active_deliveries[old_train_id]

    if not delivery_data then
        log("Delivery not found for old train: " .. tostring(old_train_id))
        return
    end

    -- ========================================
    -- ACTION: REASSIGNED
    -- ========================================

    local action_id = tools.get_next_action_id()

    local action = tools.get_action_data(
        action_id,
        "reassigned",
        delivery_data.from_id,
        delivery_data.to_id
    )

    log("========== REASSIGNED ACTION ==========")
    log(serpent.block(action))

    -- Переносим доставку на новый поезд
    storage.active_deliveries[old_train_id] = nil
    storage.active_deliveries[new_train_id] = delivery_data
end

local function on_dispatcher_no_train_found(event)

    log("========== LTN DISPATCHER NO TRAIN FOUND ==========")

    local action_id = tools.get_next_action_id()

    local action = tools.get_action_data(
        action_id,
        "reject",
        event.from_id,
        event.to_id
    )

    log("========== REJECT ACTION ==========")
    log(serpent.block(action))
end

local function register_ltn_events()
    if not remote.interfaces[LTN_INTERFACE] then
        log("LTN interface not found")
        return
    end

    -- ========================================
    -- DELIVERY SEARCH ON DISPATCHER UPDATED
    -- ========================================


    local event_id = remote.call(
        LTN_INTERFACE,
        "on_dispatcher_updated"
    )

    script.on_event(event_id, on_dispatcher_updated)

    -- ========================================
    -- DELIVERY COMPLETED
    -- ========================================


    local pickup_complete_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_pickup_complete"
    )

    script.on_event(pickup_complete_event_id, on_delivery_pickup_complete)

    -- ========================================
    -- DELIVERY FAILED
    -- ========================================

    local delivery_failed_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_failed"
    )

    script.on_event(delivery_failed_event_id, on_delivery_failed)

    -- ========================================
    -- DELIVERY REASSIGNED
    -- ========================================

    local delivery_reassigned_event_id = remote.call(
        LTN_INTERFACE,
        "on_delivery_reassigned"
    )

    script.on_event(delivery_reassigned_event_id, on_delivery_reassigned)

    -- ========================================
    -- DELIVERY REJECT
    -- ========================================

    local delivery_reject_event_id = remote.call(
        LTN_INTERFACE,
        "on_dispatcher_no_train_found"
    )

    script.on_event(delivery_reject_event_id, on_dispatcher_no_train_found)
end

script.on_init(function()
    register_ltn_events()
end)

script.on_configuration_changed(function()
    register_ltn_events()
end)



