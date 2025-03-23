-- config
local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k] or false) == "table" then
            merge_tables(t1[k], v)
        else
            t1[k] = v
        end
    end
end

local saved_config = json.load_file("IGAimedDraw_settings.json") or {}

local config = {
    enabled = true,
}

merge_tables(config, saved_config)

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