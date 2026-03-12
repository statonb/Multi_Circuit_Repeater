data:extend({
    {
        type = "bool-setting",
        name = "enable-wct-debug-messages",
        setting_type = "runtime-per-user", -- Can be 'startup', 'runtime-global', or 'runtime-per-user'
        default_value = false, -- Default state of the setting
        order = "a" -- Optional: determines the order in the settings menu
    },
    {
        type = "bool-setting",
        name = "disable-tower-power-checks",
        setting_type = "runtime-per-user", -- Can be 'startup', 'runtime-global', or 'runtime-per-user'
        default_value = false, -- Default state of the setting
        order = "b" -- Optional: determines the order in the settings menu
    }
})