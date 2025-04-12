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
        parry_damage = 90,
    },
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("IG_better_offset.json", config)
    end
)

-- status monitor

-- app.Wp10_Export.table_dca14e16_fa0d_4740_b396_0a7b7bb32b81 normal
-- app.Wp10_Export.table_89935cf4_70c4_9247_e539_05c62677527a ground offset max 260
-- app.Wp10_Export.table_2b0b0efe_aa38_a548_58ff_bb5ebd531b0c air offset max 35
-- app.Wp10_Export.table_1b083206_ef21_5712_8dcc_3c7089611271 air offset ground max 140
-- app.Wp10_Export.table_4ab168d7_8d3a_9356_0406_e676f77f9198 helicopter max 140

local in_ground_offset = false
local in_ground_weak_offset = false
local in_air_offset_air = false
local in_air_offset_ground = false
local in_helicopter = false

local ground_offset_timer = 0
local ground_weak_offset_timer = 0
local air_offset_air_timer = 0
local air_offset_ground_timer = 0
local helicopter_timer = 0

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_dca14e16_fa0d_4740_b396_0a7b7bb32b81"),
function(args)
    in_ground_offset = false
    in_air_offset_air = false
    in_air_offset_ground = false
    in_helicopter = false
    if not in_ground_weak_offset then
        ground_weak_offset_timer = 0
    end
end,
function(retval)
    if not in_ground_offset then
        ground_offset_timer = 0
    end
    if not in_air_offset_air then
        air_offset_air_timer = 0
    end
    if not in_air_offset_ground then
        air_offset_ground_timer = 0
    end
    if not in_helicopter then
        helicopter_timer = 0
    end
    in_ground_weak_offset = false
    return retval
end)

sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_89935cf4_70c4_9247_e539_05c62677527a"),
function(args)
    in_ground_offset = true
    ground_offset_timer = ground_offset_timer + 1
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_2b0b0efe_aa38_a548_58ff_bb5ebd531b0c"),
function(args)
    in_air_offset_air = true
    air_offset_air_timer = air_offset_air_timer + 1
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_1b083206_ef21_5712_8dcc_3c7089611271"),
function(args)
    in_air_offset_ground = true
    air_offset_ground_timer = air_offset_ground_timer + 1
end, nil)
sdk.hook(sdk.find_type_definition("app.Wp10_Export"):get_method("table_4ab168d7_8d3a_9356_0406_e676f77f9198"),
function(args)
    in_helicopter = true
    helicopter_timer = helicopter_timer + 1
end, nil)

-- app.Wp10Action.cHoldAttack.doUpdate
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttack"):get_method("doUpdate"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    
    in_ground_weak_offset = true
    ground_weak_offset_timer = ground_weak_offset_timer + 1
end, nil)

-- cache a app.cAttackParamPl instance when hunter perform attack
local player_attack_param = nil
-- app.HunterCharacter.evHit_AttackPostProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_AttackPostProcess(app.HitInfo)"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    if not (this:get_IsMaster() and this:get_IsUserControl()) then return end

    local hit_info = sdk.to_managed_object(args[3])
    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    if not attack_data then return end

    if player_attack_param then
        player_attack_param:force_release()
    end

    attack_data:add_ref_permanent()
    player_attack_param = attack_data
    -- log.debug("HunterAttackData: " .. string.format("%X", player_attack_param:get_address()))
end, nil)

-- core
-- rockstedy
-- app.HunterCharacter.evHit_Damage
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_Damage"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    if not (this:get_IsMaster() and this:get_IsUserControl()) then return end

    if ground_offset_timer > config.rockstedy.ground_offset_start and config.rockstedy.ground_offset > ground_offset_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if ground_weak_offset_timer > config.rockstedy.ground_offset_start and config.rockstedy.ground_offset > ground_weak_offset_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if air_offset_air_timer > config.rockstedy.air_offset_air_start and config.rockstedy.air_offset_air > air_offset_air_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if air_offset_ground_timer > config.rockstedy.air_offset_ground_start and config.rockstedy.air_offset_ground > air_offset_ground_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if helicopter_timer > config.rockstedy.helicopter_start and config.rockstedy.helicopter > helicopter_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
end, nil)

-- parry
-- app.EnemyCharacter.evHit_AttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.EnemyCharacter"):get_method("evHit_AttackPreProcess(app.HitInfo)"),
function(args)
    local hit_info = sdk.to_managed_object(args[3])
    local damage_owner = hit_info:get_field("<DamageOwner>k__BackingField")
    local damage_owner_name = damage_owner:get_Name()
    -- log.debug("DamageOwner: " .. damage_owner_name)
    if damage_owner_name ~= "MasterPlayer" then return end

    -- local damage_data = hit_info:get_field("<DamageAttackData>k__BackingField")
    -- local parry_dmg = damage_data:get_field("_ParryDamage")
    -- log.debug("parry_dmg: " .. tostring(parry_dmg))

    local parry = false

    parry = parry or (ground_offset_timer > config.parry.ground_offset_start and config.parry.ground_offset > ground_offset_timer) 
    parry = parry or (ground_weak_offset_timer > config.parry.ground_offset_start and config.parry.ground_offset > ground_weak_offset_timer) 
    parry = parry or (air_offset_air_timer > config.parry.air_offset_air_start and config.parry.air_offset_air > air_offset_air_timer) 
    parry = parry or (air_offset_ground_timer > config.parry.air_offset_ground_start and config.parry.air_offset_ground > air_offset_ground_timer) 
    parry = parry or (helicopter_timer > config.parry.helicopter_start and config.parry.helicopter > helicopter_timer)

    if not parry then return end
    
    hit_info:set_field("<CollisionLayer>k__BackingField", 18) -- PARRY
    player_attack_param:set_field("_HitEffectType", 18) -- PARRY
    player_attack_param:set_field("_ParryDamage", config.parry.parry_damage)
    hit_info:set_field("<DamageAttackData>k__BackingField", player_attack_param)

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
            changed, config.rockstedy.ground_offset_start, config.rockstedy.ground_offset = two_rows("Ground Offset", config.rockstedy.ground_offset_start, config.rockstedy.ground_offset, "Start", "End", 0, 300)
            changed, config.rockstedy.air_offset_air_start, config.rockstedy.air_offset_air = two_rows("Air Offset in Air", config.rockstedy.air_offset_air_start, config.rockstedy.air_offset_air, "Start", "End", 0, 100)
            changed, config.rockstedy.air_offset_ground_start, config.rockstedy.air_offset_ground = two_rows("Air Offset on Ground", config.rockstedy.air_offset_ground_start, config.rockstedy.air_offset_ground, "Start", "End", 0, 200)
            changed, config.rockstedy.helicopter_start, config.rockstedy.helicopter = two_rows("Helicopter", config.rockstedy.helicopter_start, config.rockstedy.helicopter, "Start", "End", 0, 200)
            imgui.tree_pop()
        end
        if imgui.tree_node("Parry") then
            imgui.text("Set the start and end frames to parry during each action. Set end frame to 0 to disable. Parry value is default to 90, which equals the game's value for fully charged attack.")
            changed, config.parry.ground_offset_start, config.parry.ground_offset = two_rows("Ground Offset", config.parry.ground_offset_start, config.parry.ground_offset, "Start", "End", 0, 300)
            changed, config.parry.air_offset_air_start, config.parry.air_offset_air = two_rows("Air Offset in Air", config.parry.air_offset_air_start, config.parry.air_offset_air, "Start", "End", 0, 100)
            changed, config.parry.air_offset_ground_start, config.parry.air_offset_ground = two_rows("Air Offset on Ground", config.parry.air_offset_ground_start, config.parry.air_offset_ground, "Start", "End", 0, 200)
            changed, config.parry.helicopter_start, config.parry.helicopter = two_rows("Helicopter", config.parry.helicopter_start, config.parry.helicopter, "Start", "End", 0, 200)
            changed, config.parry.parry_damage = imgui.drag_int("Parry Damage", config.parry.parry_damage, 1, 0, 200)
            imgui.tree_pop()
        end
        imgui.tree_pop()
    end
end)