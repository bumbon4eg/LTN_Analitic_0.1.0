local tools = {}

-- ========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ АГРЕГАЦИИ
-- ========================================

---@param content ContentData
---@param content_name string
---@param amount number
---@return nil
local function add_content(content, content_name, amount)
    content[content_name] =
        (content[content_name] or 0) + amount
end

---@param content ContentData
---@param inventory LuaInventory|nil
---@return nil
local function add_inventory_content(content, inventory)
    if not inventory then
        return
    end

    for name, count in pairs(inventory.get_contents()) do
        if type(count) == "table" then
            add_content(content, count.name, count.count)
        else
            ---@type any
            local numeric_count = count
            add_content(content, tostring(name), numeric_count)
        end
    end
end

---@param content ContentData
---@param fluid_contents table<string, number|table>
---@return nil
local function add_fluid_content(content, fluid_contents)
    for name, amount in pairs(fluid_contents) do
        if type(amount) == "table" then
            add_content(content, name, amount.amount)
        else
            add_content(content, name, amount)
        end
    end
end

-- ========================================
-- ОСНОВНЫЕ ФУНКЦИИ ДЛЯ ПОЛУЧЕНИЯ ДАННЫХ
-- ========================================

---@param train_id TrainId
---@return TrainData|nil
function tools.get_train_data(train_id)
    local train = game.train_manager.get_train_by_id(train_id)

    if not train then
        return nil
    end

    local data = {
        id = train.id,
        length = "",
        composition_summary = {},
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
    -- СВОДКА СОСТАВА И ТОПЛИВО
    -- ========================================

    local composition_summary = {}
    local fuel_counts = {}

    for _, carriage in ipairs(train.carriages) do

        if carriage.type ~= "locomotive" then
            local wagon_type = carriage.name
            local wagon_summary = composition_summary[wagon_type]

            if not wagon_summary then
                wagon_summary = {
                    count = 0,
                    content = {}
                }
                composition_summary[wagon_type] = wagon_summary
            end

            wagon_summary.count = wagon_summary.count + 1

            if carriage.type == "cargo-wagon" then
                add_inventory_content(
                    wagon_summary.content,
                    carriage.get_inventory(defines.inventory.cargo_wagon)
                )
            elseif carriage.type == "fluid-wagon" then
                add_fluid_content(
                    wagon_summary.content,
                    carriage.get_fluid_contents()
                )
            elseif carriage.type == "artillery-wagon" then
                add_inventory_content(
                    wagon_summary.content,
                    carriage.get_inventory(defines.inventory.artillery_wagon_ammo)
                )
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
                        fuel_counts[stack.name] =
                            (fuel_counts[stack.name] or 0)
                            + stack.count
                    end
                end
            end
        end
    end

    data.composition_summary = composition_summary

    for fuel_type, count in pairs(fuel_counts) do
        table.insert(
            data.fuel,
            {
                type = fuel_type,
                count = count
            }
        )
    end

    return data
end

---@param train_id TrainId
---@return CargoData|nil
function tools.get_train_cargo(train_id)

    local train = game.train_manager.get_train_by_id(train_id)

    if not train then
        return nil
    end

    local cargo_counts = {}

    -- ========================================
    -- ПРЕДМЕТЫ
    -- ========================================

    local item_contents = train.get_contents()

    for name, count in pairs(item_contents) do

        if type(count) == "table" then
            add_content(cargo_counts, count.name, count.count)
        else
            ---@type any
            local numeric_count = count
            add_content(cargo_counts, tostring(name), numeric_count)
        end

    end

    -- ========================================
    -- ЖИДКОСТИ
    -- ========================================

    local fluid_contents = train.get_fluid_contents()

    for name, amount in pairs(fluid_contents) do

        if type(amount) == "table" then
            add_content(cargo_counts, name, amount.amount)
        else
            add_content(cargo_counts, name, amount)
        end

    end

    local cargo = {}

    for cargo_type, count in pairs(cargo_counts) do
        table.insert(
            cargo,
            {
                type = cargo_type,
                count = count
            }
        )
    end

    return cargo
end

---@param station_id StationId
---@return StationData|nil
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

-- ========================================
-- НОВЫЕ ФУНКЦИИ ДЛЯ ЗАКАЗОВ И СОБЫТИЙ
-- ========================================

---@param delivery_data DeliveryData
---@return CargoData
function tools.extract_required(delivery_data)
    local required_counts = {}

    -- Попытка извлечь запрошенные предметы и жидкости из различных полей LTN
    -- Проверяем наличие массивов requested_items/requested_fluids (новый LTN)
    if delivery_data.requested_items then
        for _, item in ipairs(delivery_data.requested_items) do
            if type(item) == "table" and item.name and item.amount then
                add_content(required_counts, item.name, item.amount)
            end
        end
    end
    if delivery_data.requested_fluids then
        for _, fluid in ipairs(delivery_data.requested_fluids) do
            if type(fluid) == "table" and fluid.name and fluid.amount then
                add_content(required_counts, fluid.name, fluid.amount)
            end
        end
    end

    -- Старые поля (одиночные запросы)
    if delivery_data.item and delivery_data.amount then
        add_content(required_counts, delivery_data.item, delivery_data.amount)
    end
    if delivery_data.fluid and delivery_data.fluid_amount then
        add_content(required_counts, delivery_data.fluid, delivery_data.fluid_amount)
    end

    -- Преобразуем в массив CountData
    local result = {}
    for name, count in pairs(required_counts) do
        table.insert(result, { type = name, count = count })
    end
    return result
end

---@param order_id OrderId
---@param creation_time Tick
---@param network_id NetworkId
---@param train_id TrainId
---@param current_content CargoData
---@param required CargoData
---@return OrderData
function tools.get_order_data(order_id, creation_time, network_id, train_id, current_content, required)
    return {
        id = order_id,
        creation_time = creation_time,
        network_id = network_id,
        train_id = train_id,
        current_content = current_content,
        required = required
    }
end

---@param event_id UUID_V4
---@param order_id OrderId
---@param action ActionName
---@param from_id StationId|nil
---@param to_id StationId|nil
---@param is_empty boolean
---@param tick Tick
---@param train_id TrainId
---@return OrderEventData
function tools.get_order_event_data(event_id, order_id, action, from_id, to_id, is_empty, tick, train_id)
    return {
        id = event_id,
        order_id = order_id,
        action = action,
        from_id = from_id,
        to_id = to_id,
        is_empty = is_empty,
        tick = tick,
        train_id = train_id
    }
end

---@param request_table table<string, number>  # Ключи могут содержать префиксы "item," или "fluid,"
---@return CargoData
function tools.extract_required_from_request(request_table)
    local result = {}

    for key, amount in pairs(request_table) do
        -- Убираем префикс "item," или "fluid," если они есть
        local name = key:gsub("^item,", ""):gsub("^fluid,", "")
        table.insert(result, { type = name, count = amount })
    end

    return result
end

return tools