local tools = require("tools")

local LTN_INTERFACE = "logistic-train-network"

local function on_dispatcher_updated(event)

    log("========== LTN EVENT ==========")

    local event_data = event
    local new_deliveries = event_data.new_deliveries or {}
    local deliveries = event_data.deliveries or {}

    storage.active_deliveries = storage.active_deliveries or {}
    storage.next_action_id = storage.next_action_id or 1

    -- Оставляет только новые доставки, которые были созданы в этом тике.
    -- Это избегает перегрузки хранилища.
    for _, train_id in ipairs(new_deliveries) do
        local delivery_data = deliveries[train_id]

        if delivery_data then
            storage.active_deliveries[train_id] = delivery_data

            local action_id = tools.get_next_action_id()

            local action = tools.get_action_data(
                action_id,
                "create",
                delivery_data
            )

            log(serpent.block(action))
        end
    end



    -- for _, train_id in ipairs(new_deliveries) do
    --     local train = game.train_manager.get_train_by_id(train_id)

    --     if not train then
    --         log("Train not found: " .. tostring(train_id))
    --         return
    --     end

    --     local mt = getmetatable(train)

    --     game.print(serpent.block(mt))

    --     table.insert(
    --         train_deliveries_data,
    --         {
    --             train = mt,
    --             delivery = deliveries[train_id],
    --         }
    --     )
    -- end

    

    -- game.print(
    --     "All data: " ..
    --     serpent.block(train_deliveries_data)
    -- )
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

    local action_id =
        tools.get_next_action_id()

    local action = tools.get_action_data(
        action_id,
        "accept",
        delivery_data
    )

    -- ========================================
    -- ФИЗИЧЕСКИЙ ГРУЗ ПОЕЗДА
    -- ========================================

    local current_cargo =
        tools.get_train_cargo(train_id)

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

script.on_init(function()

    -- TODO: добавить для действий "cancel" и "reject" (когда LTN не может найти поезд для доставки)
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

end)



