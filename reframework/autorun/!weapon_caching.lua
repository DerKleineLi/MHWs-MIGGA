-- Weapon Caching

local config_file_path = "weapon_caching.json"
local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k] or false) == "table" then
            merge_tables(t1[k], v)
        else
            t1[k] = v
        end
    end
end

local saved_config = json.load_file(config_file_path) or {}

local config = {
    frames_per_attempt = 30,
    cache_function_attempts = 1,
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file(config_file_path, config)
    end
)

local function get_hunter()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local function read(obj,name)
        if not obj then return nil end
        local ok,value=pcall(function() return obj:call(name) end)
        return ok and value or nil
    end
    local info=read(player_manager,'getMasterPlayerInfo') or read(player_manager,'get_MasterPlayerInfo')
    local hunter=read(info,'getCharacter') or read(info,'get_Character')
    if hunter then return hunter end
    local player=read(player_manager,'getMasterPlayer') or read(player_manager,'get_MasterPlayer')
    return read(player,'get_Character') or read(player,'getCharacter')
end

local function get_wp_type()
    local hunter = get_hunter()
    if not hunter then return nil end
    return hunter:get_WeaponType()
end

local function get_sub_wp_type()
    local hunter = get_hunter()
    if not hunter then return nil end
    return hunter:get_ReserveWeaponType()
end

local function get_wp_data(type)
  return sdk.find_type_definition("app.WeaponUtil"):get_method("getWeaponData(System.Int32, app.WeaponDef.TYPE)"):call(nil, 0, type)
end

local MAX_WP_TYPE = 13

local task_lists = {}
local cache_status = {}
local cache_components = {}
for i = 0, MAX_WP_TYPE do
    task_lists[i] = {}
    cache_status[i] = 'No tasks'
end

local current_caching_type = nil
local attempt_counter = 0

local TASK_STATE = {
    CHANGING = 1,
    CACHING = 2,
    RESTORING = 3,
    IDLE = 4,
}
local task_state = TASK_STATE.IDLE

local function describe_components(func, wp_type)
    if not debug or type(debug.getupvalue) ~= 'function' then return nil end
    local seen = {}
    local scanned = 0
    local function inspect(fn, depth)
        if depth > 3 or seen[fn] or scanned >= 32 then return nil end
        scanned = scanned + 1
        seen[fn] = true
        local children = {}
        for i = 1, 64 do
            local name, value = debug.getupvalue(fn, i)
            if not name then break end
            if name == 'weapon_caching' and type(value) == 'table' then
                local entry = rawget(value, wp_type)
                if type(entry) == 'table' then
                    local shell = rawget(entry, 'shell_list') ~= nil
                    local sound = rawget(entry, 'sound_shell_list_data') ~= nil
                    return 'shell='..(shell and 'present' or 'missing')..
                        ', sound='..(sound and 'present' or 'missing')
                end
            elseif name ~= '_ENV' and type(value) == 'function' then
                children[#children + 1] = value
            end
        end
        for _, child in ipairs(children) do
            local result = inspect(child, depth + 1)
            if result then return result end
        end
    end
    local ok, result = pcall(inspect, func, 0)
    return ok and result or nil
end

local function register_cache_task(target_wp_type, cache_func)
    if target_wp_type < 0 or target_wp_type > MAX_WP_TYPE then
        log.error("Invalid weapon type: " .. tostring(target_wp_type))
        return
    end
    table.insert(task_lists[target_wp_type], cache_func)
    cache_status[target_wp_type] = 'Pending'
end

local function next_wp_type()
    for wp_type = 0, MAX_WP_TYPE do
        if #task_lists[wp_type] > 0 then
            return wp_type
        end
    end
    return nil
end

local function after_caching()
    current_caching_type = next_wp_type()
    if current_caching_type then
        task_state = TASK_STATE.CHANGING
    else
        task_state = TASK_STATE.RESTORING
    end
    attempt_counter = 0
end

local function init_wp_cache()
    if task_state == TASK_STATE.IDLE then return end

    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return end
    local hunter_create_info = player_manager:getHunterCreateInfo()
    if not hunter_create_info then return end
    local wp_type = get_wp_type()
    if not wp_type or wp_type == -1 then return end

    if task_state == TASK_STATE.CHANGING then
        if wp_type ~= current_caching_type then
            local wp_data = get_wp_data(current_caching_type)
            if not wp_data then
                cache_status[current_caching_type] = 'Waiting for weapon data'
                return
            end
            hunter_create_info:set_WpType(current_caching_type)
            hunter_create_info:set_WpID(wp_data:get_Index())
            hunter_create_info:set_OuterWpID(-1)
            hunter_create_info:set_WpModelID(wp_data:get_ModelId())
            player_manager:call(
                "startReloadPlayer(System.Int32, app.cHunterCreateInfo, ace.Bitset`1<app.HunterDef.CREATE_HUNTER_OPTION>)",
                0,
                hunter_create_info,
                nil
            )
        else
            task_state = TASK_STATE.CACHING
            cache_status[current_caching_type] = 'Caching'
        end
    elseif task_state == TASK_STATE.CACHING then
        local funcs = task_lists[current_caching_type]
        local remaining = {}

        for i, func in ipairs(funcs) do
            local ok = func()
            local components = describe_components(func, current_caching_type)
            if components then cache_components[current_caching_type] = components end
            if not ok then
                table.insert(remaining, func)  
            end
        end

        task_lists[current_caching_type] = remaining

        if #remaining == 0 then
            cache_status[current_caching_type] = 'Completed'
            log.info('Weapon caching: Completed tasks for weapon type '..tostring(current_caching_type))
            if cache_components[current_caching_type] then
                log.info('Weapon caching components '..tostring(current_caching_type)..': '..cache_components[current_caching_type])
            end
            after_caching()
        else
            attempt_counter = attempt_counter + 1
            if attempt_counter >= config.cache_function_attempts then
                log.warn("Weapon caching: Some funcs failed for weapon type " .. tostring(current_caching_type))
                cache_status[current_caching_type] = 'Failed (attempt limit)'
                log.warn('Weapon caching components '..tostring(current_caching_type)..': '..
                    (cache_components[current_caching_type] or 'unavailable (consumer layout not recognized)'))
                task_lists[current_caching_type] = {}  
                after_caching()
            end
        end
    elseif task_state == TASK_STATE.RESTORING then
        if wp_type ~= hunter_create_info:get_WpType() then
            player_manager:call(
                "startReloadPlayer(System.Int32, app.cHunterCreateInfo, ace.Bitset`1<app.HunterDef.CREATE_HUNTER_OPTION>)",
                0,
                hunter_create_info,
                nil
            )
        else
            task_state = TASK_STATE.IDLE
            current_caching_type = nil
        end
    end
end

local skip_frame_counter = 0
re.on_frame(function()
    skip_frame_counter = skip_frame_counter + 1
    if skip_frame_counter < config.frames_per_attempt then return end
    skip_frame_counter = 0

    if task_state == TASK_STATE.IDLE then
        current_caching_type = next_wp_type()
        if current_caching_type then
            task_state = TASK_STATE.CHANGING
        end
    end

    init_wp_cache()
end)

_WEAPON_CACHING = {
    register_cache_task = register_cache_task
}

re.on_draw_ui(function()
    local changed, any_changed = false, false
    if imgui.tree_node("!Weapon Caching") then
        imgui.text('Great Sword / weapon 0: '..cache_status[0])
        imgui.text('GS components: '..(cache_components[0] or 'not yet identified'))
        imgui.text('Charge Blade / weapon 9: '..cache_status[9])
        imgui.text('CB components: '..(cache_components[9] or 'not yet identified'))
        imgui.text('Current cache target: '..tostring(current_caching_type or 'none'))
        imgui.text("Number of frames to wait between attempts. Increasing it slows down caching, but may prevent disconnects/crashes.")
        changed, config.frames_per_attempt = imgui.drag_int("Frames per Attempt", config.frames_per_attempt, 1, 1, 1000)
        imgui.text("Number of attempts for each caching function. Increase will make caching slower, but may improve success rate.")
        changed, config.cache_function_attempts = imgui.drag_int("Cache Function Attempts", config.cache_function_attempts, 1, 1, 100)
        imgui.tree_pop()
    end
end)

log.info('Weapon Caching loaded')
