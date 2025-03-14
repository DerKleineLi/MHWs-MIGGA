local config = json.load_file("No_KeyLag_settings.json")

config = config or {}
config.enabled = config.enabled or true

local function preHook(args)
    if not config.enabled then return end
    -- local parent = args[1]
    local cLaggedKey = sdk.to_managed_object(args[2])
    if not cLaggedKey then return end
    -- log.debug("cLaggedKey: " .. string.format("%X", cLaggedKey:get_address()))
    -- local key_type = cLaggedKey:get_KeyType()
    -- log.debug("key_type: " .. key_type)
    local lag_frame = cLaggedKey:get_LagTime()
    -- log.debug("lag_frame: " .. lag_frame)
    if lag_frame and lag_frame > 0 then
        -- log.debug(tostring(parent))
        -- log.debug(string.format("%X", cLaggedKey:get_address()) .. ", lag_frame: " .. lag_frame)
        cLaggedKey:set_LagTime(0)
    end
end

sdk.hook(sdk.find_type_definition("app.cLaggedKey"):get_method("onCustomUpdate"), preHook, nil)

re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("No KeyLag") then
        local changed = false

        changed, config.enabled = imgui.checkbox("Enable", config.enabled)
        
        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("No_KeyLag_settings.json", config)
    end
)