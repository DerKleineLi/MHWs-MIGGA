-- config
local function merge_tables(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return
    end
    for k, v in pairs(t2) do
        if t1[k] ~= nil then
            if type(t1[k]) == "table" and type(v) == "table" then
                merge_tables(t1[k], v)
            else
                t1[k] = v
            end
        end
    end
end

local saved_config = json.load_file("IG_better_cancel.json") or {}

local config = {
    dodge = true,
    move = false,
    move_delay = 2,
    jump = true,
    ground_attacks = true,
    air = true,
    air_imba = false,
    easier_stabbing_on_wall = false,
    infinite_air_dodge = false,
    air_motion_after_air_focus_strike = true,
    air_motion_after_air_marking = true,
    air_motion_on_wall = false,
    always_recall_kinsect = true,
    skip_kinsect_catch = true,
    skip_stand_up = false,
    skip_land_up = false,
}

merge_tables(config, saved_config)

config.air_motion_after_air_marking_time = 42 / 60
config.air_motion_after_air_shoot_marking_time = 5 / 60
config.air_motion_after_air_marking_pre_window = 30 / 60
config.air_imba_wall_off_reserved_time = 0.05

re.on_config_save(
    function()
        json.dump_file("IG_better_cancel.json", config)
    end
)

-- global vars
-- delay the All movement cancel
local ground_mult_prev = false -- if all ground cancel avaliable in the last frame
local all_timer = 0 -- frame timer for all ground cancel available

local Wp10Insect = nil -- kinsect object
local hunter = nil -- hunter object
local stand_state = 0 -- 0: on ground, 1: in air, 2: on wall
local in_charged_attack = false -- if in charged attack
local in_wall_off = false -- if in wall jump off or wall slash off
local wall_jump_start = 0 -- frame timer for wall jump off or wall slash off
local in_fall = false -- if in fall

local in_air_marking = false -- if in air marking
local in_air_shoot_marking = false -- if in ground weak offset
local air_marking_start = 0 -- frame timer for air marking
local air_shoot_marking_start = 0 -- frame timer for air shoot marking
local force_all_cancel = false -- whether to force all cancel, used for air imba and air_motion_after_air_marking
local force_all_pre_cancel = false

-- update stand state
-- necessary to canceling wall jump
re.on_frame(
    function()
        if hunter then
            stand_state = hunter:get_StandState()
            if hunter:get_Landed() then
                stand_state = 0
            end
            if in_wall_off then
                stand_state = 1
            end
            -- log.debug("hunter: " .. string.format("%x", hunter:get_address()))
            -- log.debug("Stand State: " .. tostring(hunter:get_StandState()))
            -- log.debug("Landed: " .. tostring(hunter:get_Landed()))
            
        end
    end
)

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
    -- log.debug("insect_on_arm: " .. tostring(insect_on_arm))
    Wp10Insect:set_field("<IsArmConst>k__BackingField", false)
end, function(retval)
    if not config.always_recall_kinsect then return retval end
    if not Wp10Insect then return retval end

    Wp10Insect:set_field("<IsArmConst>k__BackingField", insect_on_arm)
    return retval
end)

-- hook for better cancel
local function preHook(args)
    force_all_cancel = false
    force_all_pre_cancel = false

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

    local ground_pre = _Pre_ATTACK_00_COMBO or _Pre_ATTACK_01_COMBO or _Pre_BATON_MARKING or _Pre_AIM_ATTACK or _Pre_INSECT_ORDER
    local ground = _ATTACK_00_COMBO or _ATTACK_01_COMBO or _BATON_MARKING or _AIM_ATTACK or _INSECT_ORDER
    local air_pre = _Pre_AIR_ATTACK or _Pre_AIR_DODGE or _Pre_CHARGE
    local air = _AIR_ATTACK or _AIR_DODGE or _CHARGE

    if config.dodge then
        Wp10Cancel:set_field("_PreDodge", _PreDodge or ground_pre)
        Wp10Cancel:set_field("_Dodge", _Dodge or ground)
    end
    if config.jump then
        Wp10Cancel:set_field("_Pre_JUMP", _Pre_JUMP or ground_pre)
        Wp10Cancel:set_field("_JUMP", _JUMP or ground)
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
        Wp10Cancel:set_field("_Pre_CHARGE", _Pre_CHARGE or ground_pre)
        Wp10Cancel:set_field("_CHARGE", _CHARGE or ground)
    end

    if stand_state == 1 then
        if config.infinite_air_dodge or config.air then
            Wp10Cancel:set_field("_Pre_AIR_DODGE", air_pre)
            Wp10Cancel:set_field("_AIR_DODGE", air)
        end
        if config.air then
            Wp10Cancel:set_field("_Pre_AIR_ATTACK", air_pre)
            Wp10Cancel:set_field("_AIR_ATTACK", air)
            Wp10Cancel:set_field("_Pre_CHARGE", air_pre)
            Wp10Cancel:set_field("_CHARGE", air)
            Wp10Cancel:set_field("_Pre_BATON_MARKING", air_pre)
            Wp10Cancel:set_field("_BATON_MARKING", air)
        end
        if config.easier_stabbing_on_wall then
            Wp10Cancel:set_field("_StepUp", air)
        end
        if config.air_imba then
            force_all_cancel = true
        end
    end
    
    -- log.debug("force_all_cancel: " .. tostring(force_all_cancel))

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
    end

    if ground_mult and not ground_mult_prev then
        all_timer = config.move_delay
    end
    if all_timer > 0 then
        all_timer = all_timer - 1
    end
    
    ground_mult_prev = ground_mult
end

sdk.hook(sdk.find_type_definition("app.motion_track.Wp10Cancel"):get_method("myFlagsToCancelFlags"), preHook, nil)

-- app.Wp10_Export.table_e524853b_ed29_76d8_0a81_b2ec4486e05b 地面弱点
-- app.Wp10_Export.table_fdc831e9_0152_308f_acd9_64514e5c9253 起跳
-- app.Wp10_Export.table_408e9d28_58f6_e73a_1dd1_1614a6f59514 空中回避
-- app.Wp10_Export.table_036c6092_4a8e_d645_6d04_760f82ba9a36 空中舞踏
-- app.Wp10_Export.table_dca14e16_fa0d_4740_b396_0a7b7bb32b81 always
-- app.Wp10_Export.table_20641528_9e20_1435_0ec8_55a0c62400fc 空中攻击
-- app.Wp10_Export.table_89935cf4_70c4_9247_e539_05c62677527a 蓄力攻击
-- app.Wp10_Export.table_413fc014_8b7d_9aa9_dc32_8ae7c215f284 爬墙
-- app.Wp10_Export.table_23dc9570_d89a_704d_c7e6_6b5aa4cdbab4 在墙上
-- app.Wp10_Export.table_4ab168d7_8d3a_9356_0406_e676f77f9198 升虫

-- global vars
local charged_attack_called = false
local jump_called = false -- jump called or enemy step called or helicopter called
local in_aim_attack = false
local ground_move_called = false
local wall_climb_called = false

-- app.Wp10Action.cAimAttack.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cAimAttack"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_aim_attack = true
    return
end, nil)

-- app.Wp10Action.cAimAttackHit.doUpdate()
-- app.Wp10Action.cAimAttackHitAir.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cAimAttackHitAir"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_aim_attack = true
    return
end, nil)

-- app.Wp10Action.cHoldAttack.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttack"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_charged_attack = true
    return
end, nil)

-- app.Wp10Action.cGunShotAir.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cGunShotAir"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_air_shoot_marking = true
    air_shoot_marking_time = os.clock() - air_shoot_marking_start
    force_all_cancel = config.air_imba or (air_shoot_marking_time > config.air_motion_after_air_shoot_marking_time and config.air_motion_after_air_marking)
    force_all_pre_cancel = (air_shoot_marking_time + config.air_motion_after_air_marking_pre_window) > config.air_motion_after_air_shoot_marking_time and config.air_motion_after_air_marking
end, nil)

-- app.Wp10Action.cGunShotAir.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cGunShotAir"):get_method("doEnter"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    air_shoot_marking_start = os.clock()

end, nil)

-- app.Wp10Action.cBatonMarkingAir.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonMarkingAir"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    local this_type = this:get_type_definition()
    local this_type_name = this_type:get_full_name()
    if this_type_name ~= "app.Wp10Action.cBatonMarkingAir" then return end

    in_air_marking = true
    air_marking_time = os.clock() - air_marking_start
    force_all_cancel = config.air_imba or (air_marking_time > config.air_motion_after_air_marking_time and config.air_motion_after_air_marking)
    force_all_pre_cancel = (air_marking_time + config.air_motion_after_air_marking_pre_window) > config.air_motion_after_air_marking_time and config.air_motion_after_air_marking
end, nil)

-- app.Wp10Action.cBatonMarkingAir.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonMarkingAir"):get_method("doEnter"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    air_marking_start = os.clock()

end, nil)

-- app.Wp10Action.cWallGrabToJump.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cWallGrabToJump"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_wall_off = true

    force_all_cancel = in_wall_off and config.air_imba and os.clock() - wall_jump_start > config.air_imba_wall_off_reserved_time
    
    return
end, nil)

-- app.Wp10Action.cWallGrabToJump.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cWallGrabToJump"):get_method("doEnter"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    wall_jump_start = os.clock()

    return
end, nil)

-- app.Wp10Action.cWallDashToFallSlash.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cWallDashToFallSlash"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_wall_off = true
    force_all_cancel = in_wall_off and config.air_imba
    return
end, nil)

-- app.Wp10Action.cFall.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cFall"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_fall = true
end, nil)


-- hook the root function, call jump function manually
local root_this = nil
local root_args1 = nil
local root_args2 = nil
local root_manual_call_jump = false
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_dca14e16_fa0d_4740_b396_0a7b7bb32b81(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    -- update stand state
    -- necessary to cancel wall slash
    if hunter then
        stand_state = hunter:get_StandState()
        if hunter:get_Landed() then
            stand_state = 0
        end
        if in_wall_off then
            stand_state = 1
        end
        -- log.debug("hunter: " .. string.format("%x", hunter:get_address()))
        -- log.debug("Stand State: " .. tostring(hunter:get_StandState()))
        -- log.debug("Landed: " .. tostring(hunter:get_Landed()))
    end
    -- cache args for manual cancel function call
    root_manual_call_jump = stand_state == 1 and config.air_imba
    root_manual_call_jump = root_manual_call_jump or (stand_state == 1 and (in_air_marking or in_air_shoot_marking) and config.air_motion_after_air_marking)
    root_manual_call_jump = root_manual_call_jump or (stand_state == 1 and in_aim_attack and config.air_motion_after_air_focus_strike)
    if root_manual_call_jump then
        root_this = sdk.to_managed_object(args[2])
        root_args1 = sdk.to_managed_object(args[3])
        root_args2 = sdk.to_managed_object(args[4])
        -- log.debug("root_this: " .. string.format("%x", root_this:get_address()))
        -- log.debug("root_args1: " .. string.format("%x", root_args1:get_address()))
        -- log.debug("root_args2: " .. string.format("%x", root_args2:get_address()))
    end

    if in_fall then
        jump_called = true -- make R2 available in fall by not calling replicated function
    end

end, function(retval)
    root_manual_call_jump = root_manual_call_jump and not wall_climb_called
    if root_manual_call_jump and root_this and root_args1 and root_args2 then
        root_this:table_fdc831e9_0152_308f_acd9_64514e5c9253(root_args1, root_args2)
    end

    in_charged_attack = charged_attack_called
    in_aim_attack = false
    in_wall_off = false
    in_air_marking = false
    in_air_shoot_marking = false
    in_fall = false

    charged_attack_called = false
    jump_called = false
    ground_move_called = false
    wall_climb_called = false

    return retval
end)

-- when these functions are called, set the corresponding flag and do nothing
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_89935cf4_70c4_9247_e539_05c62677527a(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    charged_attack_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_413fc014_8b7d_9aa9_dc32_8ae7c215f284(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    wall_climb_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_fdc831e9_0152_308f_acd9_64514e5c9253(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if jump_called then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    jump_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_4ab168d7_8d3a_9356_0406_e676f77f9198(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if jump_called then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    jump_called = true
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_036c6092_4a8e_d645_6d04_760f82ba9a36(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if jump_called then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    jump_called = true
end, nil)

-- call the jump function manually to allow continous air dodge
local ret4air_dodge = nil
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_408e9d28_58f6_e73a_1dd1_1614a6f59514(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if config.infinite_air_dodge or config.air_imba then
        local this = sdk.to_managed_object(args[2])
        local args1 = sdk.to_managed_object(args[3])
        local args2 = sdk.to_managed_object(args[4])
        ret4air_dodge = this:table_fdc831e9_0152_308f_acd9_64514e5c9253(args1, args2)
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end, function(retval)
    if config.infinite_air_dodge or config.air_imba then
        return sdk.to_ptr(ret4air_dodge)
    end
    return retval
end)

local ret4wall = nil
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_23dc9570_d89a_704d_c7e6_6b5aa4cdbab4(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if not config.air_motion_on_wall then return end
    local this = sdk.to_managed_object(args[2])
    local args1 = sdk.to_managed_object(args[3])
    local args2 = sdk.to_managed_object(args[4])
    if not this or not args1 or not args2 then return end

    ret4wall = this:table_fdc831e9_0152_308f_acd9_64514e5c9253(args1, args2)
    return sdk.PreHookResult.SKIP_ORIGINAL
end, 
function(retval)
    if config.air_motion_on_wall then
        return sdk.to_ptr(ret4wall)
    end
    return retval
end)


-- app.Wp10_Export.table_1b083206_ef21_5712_8dcc_3c7089611271 急袭突刺地面段
-- app.Wp10_Export.table_e524853b_ed29_76d8_0a81_b2ec4486e05b 地面弱点攻击
-- app.Wp10_Export.table_0b363fec_3adf_834f_5deb_724dfe5053ee 地面待机
-- app.Wp10_Export.table_cacd937e_a1aa_29a5_81ff_58ba90f7517e 地面移动
-- app.Wp10_Export.table_1177eec9_781a_39da_8736_a371471f5f56 landing
-- app.Wp10_Export.table_938d81b9_3cf4_3210_450c_8f96146b5f33 move after landing

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

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_cacd937e_a1aa_29a5_81ff_58ba90f7517e(ace.btable.cCommandWork, ace.btable.cOperatorWork)"),
function(args)
    if ground_move_called then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    ground_move_called = true
end, nil)

-- skip entering the kinsect catch animation
local skip_next_landing = false
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)"), 
function(args)
    local player = sdk.to_managed_object(args[2])
    if not player then return end
    if not (player:get_IsMaster() and player:get_IsUserControl()) then return end
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

    if skip_next_landing then
        skip_next_landing = false
        if layer == 0 and category == 2 and index == 36 then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end

    if config.skip_kinsect_catch then
        if layer == 1 and category == 2 and index == 2 then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end

    if config.skip_stand_up then
        if layer == 0 and category == 1 and index == 63 then
            local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
            local instance = ValueType.new(ActionIDType)
            sdk.set_native_field(instance, ActionIDType, "_Category", 1)
            sdk.set_native_field(instance, ActionIDType, "_Index", 15)
            player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, true)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
        if layer == 0 and category == 1 and index == 61 then
            local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
            local instance = ValueType.new(ActionIDType)
            sdk.set_native_field(instance, ActionIDType, "_Category", 1)
            sdk.set_native_field(instance, ActionIDType, "_Index", 14)
            player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, true)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end

    if config.skip_land_up then
        if layer == 0 and category == 2 and index == 37 then
            local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
            local instance = ValueType.new(ActionIDType)
            sdk.set_native_field(instance, ActionIDType, "_Category", 1)
            sdk.set_native_field(instance, ActionIDType, "_Index", 15)
            player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", 0, instance, true)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end

    if force_all_cancel then
        if not (layer == 0 and category == 2 and index == 36) then
            skip_next_landing = true -- prevents landing overwriting the ground part of the actions
        end
    end

end, nil)

-- app.motion_track.HunterCancelBase.isCancel(app.ACTION_CANCEL_INDEX)
local isCancel_is_wp10 = false
sdk.hook(sdk.find_type_definition("app.motion_track.Wp10Cancel"):get_method("isCancel(app.ACTION_CANCEL_INDEX)"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_type = this:get_type_definition()
    isCancel_is_wp10 = this_type:is_a("app.motion_track.Wp10Cancel")
end, function(retval)
    if not isCancel_is_wp10 then return retval end
    if force_all_cancel then
        return sdk.to_ptr(true)
    end
    return retval
end)

-- app.motion_track.HunterCancelBase.isPreCancel(app.ACTION_CANCEL_INDEX)
local isPreCancel_is_wp10 = false
sdk.hook(sdk.find_type_definition("app.motion_track.Wp10Cancel"):get_method("isPreCancel(app.ACTION_CANCEL_INDEX)"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_type = this:get_type_definition()
    isPreCancel_is_wp10 = this_type:is_a("app.motion_track.Wp10Cancel")
end, function(retval)
    if not isPreCancel_is_wp10 then return retval end
    if force_all_pre_cancel then
        return sdk.to_ptr(true)
    end
    return retval
end)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Insect Glaive Better Cancel") then
        changed, config.move = imgui.checkbox("Move", config.move)
        if config.move then
            changed, config.move_delay = imgui.slider_int("Move Delay", config.move_delay, 0, 120)
        end
        changed, config.dodge = imgui.checkbox("Dodge", config.dodge)
        changed, config.jump = imgui.checkbox("Jump", config.jump)
        changed, config.ground_attacks = imgui.checkbox("Ground Attacks", config.ground_attacks)
        changed, config.air = imgui.checkbox("Air", config.air)
        changed, config.air_imba = imgui.checkbox("Air Imba", config.air_imba)
        changed, config.easier_stabbing_on_wall = imgui.checkbox("Easier Stabbing On Wall", config.easier_stabbing_on_wall)
        changed, config.infinite_air_dodge = imgui.checkbox("Infinite Air Dodge", config.infinite_air_dodge)
        changed, config.air_motion_after_air_focus_strike = imgui.checkbox("Air Motion After Air Focus Strike", config.air_motion_after_air_focus_strike)
        changed, config.air_motion_after_air_marking = imgui.checkbox("Air Motion After Air Marking", config.air_motion_after_air_marking)
        changed, config.air_motion_on_wall = imgui.checkbox("Air Motion On Wall", config.air_motion_on_wall)
        changed, config.always_recall_kinsect = imgui.checkbox("Always Recall Kinsect", config.always_recall_kinsect)
        changed, config.skip_kinsect_catch = imgui.checkbox("Skip Kinsect Catch", config.skip_kinsect_catch)
        changed, config.skip_stand_up = imgui.checkbox("Skip Smash Stand Up", config.skip_stand_up)
        changed, config.skip_land_up = imgui.checkbox("Skip Land Stand Up", config.skip_land_up)

        imgui.tree_pop()
    end
end)