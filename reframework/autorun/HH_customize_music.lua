-- config
local config_file = "HH_customize_music.json"
local preset_dir = "HH_customize_music_presets\\\\"

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

local function null_music()
    return {
        MusicScoreID = 0,
        IsSp = false,
        MusicSkillID = 0,
        ToneData = {0, 0, 0, 0},
    }
end

local config = {
    enabled = false,
    musics = {},
    tone_colors = {0, 0, 0},
    HibikiShellType = 0,
    reserve_presets = {nil, nil},
}
for i = 1, 11 do
    config.musics[i] = null_music()
end

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file(config_file, config)
    end
)

local function get_stem(path)
    return path:match("([^/\\]+)%.%w+$")
end

local preset_configs = {}
local preset_name2idx = {}
local preset_idx2name = {}

local function get_empty_preset_config()
    local output = {
        deleted = false,
        musics = {},
        tone_colors = {0, 0, 0},
        HibikiShellType = 0,
    }
    for i = 1, 11 do
        output.musics[i] = null_music()
    end
    return output
end

local ui_table = {
    new_preset_name = "",
}

local function load_preset_configs()
    preset_configs = {}
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
    preset_idx2name = {}
    for name, _ in pairs(preset_configs) do
        table.insert(preset_idx2name, name)
    end
    table.sort(preset_idx2name)
    preset_name2idx = {}
    for i, name in ipairs(preset_idx2name) do
        preset_name2idx[name] = i
        if name == config.reserve_presets[1] then
            ui_table.new_preset_name = name
        end
    end

end
load_preset_configs()

local function load_preset(preset_name)
    if preset_configs[preset_name] then
        config.musics = preset_configs[preset_name].musics
        config.tone_colors = preset_configs[preset_name].tone_colors
        config.HibikiShellType = preset_configs[preset_name].HibikiShellType
        ui_table.new_preset_name = preset_name
    end
end

-- helper functions
local function get_hunter()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_character = player_info:get_Character()
    return hunter_character
end

local function get_wp_handling()
    local hunter = get_hunter()
    if not hunter then return nil end
    local wp = hunter:get_WeaponHandling()
    return wp
end

local function get_enum(type_name)
    local type_def = sdk.find_type_definition(type_name)
    if not type_def then return nil end
    local id2name = {}
    local idpp2name = {}
    local name2id = {}
    for _, field in ipairs(type_def:get_fields()) do
        if field:is_static() then
            local field_name = field:get_name()
            local field_value = field:get_data(nil)
            local field_value_name = tostring(field_value) .. " - " .. field_name
            if field_name == "MAX" then
                goto continue
            end
            id2name[field_value] = field_value_name -- credits to lingsamuel
            idpp2name[field_value + 1] = field_value_name
            name2id[field_value_name] = field_value
        end
        ::continue::
    end
    return {id2name = id2name, idpp2name = idpp2name, name2id = name2id}
end

-- core
local skill_type = get_enum("app.Wp05Def.WP05_MUSIC_SKILL_TYPE")
local tone_type = get_enum("app.Wp05Def.TONE_TYPE")
local tone_color_type = get_enum("app.Wp05Def.WP05_TONE_COLOR_TYPE")
local hibiki_skill_type = get_enum("app.Wp05Def.WP05_HIBIKI_SKILL_TYPE")

local function get_current_musics()
    local wp = get_wp_handling()
    if not wp or not wp._MusicDatas then return end
    local musics = wp._MusicDatas:get_elements()
    for i, music in ipairs(musics) do
        config.musics[i].MusicScoreID = music._MusicScoreID
        config.musics[i].MusicSkillID = music._MusicSkillID
        config.musics[i].IsSp = music._IsSp
        local tones = music._ToneData:get_elements()
        for j, tone in pairs(tones) do
            config.musics[i].ToneData[j] = tone.value__
        end
    end
    for i = 1,3 do
        config.tone_colors[i] = wp:get_field("_ToneCol_" .. i)
    end
    config.HibikiShellType = wp._HibikiFloatShellInfo._HibikiShellType
end

local function apply()
    local wp = get_wp_handling()
    if not wp or not wp._MusicDatas then return end
    local musics = wp._MusicDatas:get_elements()
    for i, music in pairs(musics) do
        musics[i]:call(
            "init(System.UInt32, app.Wp05Def.WP05_MUSIC_SKILL_TYPE, app.Wp05Def.TONE_TYPE, app.Wp05Def.TONE_TYPE, app.Wp05Def.TONE_TYPE, app.Wp05Def.TONE_TYPE, System.Boolean)",
            config.musics[i].MusicScoreID, config.musics[i].MusicSkillID, 
            config.musics[i].ToneData[1], config.musics[i].ToneData[2], config.musics[i].ToneData[3], config.musics[i].ToneData[4],
            config.musics[i].IsSp
        )
    end
    for i = 1,3 do
        wp:set_field("_ToneCol_" .. i, config.tone_colors[i])
    end
    wp._HibikiFloatShellInfo._HibikiShellType = config.HibikiShellType
end

sdk.hook(sdk.find_type_definition("app.HunterCharacter.cHunterExtendPlayer"):get_method("systemInputSetting"), function(args)
    local cHunterExtendPlayer = sdk.to_managed_object(args[2])
    if cHunterExtendPlayer and cHunterExtendPlayer:get_IsMaster() and config.enabled then
        apply()
    end
end, nil)

-- app.HunterCharacter.changeWeaponFromReserve(System.Boolean)
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("changeWeaponFromReserve"), function(args)
    local this_hunter = sdk.to_managed_object(args[2])
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    local reserved_preset = config.reserve_presets[2]
    load_preset(reserved_preset)
    config.reserve_presets[2] = config.reserve_presets[1]
    config.reserve_presets[1] = reserved_preset
end, nil)


-- ui
re.on_draw_ui(function()
    local function enum_combo(name, value, enum_type)
        local valuepp = value + 1
        changed, valuepp = imgui.combo(name, valuepp, enum_type.idpp2name)
        return changed, valuepp - 1
    end

    local changed, any_changed = false, false

    if imgui.tree_node("Hunting Horn Customize Music") then
        if imgui.button("Get Current Music") then
            get_current_musics()
        end

        imgui.begin_group()
        if imgui.button("Apply Configured Music") then
            apply()
        end
        imgui.same_line()
        changed, config.enabled = imgui.checkbox("Automatically Apply Configured Music", config.enabled)
        any_changed = any_changed or changed
        imgui.end_group()

        -- Combo for preset selection
        local selected_preset_idx = preset_name2idx[config.reserve_presets[1]] or 1
        changed, selected_preset_idx = imgui.combo("Current Preset", selected_preset_idx, preset_idx2name)
        if changed then
            config.reserve_presets[1] = preset_idx2name[selected_preset_idx]
            if config.enabled then
                load_preset(config.reserve_presets[1])
                any_changed = true
            end
        end

        imgui.same_line()
        if imgui.button("Load Preset") and config.reserve_presets[1] and preset_configs[config.reserve_presets[1]] then
            load_preset(config.reserve_presets[1])
            any_changed = true
        end

        imgui.same_line()
        if imgui.button("Delete Preset") and config.reserve_presets[1] and preset_configs[config.reserve_presets[1]] then
            local preset_path = preset_dir .. config.reserve_presets[1] .. ".json"
            local preset = preset_configs[config.reserve_presets[1]]
            preset.deleted = true
            json.dump_file(preset_path, preset)
            load_preset_configs()
        end

        local selected_reserved_preset_idx = preset_name2idx[config.reserve_presets[2]] or 1
        changed, selected_reserved_preset_idx = imgui.combo("Reserved Preset", selected_reserved_preset_idx, preset_idx2name)
        if changed then
            config.reserve_presets[2] = preset_idx2name[selected_reserved_preset_idx]
        end

        imgui.same_line()
        if imgui.button("Swap Reserved Preset") then
            local temp = config.reserve_presets[1]
            config.reserve_presets[1] = config.reserve_presets[2]
            config.reserve_presets[2] = temp
            if config.enabled then
                load_preset(config.reserve_presets[1])
                any_changed = true
            end
            any_changed = true
        end

        -- Save new preset
        if not ui_table.new_preset_name then ui_table.new_preset_name = "" end
        changed, ui_table.new_preset_name = imgui.input_text("Save As", ui_table.new_preset_name, 64)
        imgui.same_line()
        if imgui.button("Save Preset") and ui_table.new_preset_name ~= "" then
            local preset_path = preset_dir .. ui_table.new_preset_name .. ".json"
            local preset = {
                deleted = false,
                musics = config.musics,
                tone_colors = config.tone_colors,
                HibikiShellType = config.HibikiShellType,
            }
            json.dump_file(preset_path, preset)
            config.reserve_presets[1] = ui_table.new_preset_name
            load_preset_configs()
        end
        imgui.separator()

        if imgui.tree_node("Musics") then
            for i, music_config in ipairs(config.musics) do
                if imgui.tree_node(tostring(i-1)) then

                    changed, music_config.MusicScoreID = imgui.drag_int("MusicScoreID", music_config.MusicScoreID, 1, 0, 100000)
                    any_changed = any_changed or changed

                    changed, music_config.MusicSkillID = enum_combo("MusicSkillID", music_config.MusicSkillID, skill_type)
                    any_changed = any_changed or changed

                    changed, music_config.IsSp = imgui.checkbox("IsSp", music_config.IsSp)
                    any_changed = any_changed or changed

                    imgui.text("Tones")
                    imgui.begin_group()
                    for t = 1, 4 do
                        imgui.same_line()
                        local avail_width = imgui.get_window_size().x
                        imgui.push_item_width((avail_width - 300) / 4) -- divide available width by 4, minus a small padding
                        changed, music_config.ToneData[t] = enum_combo("## tone" .. t, music_config.ToneData[t], tone_type)
                        imgui.pop_item_width()
                        any_changed = any_changed or changed
                    end
                    imgui.end_group()

                    imgui.tree_pop()
                end
            end
            imgui.tree_pop()
        end

        imgui.text("Tone Colors")
        imgui.begin_group()
        for t = 1, 3 do
            imgui.same_line()
            local avail_width = imgui.get_window_size().x
            imgui.push_item_width((avail_width - 300) / 3)
            changed, config.tone_colors[t] = enum_combo("## tone" .. t, config.tone_colors[t], tone_color_type)
            imgui.pop_item_width()
            any_changed = any_changed or changed
        end
        imgui.end_group()

        changed, config.HibikiShellType = enum_combo("HibikiShellType", config.HibikiShellType, hibiki_skill_type)
        any_changed = any_changed or changed

        imgui.tree_pop()
    end

    if any_changed and config.enabled then apply() end
end)