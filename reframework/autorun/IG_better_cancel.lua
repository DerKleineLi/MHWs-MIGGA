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

local saved_config = json.load_file("IG_better_cancel.json") or {}

local config = {
    all = false,
    dodge = true,
    move = false,
    move_delay = 2,
    jump = true,
    ground_attacks = true,
    air = true,
    air_imba = false,
    infinite_air_dodge = false,
    air_motion_after_aim_attack = true,
    always_recall_kinsect = true,
    skip_kinsect_catch = true,
    skip_stand_up = false
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("IG_better_cancel.json", config)
    end
)

-- global vars
-- delay the All movement cancel
local ground_mult_prev = false
local all_timer = 0

local Wp10Insect = nil
local hunter = nil
local landed = true
local free_in_air = false -- if it's possible to cancel with air attack
local in_charged_attack = false
local in_catch_kinsect = false

-- hook to get global variables
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("doUpdateBegin"), 
function(args)
    local this_hunter = sdk.to_managed_object(args[2])
    if not this_hunter then return end
    if not this_hunter:get_type_definition():is_a("app.HunterCharacter") then return end
    if this_hunter:get_IsMaster() and this_hunter:get_IsUserControl() then
        hunter = this_hunter
        -- log.debug("Hunter: " .. string.format("%x", hunter:get_address()))
        Wp10Insect = hunter:get_Wp10Insect()
        -- log.debug("Wp10Insect: " .. string.format("%x", Wp10Insect:get_address()))
    end
end, nil)

local insect_on_arm = nil
sdk.hook(sdk.find_type_definition("app.btable.PlCommand.cWp10CheckInsectIdle"):get_method("executeNormal(app.cPlayerBTableCommandWork)"), 
function(args)
    if not config.always_recall_kinsect then return end
    if not Wp10Insect then return end

    insect_on_arm = Wp10Insect:get_field("<IsArmConst>k__BackingField")
    Wp10Insect:set_field("<IsArmConst>k__BackingField", false)
end, function(retval)
    if not config.always_recall_kinsect then return retval end
    if not Wp10Insect then return retval end

    Wp10Insect:set_field("<IsArmConst>k__BackingField", insect_on_arm)
    return retval
end)

-- hook for better cancel
local function preHook(args)
    local Wp10Cancel = sdk.to_managed_object(args[2])
    if not Wp10Cancel then return end

    local _Pre_ATTACK_00_COMBO = Wp10Cancel:get_field("_Pre_ATTACK_00_COMBO")
    local _ATTACK_00_COMBO = Wp10Cancel:get_field("_ATTACK_00_COMBO")
    local _Pre_ATTACK_01_COMBO = Wp10Cancel:get_field("_Pre_ATTACK_01_COMBO")
    local _ATTACK_01_COMBO = Wp10Cancel:get_field("_ATTACK_01_COMBO")
    local _Pre_BATON_MARKING = Wp10Cancel:get_field("_Pre_BATON_MARKING")
    local _BATON_MARKING = Wp10Cancel:get_field("_BATON_MARKING")
    local _Pre_JUMP = Wp10Cancel:get_field("_Pre_JUMP")
    local _JUMP = Wp10Cancel:get_field("_JUMP")
    local _Pre_AIR_DODGE = Wp10Cancel:get_field("_Pre_AIR_DODGE")
    local _AIR_DODGE = Wp10Cancel:get_field("_AIR_DODGE")
    local _Pre_AIR_ATTACK = Wp10Cancel:get_field("_Pre_AIR_ATTACK")
    local _AIR_ATTACK = Wp10Cancel:get_field("_AIR_ATTACK")
    local _PreDodge = Wp10Cancel:get_field("_PreDodge")
    local _Dodge = Wp10Cancel:get_field("_Dodge")
    local _Pre_AIM_ATTACK = Wp10Cancel:get_field("_Pre_AIM_ATTACK")
    local _AIM_ATTACK = Wp10Cancel:get_field("_AIM_ATTACK")
    local _All = Wp10Cancel:get_field("_All")
    local _Move = Wp10Cancel:get_field("_Move")
    local _Pre_INSECT_ORDER = Wp10Cancel:get_field("_Pre_INSECT_ORDER")
    local _INSECT_ORDER = Wp10Cancel:get_field("_INSECT_ORDER")
    local _Pre_CHARGE = Wp10Cancel:get_field("_Pre_CHARGE")
    local _CHARGE = Wp10Cancel:get_field("_CHARGE")

    local ground_pre = _PreDodge or _Pre_ATTACK_00_COMBO or _Pre_ATTACK_01_COMBO or _Pre_BATON_MARKING or _Pre_JUMP or _Pre_AIM_ATTACK or _Pre_INSECT_ORDER
    local ground = _Dodge or _ATTACK_00_COMBO or _ATTACK_01_COMBO or _BATON_MARKING or _JUMP or _AIM_ATTACK or _INSECT_ORDER
    local air_pre = _Pre_AIR_ATTACK or _Pre_AIR_DODGE or _Pre_CHARGE
    local air = _AIR_ATTACK or _AIR_DODGE or _CHARGE

    if config.dodge then
        Wp10Cancel:set_field("_PreDodge", ground_pre)
        Wp10Cancel:set_field("_Dodge", ground)
    end
    if config.jump then
        Wp10Cancel:set_field("_Pre_JUMP", ground_pre)
        Wp10Cancel:set_field("_JUMP", ground)
    end
    if config.ground_attacks then
        Wp10Cancel:set_field("_Pre_ATTACK_00_COMBO", ground_pre)
        Wp10Cancel:set_field("_ATTACK_00_COMBO", ground)
        Wp10Cancel:set_field("_Pre_ATTACK_01_COMBO", ground_pre)
        Wp10Cancel:set_field("_ATTACK_01_COMBO", ground)
        Wp10Cancel:set_field("_Pre_BATON_MARKING", ground_pre)
        Wp10Cancel:set_field("_BATON_MARKING", ground)
        Wp10Cancel:set_field("_Pre_AIM_ATTACK", ground_pre)
        Wp10Cancel:set_field("_AIM_ATTACK", ground)
        Wp10Cancel:set_field("_Pre_INSECT_ORDER", ground_pre)
        Wp10Cancel:set_field("_INSECT_ORDER", ground)
        Wp10Cancel:set_field("_Pre_CHARGE", ground_pre)
        Wp10Cancel:set_field("_CHARGE", ground)
    end

    if hunter then
        landed = hunter:get_Landed()
    end
    if not landed and config.air then
        Wp10Cancel:set_field("_Pre_AIR_ATTACK", air_pre)
        Wp10Cancel:set_field("_AIR_ATTACK", air)
        Wp10Cancel:set_field("_Pre_AIR_DODGE", air_pre)
        Wp10Cancel:set_field("_AIR_DODGE", air)
        Wp10Cancel:set_field("_Pre_CHARGE", air_pre)
        Wp10Cancel:set_field("_CHARGE", air)
        if config.air_imba then
            Wp10Cancel:set_field("_AIR_ATTACK", true)
            Wp10Cancel:set_field("_AIR_DODGE", true)
            Wp10Cancel:set_field("_CHARGE", true)
        end
    end

    -- get new value of _All
    local new_ATTACK_00_COMBO = Wp10Cancel:get_field("_ATTACK_00_COMBO")
    local new_ATTACK_01_COMBO = Wp10Cancel:get_field("_ATTACK_01_COMBO")
    local ground_mult = new_ATTACK_00_COMBO and new_ATTACK_01_COMBO
    if not config.dodge then
        ground_mult = ground_mult and Wp10Cancel:get_field("_Dodge")
    end
    if not config.jump then
        ground_mult = ground_mult and Wp10Cancel:get_field("_JUMP")
    end
    if not config.ground_attacks then
        ground_mult = ground_mult and Wp10Cancel:get_field("_AIM_ATTACK")
    end
    if (not in_charged_attack or _Pre_ATTACK_00_COMBO) then
        if config.move then
            Wp10Cancel:set_field("_Move", _Move or (ground_mult and ground_mult_prev and all_timer == 0))
        end
        if config.all then
            Wp10Cancel:set_field("_All", _All or (ground_mult and ground_mult_prev and all_timer == 0))
        end
    end

    if ground_mult and not ground_mult_prev then
        all_timer = config.move_delay
    end
    if all_timer > 0 then
        all_timer = all_timer - 1
    end
    
    ground_mult_prev = ground_mult
    free_in_air = Wp10Cancel:get_field("_AIR_ATTACK")
end

sdk.hook(sdk.find_type_definition("app.motion_track.Wp10Cancel"):get_method("myFlagsToCancelFlags"), preHook, nil)

-- app.Wp10_Export.table_e524853b_ed29_76d8_0a81_b2ec4486e05b 地面弱点
-- app.Wp10_Export.table_fdc831e9_0152_308f_acd9_64514e5c9253 空中自由
-- app.Wp10_Export.table_408e9d28_58f6_e73a_1dd1_1614a6f59514 空中回避
-- app.Wp10_Export.table_036c6092_4a8e_d645_6d04_760f82ba9a36 空中舞踏
-- app.Wp10_Export.table_dca14e16_fa0d_4740_b396_0a7b7bb32b81 always
-- app.Wp10_Export.table_20641528_9e20_1435_0ec8_55a0c62400fc 空中攻击
-- app.Wp10_Export.table_89935cf4_70c4_9247_e539_05c62677527a 蓄力攻击

-- global vars
local this = nil
local args1 = nil
local args2 = nil
local jump_called = false
local step_called = false
local dodge_called = false
local attack_called = false
local charged_attack_called = false
local jump_ret = nil

-- hook the root function, call jump function manually
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_dca14e16_fa0d_4740_b396_0a7b7bb32b81(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if hunter then
        landed = hunter:get_Landed()
    end
    if not landed then
        this = sdk.to_managed_object(args[2])
        args1 = sdk.to_managed_object(args[3])
        args2 = sdk.to_managed_object(args[4])
    end
end, function(retval)
    if config.air_imba then
        attack_called = false
    end
    local manual_call = not jump_called and not step_called and not dodge_called and not attack_called and not landed and config.air_motion_after_aim_attack
    if manual_call then
        jump_ret = this:table_fdc831e9_0152_308f_acd9_64514e5c9253(args1, args2)
    end

    in_charged_attack = charged_attack_called

    jump_called = false
    step_called = false
    dodge_called = false
    attack_called = false
    charged_attack_called = false
    if manual_call then
        return sdk.to_ptr(jump_ret)
    end

    return retval
end)

-- when these functions are called, set the corresponding flag and do nothing
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_fdc831e9_0152_308f_acd9_64514e5c9253(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    jump_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_036c6092_4a8e_d645_6d04_760f82ba9a36(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    step_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_20641528_9e20_1435_0ec8_55a0c62400fc(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    attack_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_89935cf4_70c4_9247_e539_05c62677527a(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    charged_attack_called = true
end, nil)

-- call the jump function manually to allow continous air dodge
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_408e9d28_58f6_e73a_1dd1_1614a6f59514(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    dodge_called = true
    if config.infinite_air_dodge then
        local this = sdk.to_managed_object(args[2])
        local args1 = sdk.to_managed_object(args[3])
        local args2 = sdk.to_managed_object(args[4])
        jump_ret = this:table_fdc831e9_0152_308f_acd9_64514e5c9253(args1, args2)
        -- return sdk.PreHookResult.SKIP_ORIGINAL
    end
end, 
function(retval)
    -- if config.infinite_air_dodge then
    --     return sdk.to_ptr(jump_ret)
    -- end
    return retval
end)


-- app.Wp10_Export.table_1b083206_ef21_5712_8dcc_3c7089611271 急袭突刺地面段
-- app.Wp10_Export.table_e524853b_ed29_76d8_0a81_b2ec4486e05b 地面弱点攻击
-- app.Wp10_Export.table_0b363fec_3adf_834f_5deb_724dfe5053ee 地面待机
-- app.Wp10_Export.table_cacd937e_a1aa_29a5_81ff_58ba90f7517e 地面移动
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_1b083206_ef21_5712_8dcc_3c7089611271(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if not config.ground_attacks then return end
    local this = sdk.to_managed_object(args[2])
    local args1 = sdk.to_managed_object(args[3])
    local args2 = sdk.to_managed_object(args[4])

    this:table_cacd937e_a1aa_29a5_81ff_58ba90f7517e(args1, args2)
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_e524853b_ed29_76d8_0a81_b2ec4486e05b(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if not config.ground_attacks then return end
    local this = sdk.to_managed_object(args[2])
    local args1 = sdk.to_managed_object(args[3])
    local args2 = sdk.to_managed_object(args[4])

    this:table_cacd937e_a1aa_29a5_81ff_58ba90f7517e(args1, args2)
end, nil)

-- skip entering the kinsect catch animation
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"), 
function(args)
    local player = sdk.to_managed_object(args[2])
    if not player then return end
    if not player:get_IsMaster() then return end
    local weapon_type = player:get_WeaponType()
    if weapon_type ~= 10 then return end

    local layer = sdk.to_int64(args[3])
    local action_id_type = sdk.find_type_definition("ace.ACTION_ID")
    local action_id = args[4]
    local category = sdk.get_native_field(action_id, action_id_type, "_Category")
    local index = sdk.get_native_field(action_id, action_id_type, "_Index")
    -- log.debug("changeActionRequest called with:")
    -- log.debug("Layer: " .. tostring(layer))
    -- log.debug("Action ID: " .. tostring(category) .. ":" .. tostring(index)) 
    if config.skip_kinsect_catch then
        if category == 2 and index == 2 then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
    if config.skip_stand_up then
        if category == 1 and index == 63 then
            local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
            local instance = ValueType.new(ActionIDType)
            sdk.set_native_field(instance, ActionIDType, "_Category", 1)
            sdk.set_native_field(instance, ActionIDType, "_Index", 15)
            player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, true)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
        if category == 1 and index == 61 then
            local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
            local instance = ValueType.new(ActionIDType)
            sdk.set_native_field(instance, ActionIDType, "_Category", 1)
            sdk.set_native_field(instance, ActionIDType, "_Index", 14)
            player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, true)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end
end, nil)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Insect Glaive Better Cancel") then
        -- changed, config.all = imgui.checkbox("All", config.all)
        changed, config.move = imgui.checkbox("Move", config.move)
        if config.move or config.all then
            changed, config.move_delay = imgui.slider_int("Move Delay", config.move_delay, 0, 120)
        end
        changed, config.dodge = imgui.checkbox("Dodge", config.dodge)
        changed, config.jump = imgui.checkbox("Jump", config.jump)
        changed, config.ground_attacks = imgui.checkbox("Ground Attacks", config.ground_attacks)
        changed, config.air = imgui.checkbox("Air", config.air)
        if config.air then
            changed, config.air_imba = imgui.checkbox("Air Imba", config.air_imba)
        end
        changed, config.infinite_air_dodge = imgui.checkbox("Infinite Air Dodge", config.infinite_air_dodge)
        changed, config.air_motion_after_aim_attack = imgui.checkbox("Air Motion After Aim Attack", config.air_motion_after_aim_attack)
        changed, config.always_recall_kinsect = imgui.checkbox("Always Recall Kinsect", config.always_recall_kinsect)
        changed, config.skip_kinsect_catch = imgui.checkbox("Skip Kinsect Catch", config.skip_kinsect_catch)
        changed, config.skip_stand_up = imgui.checkbox("Skip Stand Up", config.skip_stand_up)

        imgui.tree_pop()
    end
end)