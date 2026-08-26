---@type ActionsModule
local actions = require("actions")
local storage_api = require("storage")

---@type DebugModule
---@diagnostic disable-next-line: assign-type-mismatch
local debug_api = require("debug")

---@type JsonlModule
local jsonl = require("jsonl")


-- ========================================
-- SCRIPT EVENTS            
-- ========================================

---@return nil
script.on_init(function()
    storage_api.ensure()
    actions.register_ltn_events()
    jsonl.register()
end)

---@return nil
script.on_configuration_changed(function()
    storage_api.ensure()
    actions.register_ltn_events()
    jsonl.register()
end)

---@return nil
script.on_load(function()
    -- В on_load нельзя вызывать storage_api.ensure() (генерация UUID запрещена).
    -- Только регистрация обработчиков событий и таймеров.
    actions.register_ltn_events()
    jsonl.register()
end)


-- ========================================
-- ACTIVE ORDERS
-- ========================================

commands.add_command(
    "ltn_debug_world_id",
    "Show persistent world ID",
    ---@return nil
    function()
        debug_api.show_world_id()
    end
)

commands.add_command(
    "ltn_regenerate_world_id",
    "Generate a new persistent world ID",
    ---@return nil
    function()
        debug_api.regenerate_world_id()
    end
)

commands.add_command(
    "ltn_debug_orders",
    "Show active LTN orders",
    ---@return nil
    function()
        debug_api.show_active_deliveries()
    end
)


commands.add_command(
    "ltn_clear_active",
    "Clear active LTN deliveries",
    ---@return nil
    function()
        debug_api.clear_active_deliveries()
    end
)


-- ========================================
-- SEND BUFFER
-- ========================================

commands.add_command(
    "ltn_debug_buffer",
    "Show LTN send buffer",
    ---@return nil
    function()
        debug_api.show_send_buffer()
    end
)


commands.add_command(
    "ltn_debug_send_data",
    "Show collected data for sending",
    ---@return nil
    function()
        debug_api.show_send_data()
    end
)


commands.add_command(
    "ltn_clear_buffer",
    "Clear LTN send buffer",
    ---@return nil
    function()
        debug_api.clear_send_buffer()
    end
)


-- ========================================
-- ORDER
-- ========================================

commands.add_command(
    "ltn_debug_order",
    "Show Order and its Events",
    ---@param command table
    ---@return nil
    function(command)
        debug_api.show_order(command.parameter)
    end
)


-- ========================================
-- JSONL
-- ========================================

commands.add_command(
    "ltn_write_jsonl",
    "Write current buffer to JSONL",
    ---@return nil
    function()
        ---@diagnostic disable-next-line: undefined-field
        debug_api.write_jsonl_now()
    end
)