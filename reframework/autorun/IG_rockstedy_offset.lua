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

local saved_config = json.load_file("IG_rockstedy_offset.json") or {}

local config = {
    ground_offset_start = 0,
    ground_offset = 42,
    air_offset_air_start = 0,
    air_offset_air = 100,
    air_offset_ground_start = 0,
    air_offset_ground = 0,
    helicopter_start = 0,
    helicopter = 0,
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("IG_rockstedy_offset.json", config)
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

-- -- app.cCharacterActionBase.update()
-- sdk.hook(sdk.find_type_definition("app.cCharacterActionBase"):get_method("update"),
-- function(args)
--     local this = sdk.to_managed_object(args[2])
--     local character = this._Character
--     if not character then return end
--     local character_type = character:get_type_definition()
--     if character_type:get_full_name() ~= "app.HunterCharacter" then return end
--     if not (character:get_IsMaster() and character:get_IsUserControl()) then return end
--     log.debug("character: " .. string.format("%X", character:get_address()))
--     in_ground_weak_offset = false
-- end, 
-- function(retval)
--     if not in_ground_weak_offset then
--         ground_weak_offset_timer = 0
--     end
--     return retval
-- end)
-- app.Wp10Action.cHoldAttack.doUpdate
sdk.hook(sdk.find_type_definition("app.Wp10Action.cHoldAttack"):get_method("doUpdate"),
function(args)
    in_ground_weak_offset = true
    ground_weak_offset_timer = ground_weak_offset_timer + 1
    -- log.debug("ground_weak_offset_timer: " .. ground_weak_offset_timer)
end, nil)

-- core
-- app.HunterCharacter.evHit_Damage
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_Damage"),
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    if not (this:get_IsMaster() and this:get_IsUserControl()) then return end

    if ground_offset_timer > config.ground_offset_start and config.ground_offset > ground_offset_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if ground_weak_offset_timer > config.ground_offset_start and config.ground_offset > ground_weak_offset_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if air_offset_air_timer > config.air_offset_air_start and config.air_offset_air > air_offset_air_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if air_offset_ground_timer > config.air_offset_ground_start and config.air_offset_ground > air_offset_ground_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
    if helicopter_timer > config.helicopter_start and config.helicopter > helicopter_timer then return sdk.PreHookResult.SKIP_ORIGINAL end
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

    if imgui.tree_node("Insect Glaive Rockstedy Offset") then
        imgui.text("Set the start and end frames to be rockstedy during each action. Set end frame to 0 to disable.")
        changed, config.ground_offset_start, config.ground_offset = two_rows("Ground Offset", config.ground_offset_start, config.ground_offset, "Start", "End", 0, 300)
        changed, config.air_offset_air_start, config.air_offset_air = two_rows("Air Offset in Air", config.air_offset_air_start, config.air_offset_air, "Start", "End", 0, 100)
        changed, config.air_offset_ground_start, config.air_offset_ground = two_rows("Air Offset on Ground", config.air_offset_ground_start, config.air_offset_ground, "Start", "End", 0, 200)
        changed, config.helicopter_start, config.helicopter = two_rows("Helicopter", config.helicopter_start, config.helicopter, "Start", "End", 0, 200)
        imgui.tree_pop()
    end
end)