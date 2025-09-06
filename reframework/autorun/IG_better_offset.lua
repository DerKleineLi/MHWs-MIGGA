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

local saved_config = json.load_file("IG_better_offset.json") or {}

local config = {
    rockstedy = {
        ground_offset_start = 0,
        ground_offset = 42,
        air_offset_air_start = 0,
        air_offset_air = 100,
        air_offset_ground_start = 0,
        air_offset_ground = 0,
        helicopter_start = 0,
        helicopter = 0,
        ground_marking_start = 0,
        ground_marking = 0,
        air_marking_start = 0,
        air_marking = 0,
    },
    parry = {
        ground_offset_start = 0,
        ground_offset = 42,
        air_offset_air_start = 0,
        air_offset_air = 100,
        air_offset_ground_start = 0,
        air_offset_ground = 0,
        helicopter_start = 0,
        helicopter = 0,
        ground_marking_start = 0,
        ground_marking = 0,
        air_marking_start = 0,
        air_marking = 0,
        parry_damage = 90,
        parry_all_attacks = false,
        invincibility_time = 0.25,
    },
    step = {
        ground_offset_start = 0,
        ground_offset = 42,
        air_offset_air_start = 0,
        air_offset_air = 100,
        air_offset_ground_start = 0,
        air_offset_ground = 0,
        helicopter_start = 0,
        helicopter = 0,
        ground_marking_start = 0,
        ground_marking = 0,
        air_marking_start = 0,
        air_marking = 0,
        step_on_vanilla_ground_parry = false,
        step_on_vanilla_air_parry = false,
        invincibility_time = 0.25,
    },
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("IG_better_offset.json", config)
    end
)

-- helper functions
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

local function change_action(layer, category, index)
    local hunter = get_hunter()
    if not hunter then return end
    local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
    local instance = ValueType.new(ActionIDType)
    sdk.set_native_field(instance, ActionIDType, "_Category", category)
    sdk.set_native_field(instance, ActionIDType, "_Index", index)
    hunter:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", layer, instance, true)
end

local function get_motion_frame() -- credits to lingsamuel
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return 0 end
    local player_object = player_info:get_Object()
    if not player_object then return 0 end
    local motion = player_object:getComponent(sdk.typeof("via.motion.Motion"))
    if not motion then return 0 end
    local layer = motion:getLayer(0)
    if not layer then return 0 end
    local frame = layer:get_Frame()
    return frame
end

local function get_config(motion_name, function_name)
    if motion_name == "ground_weak_offset" then
        motion_name = "ground_offset"
    end
    local start_frame = config[function_name][motion_name .. "_start"]
    local end_frame = config[function_name][motion_name]
    return start_frame, end_frame
end

function contains_token(haystack, needle)
    local needle_lower = needle:lower()
    for token in string.gmatch(haystack, "[^|]+") do
        if token:lower() == needle_lower then
            return true
        end
    end
    return false
end

-- status monitor

-- app.Wp10_Export.table_dca14e16_fa0d_4740_b396_0a7b7bb32b81 normal
-- app.Wp10_Export.table_89935cf4_70c4_9247_e539_05c62677527a ground offset max 290
-- app.Wp10_Export.table_2b0b0efe_aa38_a548_58ff_bb5ebd531b0c air offset max 35
-- app.Wp10_Export.table_1b083206_ef21_5712_8dcc_3c7089611271 air offset ground max 172
-- app.Wp10_Export.table_4ab168d7_8d3a_9356_0406_e676f77f9198 helicopter max 140
-- app.Wp10_Export.table_44b622ee_9a7e_dbb1_7432_b9fccbed6f68 ground marking max 122
-- app.Wp10_Export.table_b7e1b341_c2d7_0fa8_0727_f91450bf1b79 ground marking max 122
local motion_max_frames = {
    ground_offset = 300,
    air_offset_air = 100,
    air_offset_ground = 180,
    helicopter = 150,
    ground_marking = 130,
    air_marking = 130,
}

local helicopter_start = 0

local in_motion = {
    ground_offset = false,
    ground_weak_offset = false,
    air_offset_air = false,
    air_offset_ground = false,
    helicopter = false,
    air_marking = false,
    ground_marking = false,
}

local on_vanilla_parry = false
local on_mod_parry = false

local function in_window(function_name)
    for motion_name, in_motion_value in pairs(in_motion) do
        if in_motion_value then
            local start_frame, end_frame = get_config(motion_name, function_name)
            local frame = nil
            if motion_name == "helicopter" then
                frame = (os.clock() - helicopter_start) * 60
            else
                frame = get_motion_frame()
            end
            return frame > start_frame and frame < end_frame
        end
    end
end

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_dca14e16_fa0d_4740_b396_0a7b7bb32b81"),
function(args)
    for motion_name in pairs(in_motion) do
        in_motion[motion_name] = false
    end
    on_vanilla_parry = false
    on_mod_parry = false
end, nil)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_89935cf4_70c4_9247_e539_05c62677527a"),
function(args)
    in_motion.ground_offset = true
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_2b0b0efe_aa38_a548_58ff_bb5ebd531b0c"),
function(args)
    in_motion.air_offset_air = true
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_1b083206_ef21_5712_8dcc_3c7089611271"),
function(args)
    in_motion.air_offset_ground = true
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_4ab168d7_8d3a_9356_0406_e676f77f9198"),
function(args)
    in_motion.helicopter = true
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_44b622ee_9a7e_dbb1_7432_b9fccbed6f68"),
function(args)
    in_motion.ground_marking = true
end, nil)

-- app.Wp10Action.cHoldAttack.doUpdate
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttack"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_motion.ground_weak_offset = true
end, nil)

-- app.Wp10Action.cBatonMarkingAir.doUpdate()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonMarkingAir"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    in_motion.air_marking = true
end, nil)

-- app.Wp10Action.cBatonUpSlashSuper.doEnter()
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonUpSlashSuper"):get_method("doEnter"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    helicopter_start = os.clock()
end, nil)

-- core
-- rockstedy
-- app.HunterCharacter.evHit_Damage
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_Damage(app.HitInfo)"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    if not (this:get_IsMaster() and this:get_IsUserControl()) then return end

    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end

    local attack_owner = hit_info:get_field("<AttackOwner>k__BackingField")
    if not attack_owner then return end
    local attack_owner_tag = attack_owner:get_Tag()

    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    local attack_value = attack_data:get_field("_Attack")
    local heal_value = attack_data:get_field("_HealValue")

    -- log.debug("AttackOwner: " .. attack_owner_tag .. ", Attack: " .. tostring(attack_value))

    if contains_token(attack_owner_tag, "Enemy") then
        local force_step = false
        if on_vanilla_parry then
            if config.step.step_on_vanilla_ground_parry and in_motion.ground_offset then
                force_step = true
            end
            if config.step.step_on_vanilla_air_parry and in_motion.air_offset_air then
                force_step = true
            end
        end
        force_step = force_step or in_window("step")
        if force_step then
            change_action(0, 2, 53) -- step
            this:startNoHitTimer(config.step.invincibility_time)
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end

    if on_mod_parry then
        this:startNoHitTimer(config.parry.invincibility_time)
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    
    if in_window("rockstedy") and heal_value <= 0 then return sdk.PreHookResult.SKIP_ORIGINAL end
end, nil)

-- parry
-- app.EnemyCharacter.evHit_AttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.EnemyCharacter"):get_method("evHit_AttackPreProcess(app.HitInfo)"),
function(args)
    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end
    local damage_owner = hit_info:get_field("<DamageOwner>k__BackingField")
    local damage_owner_name = damage_owner:get_Name()
    -- log.debug("DamageOwner: " .. damage_owner_name)
    if damage_owner_name ~= "MasterPlayer" then return end

    local attack_owner = hit_info:get_field("<AttackOwner>k__BackingField")
    if not attack_owner then return end
    local attack_owner_tag = attack_owner:get_Tag()
    local is_parry_able = not contains_token(attack_owner_tag, "Shell")

    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    local attack_value = attack_data:get_field("_Attack")
    is_parry_able = is_parry_able and attack_value > 0
    
    if not is_parry_able and not config.parry.parry_all_attacks then return end

    -- local damage_data = hit_info:get_field("<DamageAttackData>k__BackingField")
    -- local parry_dmg = damage_data:get_field("_ParryDamage")
    -- log.debug("parry_dmg: " .. tostring(parry_dmg))

    local collision_layer = hit_info:get_field("<CollisionLayer>k__BackingField")
    on_vanilla_parry = collision_layer == 18

    if in_window("parry") then
        hit_info:set_field("<CollisionLayer>k__BackingField", 18) -- PARRY
        local attack_param_pl = sdk.create_instance("app.cAttackParamPl", true)
        hit_info:set_DamageAttackData(attack_param_pl)
        hit_info:get_field("<DamageAttackData>k__BackingField"):set_field("_HitEffectType", 18)
        hit_info:get_field("<DamageAttackData>k__BackingField"):set_field("_ParryDamage", config.parry.parry_damage)
        hit_info:get_field("<DamageAttackData>k__BackingField"):set_field("_HitEffectOverwriteConnectID", -1)
        on_mod_parry = true
    end

end, nil)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    local two_rows = function(name, var1, var2, name1, name2, min, max)
        imgui.text(name)
        imgui.begin_table(name, 2)
        imgui.table_next_row()
        imgui.table_next_column()
        changed, var1 = imgui.drag_int(name1, var1, 1, min, max)
        imgui.table_next_column()
        changed, var2 = imgui.drag_int(name2, var2, 1, min, max)
        imgui.end_table()
        return changed, var1, var2
    end

    if imgui.tree_node("Insect Glaive Better Offset") then
        if imgui.tree_node("Rockstedy") then
            imgui.text("Set the start and end frames to be rockstedy during each action. Set end frame to 0 to disable.")
            changed, config.rockstedy.ground_offset_start, config.rockstedy.ground_offset = two_rows("Ground Offset", config.rockstedy.ground_offset_start, config.rockstedy.ground_offset, "Start", "End", 0, motion_max_frames.ground_offset)
            changed, config.rockstedy.air_offset_air_start, config.rockstedy.air_offset_air = two_rows("Air Offset in Air", config.rockstedy.air_offset_air_start, config.rockstedy.air_offset_air, "Start", "End", 0, motion_max_frames.air_offset_air)
            changed, config.rockstedy.air_offset_ground_start, config.rockstedy.air_offset_ground = two_rows("Air Offset on Ground", config.rockstedy.air_offset_ground_start, config.rockstedy.air_offset_ground, "Start", "End", 0, motion_max_frames.air_offset_ground)
            changed, config.rockstedy.helicopter_start, config.rockstedy.helicopter = two_rows("Helicopter", config.rockstedy.helicopter_start, config.rockstedy.helicopter, "Start", "End", 0, motion_max_frames.helicopter)
            changed, config.rockstedy.ground_marking_start, config.rockstedy.ground_marking = two_rows("Ground Marking", config.rockstedy.ground_marking_start, config.rockstedy.ground_marking, "Start", "End", 0, motion_max_frames.ground_marking)
            changed, config.rockstedy.air_marking_start, config.rockstedy.air_marking = two_rows("Air Marking", config.rockstedy.air_marking_start, config.rockstedy.air_marking, "Start", "End", 0, motion_max_frames.air_marking)
            imgui.tree_pop()
        end
        if imgui.tree_node("Parry") then
            imgui.text("Parry value is default to 90, which equals the game's value for fully charged attack.")
            changed, config.parry.parry_damage = imgui.drag_int("Parry Damage", config.parry.parry_damage, 1, 0, 200)
            imgui.text("Enabling Parry All Attacks will make all attacks (including projectiles and non-body-attacks) parryable.")
            changed, config.parry.parry_all_attacks = imgui.checkbox("Parry All Attacks", config.parry.parry_all_attacks)
            imgui.text("Set the start and end frames to parry during each action. Set end frame to 0 to disable.")
            changed, config.parry.ground_offset_start, config.parry.ground_offset = two_rows("Ground Offset", config.parry.ground_offset_start, config.parry.ground_offset, "Start", "End", 0, motion_max_frames.ground_offset)
            changed, config.parry.air_offset_air_start, config.parry.air_offset_air = two_rows("Air Offset in Air", config.parry.air_offset_air_start, config.parry.air_offset_air, "Start", "End", 0, motion_max_frames.air_offset_air)
            changed, config.parry.air_offset_ground_start, config.parry.air_offset_ground = two_rows("Air Offset on Ground", config.parry.air_offset_ground_start, config.parry.air_offset_ground, "Start", "End", 0, motion_max_frames.air_offset_ground)
            changed, config.parry.helicopter_start, config.parry.helicopter = two_rows("Helicopter", config.parry.helicopter_start, config.parry.helicopter, "Start", "End", 0, motion_max_frames.helicopter)
            changed, config.parry.ground_marking_start, config.parry.ground_marking = two_rows("Ground Marking", config.parry.ground_marking_start, config.parry.ground_marking, "Start", "End", 0, motion_max_frames.ground_marking)
            changed, config.parry.air_marking_start, config.parry.air_marking = two_rows("Air Marking", config.parry.air_marking_start, config.parry.air_marking, "Start", "End", 0, motion_max_frames.air_marking)
            changed, config.parry.invincibility_time = imgui.drag_float("Invincibility Time", config.parry.invincibility_time, 0.01, 0, 5, "%.2f")
            imgui.tree_pop()
        end
        if imgui.tree_node("Enemy Step") then
            imgui.text("Whether to perform enemy step on vanilla parry.")
            changed, config.step.step_on_vanilla_ground_parry = imgui.checkbox("Enemy Step on Vanilla Ground Parry", config.step.step_on_vanilla_ground_parry)
            changed, config.step.step_on_vanilla_air_parry = imgui.checkbox("Enemy Step on Vanilla Air Parry", config.step.step_on_vanilla_air_parry)
            imgui.text("Set the start and end frames to perform enemy step during each action when hit. Set end frame to 0 to disable.")
            changed, config.step.ground_offset_start, config.step.ground_offset = two_rows("Ground Offset", config.step.ground_offset_start, config.step.ground_offset, "Start", "End", 0, motion_max_frames.ground_offset)
            changed, config.step.air_offset_air_start, config.step.air_offset_air = two_rows("Air Offset in Air", config.step.air_offset_air_start, config.step.air_offset_air, "Start", "End", 0, motion_max_frames.air_offset_air)
            changed, config.step.air_offset_ground_start, config.step.air_offset_ground = two_rows("Air Offset on Ground", config.step.air_offset_ground_start, config.step.air_offset_ground, "Start", "End", 0, motion_max_frames.air_offset_ground)
            changed, config.step.helicopter_start, config.step.helicopter = two_rows("Helicopter", config.step.helicopter_start, config.step.helicopter, "Start", "End", 0, motion_max_frames.helicopter)
            changed, config.step.ground_marking_start, config.step.ground_marking = two_rows("Ground Marking", config.step.ground_marking_start, config.step.ground_marking, "Start", "End", 0, motion_max_frames.ground_marking)
            changed, config.step.air_marking_start, config.step.air_marking = two_rows("Air Marking", config.step.air_marking_start, config.step.air_marking, "Start", "End", 0, motion_max_frames.air_marking)
            changed, config.step.invincibility_time = imgui.drag_float("Invincibility Time", config.step.invincibility_time, 0.01, 0, 5, "%.2f")
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
end)