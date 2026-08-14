local tools = {}

function tools.get_next_action_id()
    storage.next_action_id = storage.next_action_id or 1

    local action_id = storage.next_action_id
    storage.next_action_id = storage.next_action_id + 1

    return action_id
end

function tools.get_train_data(train_id)
    local train = game.train_manager.get_train_by_id(train_id)

    if not train then
        return nil
    end

    local data = {
        id = train.id,
        length = "",
        wagons_types = {},
        fuel = {},
        name = nil,
        planet = nil
    }

    -- ========================================
    -- ИМЯ ПОЕЗДА
    -- ========================================

    local front_movers = train.locomotives.front_movers

    if front_movers and #front_movers > 0 then
        local leading_locomotive = front_movers[1]

        if leading_locomotive.valid then
            data.name = leading_locomotive.backer_name
        end
    end

    -- ========================================
    -- ПЛАНЕТА
    -- ========================================

    local planet = nil

    if train.front_stock and train.front_stock.valid then
        local surface = train.front_stock.surface

        if surface and surface.valid then
            if surface.planet then
                planet = surface.planet.name
            else
                planet = surface.name
            end
        end
    end

    data.planet = planet

    -- ========================================
    -- СОСТАВ ПОЕЗДА
    -- ========================================

    local front_locomotives = 0
    local rear_locomotives = 0
    local wagon_count = 0

    local carriages = train.carriages

    -- Ищем первый вагон, который не является локомотивом.
    local first_wagon_index = nil

    for i, carriage in ipairs(carriages) do
        if carriage.type ~= "locomotive" then
            first_wagon_index = i
            break
        end
    end

    -- Если в составе вообще нет вагонов,
    -- весь состав считаем локомотивами.
    if not first_wagon_index then
        front_locomotives = #carriages
    else

        -- Локомотивы ДО первого вагона
        front_locomotives = first_wagon_index - 1

        -- Считаем грузовые вагоны
        for i = first_wagon_index, #carriages do
            local carriage = carriages[i]

            if carriage.type == "cargo-wagon"
                or carriage.type == "fluid-wagon"
                or carriage.type == "artillery-wagon" then

                wagon_count = wagon_count + 1
            end
        end

        -- Локомотивы ПОСЛЕ последнего вагона
        for i = #carriages, first_wagon_index, -1 do
            local carriage = carriages[i]

            if carriage.type == "locomotive" then
                rear_locomotives = rear_locomotives + 1
            else
                break
            end
        end
    end

    data.length =
    tostring(front_locomotives)
    .. "-"
    .. tostring(wagon_count)
    .. "-"
    .. tostring(rear_locomotives)

    -- ========================================
    -- ТИПЫ ВАГОНОВ И ТОПЛИВО ЛОКОМОТИВОВ
    -- ========================================

    local wagon_types_set = {}

    for _, carriage in ipairs(train.carriages) do

        -- Вагоны
        if carriage.type ~= "locomotive" then
            local wagon_type = carriage.name

            if not wagon_types_set[wagon_type] then
                wagon_types_set[wagon_type] = true
                table.insert(data.wagons_types, wagon_type)
            end
        end

        -- Локомотив
        if carriage.type == "locomotive" then
            local fuel_inventory = carriage.get_fuel_inventory()

            -- Топливо
            if fuel_inventory then
                for slot = 1, #fuel_inventory do
                    local stack = fuel_inventory[slot]

                    if stack and stack.valid_for_read then
                        data.fuel[stack.name] =
                            (data.fuel[stack.name] or 0)
                            + stack.count
                    end
                end
            end
        end
    end

    return data
end

function tools.get_train_cargo(train_id)

    local train = game.train_manager.get_train_by_id(train_id)

    if not train then
        return nil
    end

    local cargo = {}

    -- ========================================
    -- ПРЕДМЕТЫ
    -- ========================================

    local item_contents = train.get_contents()

    for name, count in pairs(item_contents) do

        if type(count) == "table" then
            cargo["item," .. count.name] = count.count
        else
            cargo["item," .. name] = count
        end

    end

    -- ========================================
    -- ЖИДКОСТИ
    -- ========================================

    local fluid_contents = train.get_fluid_contents()

    for name, amount in pairs(fluid_contents) do

        if type(amount) == "table" then
            cargo["fluid," .. name] = amount.amount
        else
            cargo["fluid," .. name] = amount
        end

    end

    return cargo
end

function tools.get_station_data(station_id)

    local station = game.get_entity_by_unit_number(station_id)

    if not station or not station.valid then
        return nil
    end

    if station.type ~= "train-stop" then
        return nil
    end

    local data = {
        id = station.unit_number,
        name = station.backer_name,
        position = {
            x = station.position.x,
            y = station.position.y
        },
        planet = nil
    }

    -- ========================================
    -- ПЛАНЕТА СТАНЦИИ
    -- ========================================

    local surface = station.surface

    if surface and surface.valid then
        if surface.planet and surface.planet.valid then
            data.planet = surface.planet.name
        else
            data.planet = surface.name
        end
    end

    return data
end

function tools.get_action_data(action_id, action, from_id, to_id)
    return {
        id = action_id,
        action = action,
        from_id = from_id,
        to_id = to_id
    }
end

function tools.get_order_data(action_id, train_id, time, network_id, current_cargo)
    return {
        action_id = action_id,
        train_id = train_id,
        time = time,
        network_id = network_id,
        current_cargo = current_cargo or {}
    }
end

return tools