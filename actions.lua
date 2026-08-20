local tools = require("tools")
local buffer = require("buffer")
local storage_api = require("storage")

local LTN_INTERFACE = "logistic-train-network"

local actions = {}

local ACTION = {
    CREATE = "create",
    ACCEPT = "accept",
    FAILED = "error",
    REASSIGNED = "reassigned",
    COMPLETE = "complete"
}

local DELIVERY_STATE = {
    CREATED = "created",
    ACCEPTED = "accepted"
}

---@return nil
local function ensure_storage()
    storage_api.ensure()
end

---@param train_id TrainId
---@return ActiveDelivery|nil
local function get_active_delivery(train_id)
    ensure_storage()
    return storage.active_deliveries[train_id]
end

---@param train_id TrainId
---@param delivery_data DeliveryData
---@param order_id OrderId
---@param state DeliveryState
---@return nil
local function set_active_delivery(train_id, delivery_data, order_id, state)
    ensure_storage()

    storage.active_deliveries[train_id] = {
        delivery = delivery_data,
        order_id = order_id,
        state = state
    }
end

---@param train_id TrainId
---@return nil
local function remove_active_delivery(train_id)
    ensure_storage()

    storage.active_deliveries[train_id] = nil
end

---@param train_id TrainId
---@param state DeliveryState
---@return boolean
local function set_active_state(train_id, state)
    local active = get_active_delivery(train_id)

    if not active then
        return false
    end

    active.state = state
    return true
end

---@param train_id TrainId
---@param expected_states DeliveryState[]
---@return ActiveDelivery|nil
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

---@param order_id OrderId
---@param action_name ActionName
---@param delivery_data DeliveryData
---@return ActionData|nil
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

---@param label string
---@param payload table|nil
---@return nil
local function log_payload(label, payload)
    if payload then
        log("========== " .. label .. " ==========")
        log(serpent.block(payload))
    end
end

---@param order_id OrderId
---@param action_name ActionName
---@param delivery_data DeliveryData
---@param log_label string
---@return ActionData|nil
local function record_action(order_id, action_name, delivery_data, log_label)
    local action = get_action_payload(
        order_id,
        action_name,
        delivery_data
    )

    if not action then
        return nil
    end

    log_payload(log_label, action)
    buffer.buffer_action(action)

    return action
end

-- Обработка событий
---@param event LtnTrainDeliveryEvent
---@return nil
local function on_delivery_completed(event)
    log("========== LTN DELIVERY COMPLETED ==========")

    local train_id = event.train_id
    local active = check_state(train_id, {DELIVERY_STATE.ACCEPTED})

    if not active then
        return
    end

    record_action(
        active.order_id,
        ACTION.COMPLETE,
        active.delivery,
        "COMPLETE ACTION"
    )

    remove_active_delivery(train_id)
end

---@param train_id TrainId
---@param delivery_data DeliveryData
---@return nil
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

    -- ========================================
    -- ORDER
    -- ========================================

    local order = tools.get_order_data(
        order_id,
        train_id,
        delivery_data.started,
        delivery_data.network_id,
        current_cargo
    )

    -- ========================================
    -- ACTION: CREATE
    -- ========================================

    -- ========================================
    -- TRAIN
    -- ========================================

    local train_data = tools.get_train_data(train_id)

    -- ========================================
    -- STATIONS
    -- ========================================

    local from_station = tools.get_station_data(delivery_data.from_id)
    local to_station = tools.get_station_data(delivery_data.to_id)

    -- ========================================
    -- ACTIVE DELIVERY
    -- ========================================

    set_active_delivery(
        train_id,
        delivery_data,
        order_id,
        DELIVERY_STATE.CREATED
    )

    -- ========================================
    -- BUFFER
    -- ========================================

    buffer.buffer_order(order)
    record_action(
        order_id,
        ACTION.CREATE,
        delivery_data,
        "CREATE ACTION"
    )
    buffer.buffer_train(train_data)
    buffer.buffer_station(from_station)
    buffer.buffer_station(to_station)

    log_payload("ORDER CREATED", order)
end

---@param event LtnDispatcherUpdatedEvent
---@return nil
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

---@param event LtnTrainDeliveryEvent
---@return nil
local function on_delivery_pickup_complete(event)
    log("========== LTN PICKUP COMPLETE ==========")

    local train_id = event.train_id
    local active = check_state(train_id, {DELIVERY_STATE.CREATED})

    if not active then
        return
    end

    record_action(
        active.order_id,
        ACTION.ACCEPT,
        active.delivery,
        "ACCEPT ACTION"
    )

    set_active_state(train_id, DELIVERY_STATE.ACCEPTED)
end

---@param event LtnTrainDeliveryEvent
---@return nil
local function on_delivery_failed(event)
    log("========== LTN DELIVERY FAILED ==========")

    local train_id = event.train_id
    local active = check_state(
        train_id,
        {DELIVERY_STATE.CREATED, DELIVERY_STATE.ACCEPTED}
    )

    if not active then
        return
    end

    record_action(
        active.order_id,
        ACTION.FAILED,
        active.delivery,
        "ERROR ACTION"
    )

    remove_active_delivery(train_id)
end

---@param event LtnDeliveryReassignedEvent
---@return nil
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

    record_action(
        old_active.order_id,
        ACTION.REASSIGNED,
        old_active.delivery,
        "REASSIGNED ACTION"
    )
    buffer.buffer_train(tools.get_train_data(new_train_id))

    -- Перенос активной доставки на новый поезд
    storage.active_deliveries[old_train_id] = nil
    storage.active_deliveries[new_train_id] = old_active
end

---@param event LtnDispatcherNoTrainFoundEvent
---@return nil
local function on_dispatcher_no_train_found(event)
    log("========== LTN DISPATCHER NO TRAIN FOUND ==========")
end

-- Связующие функции
---@param event_name LtnRemoteEventName
---@param callback fun(event: table): nil
---@return boolean
local function register_ltn_event(event_name, callback)
    if not remote.interfaces[LTN_INTERFACE] then
        return false
    end

    local interface = remote.interfaces[LTN_INTERFACE]

    if not interface or interface[event_name] == nil then
        return false
    end

    -- LTN is an external remote interface, so LuaLS cannot infer its method keys.
    ---@diagnostic disable-next-line: param-type-mismatch
    local event_id = remote.call(LTN_INTERFACE, event_name)

    if event_id then
        script.on_event(event_id, callback)
        return true
    end

    return false
end

---@return nil
function actions.register_ltn_events()

    log("========== REGISTERING LTN EVENTS ==========")

    if not remote.interfaces[LTN_INTERFACE] then
        log("LTN interface not found")
        return
    end

    local events = {
        {
            name = "on_dispatcher_updated",
            callback = on_dispatcher_updated
        },
        {
            name = "on_delivery_pickup_complete",
            callback = on_delivery_pickup_complete
        },
        {
            name = "on_delivery_failed",
            callback = on_delivery_failed
        },
        {
            name = "on_delivery_reassigned",
            callback = on_delivery_reassigned
        },
        {
            name = "on_dispatcher_no_train_found",
            callback = on_dispatcher_no_train_found
        },
        {
            name = "on_delivery_completed",
            callback = on_delivery_completed
        }
    }

    for _, event_data in ipairs(events) do
        local registered = register_ltn_event(event_data.name, event_data.callback)
        log("LTN event " .. event_data.name .. ": " .. tostring(registered))
    end
end

return actions
