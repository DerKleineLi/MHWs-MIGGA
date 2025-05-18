-- config
local config_file = "MV_manager.json"
local preset_dir = "MVManagerPresets\\\\"
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
local preset_names = {}
local preset_idxs = {}

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
    preset_names = {}
    preset_idxs = {}
    for preset_name, _ in spairs(preset_configs) do
        preset_names[#preset_names + 1] = preset_name
        preset_idxs[preset_name] = #preset_names
    end
end
load_preset_configs()

local function get_empty_motion_config()
    return {
        enabled = false,
        name = "Unnamed",
        motion_value = 0.0,
        preset_id = preset_idxs["default"],
    }
end
-- _MVMANAGER_GLOBAL_MOTION_CONFIG = get_empty_motion_config()

local function get_motion_config(key)
    -- if _MVMANAGER_GLOBAL_MOTION_CONFIG.enabled then
    --     return _MVMANAGER_GLOBAL_MOTION_CONFIG
    -- end
    local motion_config = get_empty_motion_config()
    for preset_name, preset in pairs(preset_configs) do
        if not preset.enabled then goto continue end
        if preset.motion_configs[key] then
            motion_config = preset.motion_configs[key]
            motion_config.preset_id = preset_idxs[preset_name]
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

-- core
local hit_data_queue = {}
local max_queue_size = 20
local function push_queue(hit_data)
    table.insert(hit_data_queue, hit_data)
    if #hit_data_queue > max_queue_size then
        table.remove(hit_data_queue, 1)
    end
end

-- on hit
local function get_key(hit_data)
    return string.format("%d_%s_%d", hit_data.weapon_type, hit_data.attack_owner_name, hit_data.attack_index)
end

local function hit_pre(args)
    if not config.enabled then return end
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end
    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    if not attack_data then return end
    local hit_data = {
        weapon_type = attack_data._WeaponType,
        attack_index = hit_info:get_field("<AttackIndex>k__BackingField")._Index,
        attack_owner_name = hit_info:get_field("<AttackOwner>k__BackingField"):get_Name(),
        attack_owner_tag = hit_info:get_field("<AttackOwner>k__BackingField"):get_Tag(),
        motion_value = attack_data._Attack,
    }
    hit_data.key = get_key(hit_data)
    local motion_config = get_motion_config(hit_data.key)
    hit_data.name = motion_config.name
    hit_data.preset_id = motion_config.preset_id
    push_queue(hit_data)

    if motion_config.enabled then
        attack_data._Attack = motion_config.motion_value
    end
end
-- app.Wp10Insect.evAttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("evAttackPreProcess(app.HitInfo)"), hit_pre, nil)
-- app.cHunterWeaponHandlingBase.evHit_AttackPreProcess(app.HitInfo, System.Boolean, System.Boolean)
sdk.hook(sdk.find_type_definition("app.cHunterWeaponHandlingBase"):get_method("evHit_AttackPreProcess(app.HitInfo, System.Boolean, System.Boolean)"), hit_pre, nil)

-- ui
local UI_preset_table = {}
local function update_UI_preset_table()
    for preset_name, preset_config in pairs(preset_configs) do
        local default_UI_table = {
            preset_save_as = preset_name,
        }
        merge_tables(default_UI_table, UI_preset_table[preset_name])
        UI_preset_table[preset_name] = default_UI_table
    end
end
update_UI_preset_table()

re.on_draw_ui(function()
    local changed, any_changed = false, false
    
    if imgui.tree_node("Motion Value Manager") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)

        if imgui.tree_node("Recent Hits") then
            for i = #hit_data_queue, 1, -1 do
                local hit_data = hit_data_queue[i]
                local motion_config = hit_data.motion_config
                local motion_name = hit_data.name
                if imgui.tree_node(hit_data.key .. "##" .. i) then
                    imgui.text("Weapon Type: " .. hit_data.weapon_type)
                    imgui.text("Attack Index: " .. hit_data.attack_index)
                    imgui.text("Attack Owner Name: " .. hit_data.attack_owner_name)
                    imgui.text("Attack Owner Tag: " .. hit_data.attack_owner_tag)
                    imgui.text("Default Motion Value: " .. hit_data.motion_value)
                    changed, hit_data.name = imgui.input_text("Name", hit_data.name)
                    changed, hit_data.preset_id = imgui.combo("Preset Name", hit_data.preset_id, preset_names)
                    local preset_name = preset_names[hit_data.preset_id] or "Not Found"
                    if imgui.button("Add") then
                        preset_configs[preset_name].motion_configs[hit_data.key] = preset_configs[preset_name].motion_configs[hit_data.key] or get_empty_motion_config()
                        preset_configs[preset_name].motion_configs[hit_data.key].name = hit_data.name
                        preset_configs[preset_name].motion_configs[hit_data.key].preset_id = hit_data.preset_id
                        preset_configs[preset_name].motion_configs[hit_data.key].enabled = true
                    end
                    imgui.tree_pop()
                end
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Presets") then
            for preset_name, preset_config in spairs(preset_configs) do
                if imgui.tree_node(preset_name) then
                    local UI_vars = UI_preset_table[preset_name]
                    local motion_configs = preset_config.motion_configs
                    changed, preset_config.enabled = imgui.checkbox("Enabled", preset_config.enabled)
                    if imgui.tree_node("Saved Motions") then
                        for key, motion_config in spairs(motion_configs) do
                            -- make sure motion_config contains all the required fields
                            motion_config.enabled = motion_config.enabled or false
                            motion_config.motion_value = motion_config.motion_value or 0.0
                            motion_config.name = motion_config.name or "Unnamed"
                            motion_config.preset_id = motion_config.preset_id or preset_idxs["default"]
                            local motion_id_str = motion_config.name .. " (" .. key .. ")"
                            if imgui.tree_node(motion_id_str) then
                                changed, motion_config.enabled = imgui.checkbox("Enabled", motion_config.enabled)
                                changed, motion_config.motion_value = imgui.drag_float("Motion Value", motion_config.motion_value, 0.01, -100, 1000.0, "%.2f")

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