local actions = require("actions")
local debug = require("debug")

script.on_init(function()
    actions.register_ltn_events()
end)

script.on_configuration_changed(function()
    actions.register_ltn_events()
end)

commands.add_command(
    "ltn_debug_orders",
    "Show active LTN orders",
    function()
        debug.show_active_deliveries()
    end
)

commands.add_command(
    "ltn_clear_active",
    "Clear active LTN deliveries",
    function()
        debug.clear_active_deliveries()
    end
)

commands.add_command(
    "ltn_debug_buffer",
    "Show LTN send buffer",
    function()
        debug.show_send_buffer()
    end
)

commands.add_command(
    "ltn_debug_send_data",
    "Show collected data for sending",
    function()
        debug.show_send_data()
    end
)
