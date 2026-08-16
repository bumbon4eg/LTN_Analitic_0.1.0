local actions = require("actions")

script.on_init(function()
    actions.register_ltn_events()
end)

script.on_configuration_changed(function()
    actions.register_ltn_events()
end)



