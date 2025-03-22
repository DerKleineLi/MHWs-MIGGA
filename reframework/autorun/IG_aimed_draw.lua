-- config
local config = json.load_file("IGAimedDraw_settings.json")

config = config or {}
config.enabled = config.enabled or true

-- core
local in_doEnter = false
sdk.hook(sdk.find_type_definition("app.Wp10SubAction.cInsectAttack"):get_method("doEnter()"),
function(args)
    in_doEnter = true
end, function(retval)
    in_doEnter = false
    return retval
end)

sdk.hook(sdk.find_type_definition("ace.ACTION_ID"):get_method("op_Inequality(ace.ACTION_ID, ace.ACTION_ID)"), nil,
function(retval)
    if in_doEnter and config.enabled then
        return sdk.to_ptr(true)
    end
    return retval
end)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Insect Glaive Aimed Draw") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)

        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("IGAimedDraw_settings.json", config)
    end
)