-- config
local config_file = "EverParry.json"
local preset_dir = "EverParryPresets\\\\"

local function merge_tables(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then return end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k] or false) == "table" then
            merge_tables(t1[k], v)
        else
            t1[k] = v
        end
    end
end

local saved_config = json.load_file(config_file) or {}

local config = {
    enabled = true,
    global_motion_config = {
        enabled = false,
        start_frame = 0,
        end_frame = 0,
        invisible_time = 0.0,
    },
    motion_configs = {}
}

merge_tables(config, saved_config)

local function get_empty_preset_config()
    return {
        enabled = true,
        motion_configs = {},
        deleted = false,
    }
end
local preset_configs = {
    default = get_empty_preset_config()
}

local function get_stem(path)
    return path:match("([^/\\]+)%.%w+$")
end

function spairs(t, comp)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end

    -- sort the keys using optional comparator
    if comp then
        table.sort(keys, function(a, b) return comp(t, a, b) end)
    else
        table.sort(keys)
    end

    -- iterator function
    local i = 0
    return function()
        i = i + 1
        local key = keys[i]
        if key ~= nil then
            return key, t[key]
        end
    end
end

local function load_preset_configs()
    local preset_files = fs.glob(preset_dir .. ".*\\.json$")
    for _, file in ipairs(preset_files) do
        local preset_name = get_stem(file)
        local preset_config = json.load_file(file)
        preset_configs[preset_name] = preset_configs[preset_name] or get_empty_preset_config()
        merge_tables(preset_configs[preset_name], preset_config)
        if preset_configs[preset_name].deleted then
            preset_configs[preset_name] = nil
        end
    end
end
load_preset_configs()

local function get_empty_segment_config()
    return {
        enabled = false,
        start_frame = 0,
        end_frame = 1000,
        invisible_time = 0.0,
    }
end
_EVERPARRY_GLOBAL_SEGMENT_CONFIG = get_empty_segment_config()

local function get_motion_config(key)
    local segment_config = get_empty_segment_config()
    merge_tables(segment_config, _EVERPARRY_GLOBAL_SEGMENT_CONFIG)
    local motion_config = {segments = {segment_config}}
    if segment_config.enabled then
        return motion_config
    end

    motion_config = {segments = {config.global_motion_config}}
    if config.global_motion_config.enabled then
        return motion_config
    end
    for _, preset in pairs(preset_configs) do
        if not preset.enabled then goto continue end
        if preset.motion_configs[key] then
            motion_config = preset.motion_configs[key]
            break
        end
        ::continue::
    end
    return motion_config
end

re.on_config_save(
    function()
        json.dump_file(config_file, config)
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

local function get_effect()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return 0 end
    local player_object = player_info:get_Object()
    return player_object:getComponent(sdk.typeof("via.effect.script.ObjectEffectManager2"))
end

local function get_prefab(wp_type)
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local catalog = player_manager:get_Catalog()
    if not catalog then return nil end
    local wp_assets = catalog:getWeaponEquipUseAssets(wp_type)
    if not wp_assets then return nil end
    return wp_assets:get_EpvRef()
end

local function get_wp_type()
    local hunter = get_hunter()
    if not hunter then return nil end
    return hunter:get_WeaponType()
end

local function get_motion(layer_id) -- credits to lingsamuel
    layer_id = layer_id or 0
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return 0 end
    local player_object = player_info:get_Object()
    if not player_object then return 0 end
    local motion = player_object:getComponent(sdk.typeof("via.motion.Motion"))
    if not motion then return 0 end
    local layer = motion:getLayer(layer_id)
    if not layer then return 0 end

    local nodeCount = layer:getMotionNodeCount()
    local result = {
        Layer = layer,
        LayerID = layer_id,
        MotionID = layer:get_MotionID(),
        MotionBankID = layer:get_MotionBankID(),
        Frame = layer:get_Frame(),
    }

    return result
end

local function get_sub_motion()
    return get_motion(3)
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

-- core
local effect_wp_type = 10 -- use IG's effect to override, other values won't work
local effect_override_types = {
    [1] = true, -- Sword and Shield
    [2] = true, -- Dual Blades
    [3] = true, -- Long Sword
    [6] = true, -- Lance
    [7] = true, -- Gunlance
    [9] = true, -- Charge Blade
    [11] = true, -- Bow
    [12] = true, -- Heavy Bowgun
    [13] = true, -- Light Bowgun
}

local should_restore_effect = false
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
    
    if not is_parry_able then return end

    local collision_layer = hit_info:get_field("<CollisionLayer>k__BackingField")
    on_vanilla_parry = collision_layer == 18
    if on_vanilla_parry then return end

    local main_motion = get_motion()
    local sub_motion = get_sub_motion()
    for _, motion in ipairs({main_motion, sub_motion}) do
        if motion then
            local motion_id = motion.MotionID
            local motion_bank_id = motion.MotionBankID
            local motion_frame = motion.Frame
            local layer_id = motion.LayerID
            local weapon_code = motion_bank_id == 20 and get_wp_type() or -1
            local config_key = string.format("%d_%d_%d_%d", weapon_code, layer_id, motion_bank_id, motion_id)
            local target_motion_config = get_motion_config(config_key)
            for _, target_config in ipairs(target_motion_config.segments) do
                if target_config.enabled and motion_frame >= target_config.start_frame and motion_frame <= target_config.end_frame then
                    hit_info:set_field("<CollisionLayer>k__BackingField", 18) -- PARRY
                    local attack_param_pl = sdk.create_instance("app.cAttackParamPl", true)
                    hit_info:set_DamageAttackData(attack_param_pl)
                    hit_info:get_field("<DamageAttackData>k__BackingField"):set_field("_HitEffectType", 18)
                    hit_info:get_field("<DamageAttackData>k__BackingField"):set_field("_ParryDamage", 90)
                    hit_info:get_field("<DamageAttackData>k__BackingField"):set_field("_HitEffectOverwriteConnectID", -1)
                    get_hunter():startNoHitTimer(target_config.invisible_time)
                    -- log.debug("parry triggered")
                    local effect = get_effect()
                    -- log.debug("effect: " .. string.format("%x", effect:get_address()))
                    local wp_type = get_wp_type()
                    if effect_override_types[wp_type] then
                        local effect_prefab = get_prefab(effect_wp_type)
                        effect:requestSetDataContainer(effect_prefab, 0, effect_wp_type)
                        -- effect:update()
                        effect:lateUpdate()
                        should_restore_effect = true
                    end
                    return
                end
            end
        end
    end
end, function(retval)
    if should_restore_effect then
        local effect = get_effect()
        local wp_type = get_wp_type()
        local current_prefab = get_prefab(wp_type)
        effect:requestSetDataContainer(current_prefab, 0, wp_type)
        should_restore_effect = false
    end
    return retval
end)


-- UI
local UI_preset_table = {}
local function update_UI_preset_table()
    for preset_name, preset_config in pairs(preset_configs) do
        local default_UI_table = {
            motion_bank_id_to_add = 0,
            motion_id_to_add = 0,
            is_submotion_to_add = false,
            motion_name_to_add = "Unnamed",
            preset_save_as = preset_name,
        }
        merge_tables(default_UI_table, UI_preset_table[preset_name])
        UI_preset_table[preset_name] = default_UI_table
    end
end
update_UI_preset_table()

re.on_draw_ui(function()
    local changed, any_changed = false, false
    
    if imgui.tree_node("EverParry") then

        if imgui.tree_node("Global Configs") then
            changed, config.enabled = imgui.checkbox("Enabled", config.enabled)

            if imgui.tree_node("Global Motion Configs") then
                changed, config.global_motion_config.enabled = imgui.checkbox("Enabled", config.global_motion_config.enabled)
                imgui.text("Set the start and end frames of the motion to enable EverParry.")
                imgui.begin_table("Frames", 2)
                imgui.table_next_row()
                imgui.table_next_column()
                changed, config.global_motion_config.start_frame = imgui.drag_int("Start Frame", config.global_motion_config.start_frame, 1, 0, 1000)
                imgui.table_next_column()
                changed, config.global_motion_config.end_frame = imgui.drag_int("End Frame", config.global_motion_config.end_frame, 1, 0, 1000)
                imgui.end_table()
                changed, config.global_motion_config.invisible_time = imgui.drag_float("Invisible Time", config.global_motion_config.invisible_time, 0.01, 0.0, 5.0, "%.2f")
                imgui.tree_pop()
            end
            
            imgui.tree_pop()
        end
        
        if imgui.tree_node("Current Motion") then
            local motion = get_motion()
            local weapon_type = get_wp_type()
            imgui.text("Weapon Type: " .. tostring(weapon_type))
            if motion then
                local motion_id = motion.MotionID
                local motion_bank_id = motion.MotionBankID
                local motion_frame = motion.Frame

                imgui.text("Motion Bank ID: " .. motion_bank_id)
                imgui.text("Motion ID: " .. motion_id)
                imgui.text("Motion Frame: " .. string.format("%.2f", motion_frame))
            else
                imgui.text("No motion detected")
            end
            local sub_motion = get_sub_motion()
            if sub_motion then
                local motion_id = sub_motion.MotionID
                local motion_bank_id = sub_motion.MotionBankID
                local motion_frame = sub_motion.Frame

                imgui.text("Sub Motion Bank ID: " .. motion_bank_id)
                imgui.text("Sub Motion ID: " .. motion_id)
                imgui.text("Sub Motion Frame: " .. string.format("%.2f", motion_frame))
            else
                imgui.text("No sub motion detected")
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Presets") then
            for preset_name, preset_config in spairs(preset_configs) do
                if imgui.tree_node(preset_name) then
                    local UI_vars = UI_preset_table[preset_name]
                    local motion_configs = preset_config.motion_configs
                    changed, preset_config.enabled = imgui.checkbox("Enabled", preset_config.enabled)
                    if imgui.tree_node("Add Motion Config") then
                        imgui.text("Double click to set IDs, then click Add to add motion config.")
                        imgui.begin_table("Add Motion", 2)
                        imgui.table_next_row()
                        imgui.table_next_column()
                        changed, UI_vars.motion_bank_id_to_add = imgui.drag_int("Motion Bank ID", UI_vars.motion_bank_id_to_add, 1, 0, 100)
                        imgui.table_next_column()
                        changed, UI_vars.motion_id_to_add = imgui.drag_int("Motion ID", UI_vars.motion_id_to_add, 1, 0, 1000)
                        imgui.end_table()
                        changed, UI_vars.is_submotion_to_add = imgui.checkbox("Is Sub Motion", UI_vars.is_submotion_to_add)
                        changed, UI_vars.motion_name_to_add, _, _ = imgui.input_text("Motion Name", UI_vars.motion_name_to_add)
                        if imgui.button("Add") then
                            local weapon_code = UI_vars.motion_bank_id_to_add == 20 and get_wp_type() or -1
                            local key = string.format("%d_%d_%d_%d", weapon_code, UI_vars.is_submotion_to_add and 3 or 0, UI_vars.motion_bank_id_to_add, UI_vars.motion_id_to_add)
                            local key_exists = motion_configs[key] ~= nil
                            motion_configs[key] = motion_configs[key] or {}
                            motion_configs[key].name = UI_vars.motion_name_to_add
                        end
                        imgui.tree_pop()
                    end
        
                    if imgui.tree_node("Saved Motions") then
                        for key, motion_config in spairs(motion_configs) do
                            -- make sure motion_config contains all the required fields
                            motion_config.name = motion_config.name or "Unnamed"
                            motion_config.segments = motion_config.segments or {{}}
                            local motion_id_str = motion_config.name .. " (" .. key .. ")"
                            if imgui.tree_node(motion_id_str) then
                                for segment_idx, segment in ipairs(motion_config.segments) do
                                    segment.enabled = segment.enabled or false
                                    segment.start_frame = segment.start_frame or 0
                                    segment.end_frame = segment.end_frame or 0
                                    segment.invisible_time = segment.invisible_time or 0.0

                                    if imgui.tree_node("Segment " .. tostring(segment_idx)) then
                                        changed, segment.enabled = imgui.checkbox("Enabled", segment.enabled)
                                        imgui.begin_table("Frames", 2)
                                        imgui.table_next_row()
                                        imgui.table_next_column()
                                        changed, segment.start_frame = imgui.drag_int("Start Frame", segment.start_frame, 1, 0, 1000)
                                        imgui.table_next_column()
                                        changed, segment.end_frame = imgui.drag_int("End Frame", segment.end_frame, 1, 0, 1000)
                                        imgui.end_table()
                                        changed, segment.invisible_time = imgui.drag_float("Invisible Time", segment.invisible_time, 0.01, 0.0, 5.0, "%.2f")
                                        
                                        if #motion_config.segments > 1 then
                                            if imgui.button("Remove Segment") then
                                                table.remove(motion_config.segments, segment_idx)
                                            end
                                        end
                                        imgui.tree_pop()
                                    end
                                end

                                if imgui.button("Add Segment") then
                                    motion_config.segments[#motion_config.segments + 1] = {}
                                end

                                if imgui.button("Remove Motion") then
                                    motion_configs[key] = nil
                                end
                                imgui.tree_pop()
                            end
                        end
        
                        imgui.tree_pop()
                    end
        
                    if imgui.button("Clear Preset") then
                        preset_config.motion_configs = {}
                    end

                    changed, UI_vars.preset_save_as = imgui.input_text("Save As", UI_vars.preset_save_as)

                    if imgui.button("Save Preset") then
                        json.dump_file(preset_dir .. UI_vars.preset_save_as .. ".json", preset_config)
                        any_changed = true
                    end

                    if preset_name ~= "default" then
                        if imgui.button("Delete Preset") then
                            preset_config.deleted = true
                            json.dump_file(preset_dir .. preset_name .. ".json", preset_config)
                            any_changed = true
                        end
                    end

                    imgui.tree_pop()
                end
            end
            imgui.tree_pop()
        end

        if any_changed then
            load_preset_configs()
            update_UI_preset_table()
        end
        imgui.tree_pop()
    end
end)