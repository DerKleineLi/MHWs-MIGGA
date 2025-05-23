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

local saved_config = json.load_file("Kinsect_dont_come_back_settings.json") or {}

local config = {
    auto_back_time = 200.0,
    charged_attack_is_tripple = true, -- true means don't come back
    charged_attack_not_tripple = false,
    helicopter = false,
    aim_attack_start_is_tripple = true,
    aim_attack_start_not_tripple = false,
    aim_attack_end_is_tripple = true,
    aim_attack_end_not_tripple = false,
    wide_sweep_is_tripple = true,
    wide_sweep_not_tripple = false,
    item_button_recall = true,
}

merge_tables(config, saved_config)

-- helper functions
local function get_input()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_controller = player_info:get_Controller()
    if not hunter_controller then return nil end
    local hunter_controller_entity_holder = hunter_controller:get_ControllerEntityHolder()
    if not hunter_controller_entity_holder then return nil end
    local master_player_controler_entity = hunter_controller_entity_holder:get_Master()
    if not master_player_controler_entity then return nil end
    local command_controller = master_player_controler_entity:get_CommandController()
    if not command_controller then return nil end
    local player_game_input_base = command_controller:get_MergedVirtualInput()
    return player_game_input_base
end

local function get_hunter()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_character = player_info:get_Character()
    return hunter_character
end

local function get_wp()
    local hunter = get_hunter()
    if not hunter then return nil end
    local wp = hunter:get_WeaponHandling()
    return wp
end

local function get_kinsect()
    local hunter = get_hunter()
    if not hunter then return nil end
    local kinsect = hunter:get_Wp10Insect()
    return kinsect
end

local function change_kinsect_action(category, index)
    local kinsect = get_kinsect()
    if not kinsect then return end
    local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
    local instance = ValueType.new(ActionIDType)
    sdk.set_native_field(instance, ActionIDType, "_Category", category)
    sdk.set_native_field(instance, ActionIDType, "_Index", index)
    kinsect:call("requestChangeAction(ace.ACTION_ID, System.Boolean)", instance, true)
end

-- action states
-- app.Wp10Action.cHoldAttackSuper.doUpdate()
local in_hold_attack = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttackSuper"):get_method("doUpdate()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_hold_attack = true
end, function(retval)
    in_hold_attack = false
    return retval
end)

-- app.Wp10Action.cBatonUpSlashSuper.doEnter()
local in_baton_up_slash = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonUpSlashSuper"):get_method("doEnter()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
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
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_aim_attack = true
end, function(retval)
    in_aim_attack = false
    return retval
end)

-- app.Wp10InsectAction.cAimAttack.update()
local in_aim_attack_update = false
sdk.hook(sdk.find_type_definition("app.Wp10InsectAction.cAimAttack"):get_method("update"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_aim_attack_update = true
end, function(retval)
    in_aim_attack_update = false
    return retval
end)

-- app.Wp10Action.cBatonSSlash.doEnter()
local in_baton_s_slash = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonSSlash"):get_method("doEnter()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_baton_s_slash = true
end, function(retval)
    in_baton_s_slash = false
    return retval
end)

-- core
local force_change_action = false
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("requestChangeAction(ace.ACTION_ID, System.Boolean)"), 
function(args)
    local Wp10Insect = sdk.to_managed_object(args[2])
    if not Wp10Insect then return end
    local hunter = Wp10Insect:get_Hunter()
    if not hunter then return end
    if not (hunter:get_IsMaster() and hunter:get_IsUserControl()) then return end

    if force_change_action then return end

    -- log.debug("hunter: " .. string.format("%x", hunter:get_address()))

    -- hunter state
    local Wp10Handling = Wp10Insect._Wp10
    local is_tripple_up = Wp10Handling:get_IsTrippleUp()

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
        if in_hold_attack then
            local should_skip = config.charged_attack_is_tripple and is_tripple_up
            -- should_skip = should_skip or (config.charged_attack_not_tripple and not is_tripple_up)
            if should_skip then
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
            
        end
        if in_baton_up_slash and config.helicopter then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
    if category == 0 and index == 13 then
        if in_aim_attack and ((config.aim_attack_start_is_tripple and is_tripple_up) or (config.aim_attack_start_not_tripple and not is_tripple_up)) then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
    if category == 0 and index == 4 then
        if in_aim_attack_update and ((config.aim_attack_end_is_tripple and is_tripple_up) or (config.aim_attack_end_not_tripple and not is_tripple_up)) then
            local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
            local instance = ValueType.new(ActionIDType)
            sdk.set_native_field(instance, ActionIDType, "_Category", 0)
            sdk.set_native_field(instance, ActionIDType, "_Index", 7)
            Wp10Insect:call("requestChangeAction(ace.ACTION_ID, System.Boolean)", instance, false)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
        if in_baton_s_slash and ((config.wide_sweep_is_tripple and is_tripple_up) or (config.wide_sweep_not_tripple and not is_tripple_up)) then
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

-- triangle recall kinsect
-- app.cPlayerCommandController.update
sdk.hook(sdk.find_type_definition("app.cPlayerCommandController"):get_method("update"), nil, 
function(retval)
    if not config.item_button_recall then return retval end
    local player_input = get_input()
    if not player_input then return end
    local key_idx = 6 -- square
    local key = player_input:getKey(key_idx)
    local on_trigger = key:get_OnTrigger()
    if on_trigger then
        local Wp10Insect = get_kinsect()
        if not Wp10Insect then return end
        force_change_action = true
        change_kinsect_action(0, 4)
        force_change_action = false
    end

    return retval
end)


-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Kinsect, Don't Come Back!") then
        changed, config.item_button_recall = imgui.checkbox("Item Button Recall Kinsect", config.item_button_recall)
        changed, config.auto_back_time = imgui.drag_float("Auto Back Time", config.auto_back_time, 0.1, 0, 200, "%.2f")
        imgui.text("Default: 3.0; Set to 200.0 to disable auto back")
        changed, config.charged_attack_is_tripple = imgui.checkbox("Charged Attack in Tripple Up", config.charged_attack_is_tripple)
        -- changed, config.charged_attack_not_tripple = imgui.checkbox("Charged Attack not Tripple Up", config.charged_attack_not_tripple)
        changed, config.helicopter = imgui.checkbox("Helicopter", config.helicopter)
        changed, config.aim_attack_start_is_tripple = imgui.checkbox("Aim Attack Start in Tripple Up", config.aim_attack_start_is_tripple)
        changed, config.aim_attack_start_not_tripple = imgui.checkbox("Aim Attack Start not Tripple Up", config.aim_attack_start_not_tripple)
        changed, config.aim_attack_end_is_tripple = imgui.checkbox("Aim Attack End in Tripple Up", config.aim_attack_end_is_tripple)
        changed, config.aim_attack_end_not_tripple = imgui.checkbox("Aim Attack End not Tripple Up", config.aim_attack_end_not_tripple)
        changed, config.wide_sweep_is_tripple = imgui.checkbox("Wide Sweep in Tripple Up", config.wide_sweep_is_tripple)
        changed, config.wide_sweep_not_tripple = imgui.checkbox("Wide Sweep not Tripple Up", config.wide_sweep_not_tripple)

        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("Kinsect_dont_come_back_settings.json", config)
    end
)