-- const
local attack_types = {
    "charged_attack",
    "helicopter_start",
    "helicopter_end",
    "aim_attack_start",
    "aim_attack_end",
    "wide_sweep",
    "combo_attacks_end",
}
local speed_types = {
    "Unchanged",
    "Skip",
    "Instant",
}
local recall_types = {
    "Disabled",
    "Normal",
    "Instant",
}
local colab_types = {
    "Unchanged",
    "Always",
    "onAim",
    "notMarking",
    "onAimAndNotMarking",
    "Never",
}

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

local saved_config = json.load_file("Kinsect_dont_come_back.json") or {}

local function init_group_config()
    output = {}
    for _, attack_type in ipairs(attack_types) do
        output[attack_type] = 1
    end
    return output
end

local config = {
    auto_back_time = 200.0,
    is_tripple_up = init_group_config(),
    not_tripple_up = init_group_config(),
    item_button_recall = 1,
    colab_type = 1,
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

local function get_aim()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local player_context_holder = player_info:get_ContextHolder()
    if not player_context_holder then return nil end
    local hunter_context = player_context_holder:get_Hunter()
    if not hunter_context then return nil end
    local hunter_action_arg = hunter_context:get_ActionArg()
    if not hunter_action_arg then return nil end
    return hunter_action_arg:get_IsAim()
end

-- action states
local in_motion = {}
for _, attack_type in ipairs(attack_types) do
    in_motion[attack_type] = false
end

-- app.Wp10Action.cHoldAttackSuper.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttackSuper"):get_method("doUpdate()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_motion["charged_attack"] = true
end, function(retval)
    in_motion["charged_attack"] = false
    return retval
end)

-- app.Wp10Action.cBatonUpSlashSuper.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonUpSlashSuper"):get_method("doEnter()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_motion["helicopter_start"] = true
end, function(retval)
    in_motion["helicopter_start"] = false
    return retval
end)

-- app.cWp10InsectActionBase.update()
local parallel_call = 0
sdk.hook(sdk.find_type_definition("app.cWp10InsectActionBase"):get_method("update()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    parallel_call = parallel_call + 1

    local this_type = this:get_type_definition()
    local parent_types = {}
    local parent_type = this_type
    while parent_type:get_full_name() ~= "app.cWp10InsectActionBase" do
        parent_types[parent_type:get_full_name()] = true
        parent_type = parent_type:get_parent_type()
        if not parent_type then break end
    end

    if parent_types["app.Wp10InsectAction.cPassBase"] then
        in_motion["combo_attacks_end"] = true
    elseif parent_types["app.Wp10InsectAction.cFightTogetherConstBase"] then
        in_motion["helicopter_end"] = true
    elseif parent_types["app.Wp10InsectAction.cAimAttack"] then
        in_motion["aim_attack_end"] = true
    end
end, function(retval)
    parallel_call = parallel_call - 1
    if parallel_call > 0 then return retval end

    in_motion["combo_attacks_end"] = false
    in_motion["helicopter_end"] = false
    in_motion["aim_attack_end"] = false
    return retval
end)

-- security
re.on_frame(function()
    parallel_call = 0
end)

-- app.Wp10Action.cAimAttack.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cAimAttack"):get_method("doEnter()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_motion["aim_attack_start"] = true
end, function(retval)
    in_motion["aim_attack_start"] = false
    return retval
end)

-- app.Wp10Action.cBatonSSlash.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonSSlash"):get_method("doEnter()"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_motion["wide_sweep"] = true
end, function(retval)
    in_motion["wide_sweep"] = false
    return retval
end)

-- core
local force_change_action = false
local force_instant_recall = false

sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("requestChangeAction(ace.ACTION_ID, System.Boolean)"), 
function(args)
    local Wp10Insect = sdk.to_managed_object(args[2])
    if not Wp10Insect then return end
    local hunter = Wp10Insect:get_Hunter()
    if not hunter then return end
    if not (hunter:get_IsMaster() and hunter:get_IsUserControl()) then return end

    if force_change_action then return end

    -- hunter state
    local Wp10Handling = Wp10Insect._Wp10
    local is_tripple_up = Wp10Handling:get_IsTrippleUp()
    local tripple_up_config = is_tripple_up and config.is_tripple_up or config.not_tripple_up

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

    -- check recall action
    local is_recall_action = category == 0 and (index == 17 or index == 13 or index == 4 or index == 5)
    if not is_recall_action then return end

    local target_action = nil
    for attack_type, config_speed_type in pairs(tripple_up_config) do
        if in_motion[attack_type] then
            -- log.debug("in_motion: " .. attack_type)
            target_action = speed_types[config_speed_type]
            break
        end
    end
    if not target_action then return end
    -- log.debug("target_action: " .. target_action)
    if target_action == "Unchanged" then return end
    if target_action == "Skip" then
        if in_motion["combo_attacks_end"] or in_motion["helicopter_end"] or in_motion["aim_attack_end"] then
            change_kinsect_action(0, 7) -- idle
        end
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    if target_action == "Instant" then
        force_change_action = true
        force_instant_recall = true
        change_kinsect_action(0, 17) -- instant recall
        force_change_action = false
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end, nil)

-- app.cWp10InsectActionBase.enter()
local cJumpSlashBack = nil
sdk.hook(sdk.find_type_definition("app.cWp10InsectActionBase"):get_method("enter()"),
function(args)
    cJumpSlashBack = nil

    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    local this_type = this:get_type_definition():get_full_name()
    if this_type == "app.Wp10InsectAction.cJumpSlashBack" then
        cJumpSlashBack = this
    end

end, function(retval)
    if cJumpSlashBack and force_instant_recall then
        cJumpSlashBack._BackTime = 0.1
        force_instant_recall = false
    end
    return retval
end)


-- square recall kinsect
-- app.cPlayerCommandController.update
sdk.hook(sdk.find_type_definition("app.cPlayerCommandController"):get_method("update"), nil, 
function(retval)
    local item_button_recall = recall_types[config.item_button_recall]
    if not item_button_recall then return retval end
    if item_button_recall == "Disabled" then return retval end
    local player_input = get_input()
    if not player_input then return end
    local key_idx = 6 -- square
    local key = player_input:getKey(key_idx)
    local on_trigger = key:get_OnTrigger()
    if on_trigger then
        local Wp10Insect = get_kinsect()
        if not Wp10Insect then return end
        force_change_action = true
        if item_button_recall == "Normal" then
            change_kinsect_action(0, 4) -- normal recall
        elseif item_button_recall == "Instant" then
            change_kinsect_action(0, 17) -- instant recall
        end
        force_change_action = false
    end

    return retval
end)

-- Colab
-- app.Wp10Action.cWp10BatonAttackBase.get_EnableInsectFightTogether()
local is_master_insect_fight_together = false
sdk.hook(sdk.find_type_definition("app.Wp10Action.cWp10BatonAttackBase"):get_method("get_EnableInsectFightTogether()"),
function(args)
    is_master_insect_fight_together = false
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    is_master_insect_fight_together = true
end, function (retval)
    if not is_master_insect_fight_together then return retval end

    local colab_type = colab_types[config.colab_type]
    if not colab_type then return retval end
    if colab_type == "Unchanged" then return retval end
    if colab_type == "Always" then
        return sdk.to_ptr(true)
    end
    if colab_type == "Never" then
        return sdk.to_ptr(false)
    end
    local is_aim = get_aim()
    local wp = get_wp()
    if not wp then return retval end
    local is_marking = wp:isMarkingShellEnable()
    if colab_type == "onAim" and is_aim then
        return sdk.to_ptr(true)
    end
    if colab_type == "notMarking" and not is_marking then
        return sdk.to_ptr(true)
    end
    if colab_type == "onAimAndNotMarking" and is_aim and not is_marking then
        return sdk.to_ptr(true)
    end
    return retval
end)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Kinsect, Don't Come Back!") then
        changed, config.item_button_recall = imgui.slider_int("Item Button Recall Kinsect", config.item_button_recall, 1, #recall_types, recall_types[config.item_button_recall])
        changed, config.colab_type = imgui.slider_int("Kinsect Fight Together Timing", config.colab_type, 1, #colab_types, colab_types[config.colab_type])
        changed, config.auto_back_time = imgui.drag_float("Auto Back Time", config.auto_back_time, 0.1, 0, 200, "%.2f")
        imgui.text("Default: 3.0; Set to 200.0 to disable auto back")
        if imgui.tree_node("Tripple Up Config") then
            local config_table = config.is_tripple_up
            changed, config_table["charged_attack"] = imgui.slider_int("Charged Attack", config_table["charged_attack"], 1, #speed_types, speed_types[config_table["charged_attack"]])
            -- changed, config_table["helicopter_start"] = imgui.slider_int("Helicopter Start", config_table["helicopter_start"], 1, #speed_types, speed_types[config_table["helicopter_start"]])
            changed, config_table["aim_attack_start"] = imgui.slider_int("Focus Strike Start", config_table["aim_attack_start"], 1, #speed_types, speed_types[config_table["aim_attack_start"]])
            changed, config_table["aim_attack_end"] = imgui.slider_int("Focus Strike End", config_table["aim_attack_end"], 1, #speed_types, speed_types[config_table["aim_attack_end"]])
            changed, config_table["wide_sweep"] = imgui.slider_int("Wide Sweep", config_table["wide_sweep"], 1, #speed_types, speed_types[config_table["wide_sweep"]])
            changed, config_table["combo_attacks_end"] = imgui.slider_int("Ground Colab Attacks End", config_table["combo_attacks_end"], 1, #speed_types, speed_types[config_table["combo_attacks_end"]])
            changed, config_table["helicopter_end"] = imgui.slider_int("Air Colab Attacks End (Including Helicopter End)", config_table["helicopter_end"], 1, #speed_types, speed_types[config_table["helicopter_end"]])
            imgui.tree_pop()
        end
        if imgui.tree_node("Not Tripple Up Config") then
            local config_table = config.not_tripple_up
            -- changed, config_table["charged_attack"] = imgui.slider_int("Charged Attack", config_table["charged_attack"], 1, #speed_types, speed_types[config_table["charged_attack"]])
            changed, config_table["helicopter_start"] = imgui.slider_int("Helicopter Start", config_table["helicopter_start"], 1, #speed_types, speed_types[config_table["helicopter_start"]])
            changed, config_table["aim_attack_start"] = imgui.slider_int("Focus Strike Start", config_table["aim_attack_start"], 1, #speed_types, speed_types[config_table["aim_attack_start"]])
            changed, config_table["aim_attack_end"] = imgui.slider_int("Focus Strike End", config_table["aim_attack_end"], 1, #speed_types, speed_types[config_table["aim_attack_end"]])
            changed, config_table["wide_sweep"] = imgui.slider_int("Wide Sweep", config_table["wide_sweep"], 1, #speed_types, speed_types[config_table["wide_sweep"]])
            changed, config_table["combo_attacks_end"] = imgui.slider_int("Ground Colab Attacks End", config_table["combo_attacks_end"], 1, #speed_types, speed_types[config_table["combo_attacks_end"]])
            changed, config_table["helicopter_end"] = imgui.slider_int("Air Colab Attacks End (Including Helicopter End)", config_table["helicopter_end"], 1, #speed_types, speed_types[config_table["helicopter_end"]])
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("Kinsect_dont_come_back.json", config)
    end
)