local actions = require("actions")

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
        actions.debug_active_deliveries()
    end
)

commands.add_command(
    "ltn_clear_active",
    "Clear active LTN deliveries",
    function()
        actions.debug_clear_active_deliveries()
    end
)
