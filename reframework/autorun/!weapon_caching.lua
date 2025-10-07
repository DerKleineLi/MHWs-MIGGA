-- config
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

-- helper functions
local function get_hunter()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_character = player_info:get_Character()
    return hunter_character
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

-- core
local MAX_WP_TYPE = 13

-- task_lists[wp_type] = { list of cache functions }
local task_lists = {}
for i = 0, MAX_WP_TYPE do
    task_lists[i] = {}
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

-- API: Register a new caching task
local function register_cache_task(target_wp_type, cache_func)
    -- target_wp_type: integer in [0, MAX_WP_TYPE]
    -- cache_func: function that performs caching, returns true if successful
    if target_wp_type < 0 or target_wp_type > MAX_WP_TYPE then
        log.error("Invalid weapon type: " .. tostring(target_wp_type))
        return
    end
    table.insert(task_lists[target_wp_type], cache_func)
end

-- find the next weapon type that has pending tasks
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
    -- log.debug("Weapon caching state: " .. tostring(task_state) .. ", current type: " .. tostring(current_caching_type))
    if task_state == TASK_STATE.IDLE then return end

    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return end
    local hunter_create_info = player_manager:getHunterCreateInfo()
    if not hunter_create_info then return end
    local wp_type = get_wp_type()
    if not wp_type or wp_type == -1 then return end

    local wp_data = get_wp_data(target_wp_type)
    if not wp_data then return end

    if task_state == TASK_STATE.CHANGING then
        if wp_type ~= current_caching_type then
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
        end

    elseif task_state == TASK_STATE.CACHING then
        local funcs = task_lists[current_caching_type]
        local remaining = {}

        for i, func in ipairs(funcs) do
            local ok = func()
            if not ok then
                table.insert(remaining, func)  -- keep for next frame
            end
        end

        -- Replace the list with only the ones that failed this frame
        task_lists[current_caching_type] = remaining

        if #remaining == 0 then
            -- All tasks succeeded
            after_caching()
        else
            attempt_counter = attempt_counter + 1
            if attempt_counter >= config.cache_function_attempts then
                log.warn("Weapon caching: Some funcs failed for weapon type " .. tostring(current_caching_type))
                task_lists[current_caching_type] = {}  -- drop the remaining failed tasks
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

-- Frame update
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

-- Expose API
_WEAPON_CACHING = {
    register_cache_task = register_cache_task
}


-- UI
re.on_draw_ui(function()
    local changed, any_changed = false, false
    if imgui.tree_node("!Weapon Caching") then
        imgui.text("Number of frames to wait between attempts. Increasing it slows down caching, but may prevent disconnects/crashes.")
        changed, config.frames_per_attempt = imgui.drag_int("Frames per Attempt", config.frames_per_attempt, 1, 1, 1000)
        imgui.text("Number of attempts for each caching function. Increase will make caching slower, but may improve success rate.")
        changed, config.cache_function_attempts = imgui.drag_int("Cache Function Attempts", config.cache_function_attempts, 1, 1, 100)
        imgui.tree_pop()
    end
end)