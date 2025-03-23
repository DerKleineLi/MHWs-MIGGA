-- config
local config = json.load_file("Kinsect_dont_come_back_settings.json")

config = config or {}
config.auto_back_time = config.auto_back_time or 200.0
config.charged_attack = config.charged_attack or true
config.helicopter = config.helicopter or true
config.aim_attack_start = config.aim_attack_start or true
config.aim_attack_end = config.aim_attack_end or true
config.wide_sweep = config.wide_sweep or true

-- action states
-- app.Wp10Action.cHoldAttackSuper.doUpdate()
local in_hold_attack = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttackSuper"):get_method("doUpdate()"),
function(args)
    in_hold_attack = true
end, function(retval)
    in_hold_attack = false
    return retval
end)

-- app.Wp10Action.cBatonUpSlashSuper.doEnter()
local in_baton_up_slash = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonUpSlashSuper"):get_method("doEnter()"),
function(args)
    in_baton_up_slash = true
end, function(retval)
    in_baton_up_slash = false
    return retval
end)

-- -- app.Wp10InsectAction.cPassBase.update()
-- local in_pass_base_update = false
-- sdk.hook(sdk.find_type_definition("app.Wp10InsectAction.cPassBase"):get_method("update"),
-- function(args)
--     in_pass_base_update = true
-- end, function(retval)
--     in_pass_base_update = false
--     return retval
-- end)

-- app.Wp10Action.cAimAttack.doEnter()
local in_aim_attack = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cAimAttack"):get_method("doEnter()"),
function(args)
    in_aim_attack = true
end, function(retval)
    in_aim_attack = false
    return retval
end)

-- app.Wp10InsectAction.cAimAttack.update()
local in_aim_attack_update = false
sdk.hook(sdk.find_type_definition("app.Wp10InsectAction.cAimAttack"):get_method("update"),
function(args)
    in_aim_attack_update = true
end, function(retval)
    in_aim_attack_update = false
    return retval
end)

-- app.Wp10Action.cBatonSSlash.doEnter()
local in_baton_s_slash = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonSSlash"):get_method("doEnter()"),
function(args)
    in_baton_s_slash = true
end, function(retval)
    in_baton_s_slash = false
    return retval
end)

-- core
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("requestChangeAction(ace.ACTION_ID, System.Boolean)"), 
function(args)
    local Wp10Insect = sdk.to_managed_object(args[2])
    if not Wp10Insect then return end

    -- auto back time
    local action_param = Wp10Insect._ActionParam
    local target_time = config.auto_back_time
    if config.auto_back_time >= 199.95 then
        target_time = 9999.0
    end
    action_param._InsectAutoBackTime = target_time

    local action_id = args[3]
    local category = sdk.get_native_field(action_id, sdk.find_type_definition("ace.ACTION_ID"), "_Category")
    local index = sdk.get_native_field(action_id, sdk.find_type_definition("ace.ACTION_ID"), "_Index")
    -- log.debug("category: " .. category .. ", index: " .. index)
    if category == 0 and index == 17 then
        if in_hold_attack and config.charged_attack then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
        if in_baton_up_slash and config.helicopter then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
    if category == 0 and index == 13 then
        if in_aim_attack and config.aim_attack_start then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
    if category == 0 and index == 4 then
        if in_aim_attack_update and config.aim_attack_end then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
        if in_baton_s_slash and config.wide_sweep then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
    -- if category == 0 and index == 5 then
    --     if in_pass_base_update then
    --         local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
    --         local instance = ValueType.new(ActionIDType)
    --         sdk.set_native_field(instance, ActionIDType, "_Category", 0)
    --         sdk.set_native_field(instance, ActionIDType, "_Index", 0)
    --         Wp10Insect:call("requestChangeAction(ace.ACTION_ID, System.Boolean)", instance, false)
    --         return sdk.PreHookResult.SKIP_ORIGINAL
    --     end
    -- end
end, nil)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Kinsect, Don't Come Back!") then
        changed, config.auto_back_time = imgui.drag_float("Auto Back Time", config.auto_back_time, 0.1, 0, 200, "%.2f")
        imgui.text("Default: 3.0; Set to 200.0 to disable auto back")
        changed, config.charged_attack = imgui.checkbox("Charged Attack", config.charged_attack)
        changed, config.helicopter = imgui.checkbox("Helicopter", config.helicopter)
        changed, config.aim_attack_start = imgui.checkbox("Aim Attack Start", config.aim_attack_start)
        changed, config.aim_attack_end = imgui.checkbox("Aim Attack End", config.aim_attack_end)
        changed, config.wide_sweep = imgui.checkbox("Wide Sweep (in focus mode)", config.wide_sweep)

        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("Kinsect_dont_come_back_settings.json", config)
    end
)