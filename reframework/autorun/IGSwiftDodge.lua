local config = json.load_file("IGSwiftDodge_settings.json")

config = config or {}
config.enable_hook = config.enable_hook or true
config.enable_back_dodge = config.enable_back_dodge or false
config.enable_landing = config.enable_landing or false

local function preChangeActionRequest(args)
    if not config.enable_hook then return end

    local player = sdk.to_managed_object(args[2])
    if not player then return end
    local weapon_type = player:get_WeaponType()
    if weapon_type ~= 10 then return end

    -- log.debug(string.format("%X", player:get_address()))
    -- log.debug("Weapon Type: " .. tostring(weapon_type))

    local layer = sdk.to_int64(args[3])
    local action_id_type = sdk.find_type_definition("ace.ACTION_ID")
    local action_id = args[4]
    local category = sdk.get_native_field(action_id, action_id_type, "_Category")
    local index = sdk.get_native_field(action_id, action_id_type, "_Index")

    -- log.debug("changeActionRequest called with:")
    -- log.debug("Layer: " .. tostring(layer))
    -- log.debug("Action ID: " .. tostring(category) .. ":" .. tostring(index))

    if layer == 0 and category == 2 and (index == 55 or index == 56 or (config.enable_landing and (index == 36 or index == 46 or index == 49))) then
        local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
        local instance = ValueType.new(ActionIDType)
        sdk.set_native_field(instance, ActionIDType, "_Category", 1)
        sdk.set_native_field(instance, ActionIDType, "_Index", 15)

        player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, false)

        return sdk.PreHookResult.SKIP_ORIGINAL
    end

    if layer == 1 and category == 1 and index == 9 then
        local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")

        local instance = ValueType.new(ActionIDType)
        sdk.set_native_field(instance, ActionIDType, "_Category", 1)
        sdk.set_native_field(instance, ActionIDType, "_Index", 14)

        player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, false)

        local instance = ValueType.new(ActionIDType)
        sdk.set_native_field(instance, ActionIDType, "_Category", 1)
        sdk.set_native_field(instance, ActionIDType, "_Index", 10)

        player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 1, instance, false)

        return sdk.PreHookResult.SKIP_ORIGINAL
    end

    if layer == 0 and category == 1 and (index == 20 or (config.enable_back_dodge and index == 21)) then
        local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
        local instance = ValueType.new(ActionIDType)
        sdk.set_native_field(instance, ActionIDType, "_Category", 1)
        sdk.set_native_field(instance, ActionIDType, "_Index", 19)

        player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, true)

        return sdk.PreHookResult.SKIP_ORIGINAL
    end

end

sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"), preChangeActionRequest, nil)

re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("IG Swift Dodge") then
        local changed = false

        changed, config.enable_hook = imgui.checkbox("Basic", config.enable_hook)
        changed, config.enable_back_dodge = imgui.checkbox("Back Dodge", config.enable_back_dodge)
        changed, config.enable_landing = imgui.checkbox("Air Landing", config.enable_landing)

        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("IGSwiftDodge_settings.json", config)
    end
)