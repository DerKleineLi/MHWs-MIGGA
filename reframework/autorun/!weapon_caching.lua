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
    frame_skip = 30,
    cache_function_retries = 1,
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

-- core
-- Queue for caching tasks
local cache_queue = {}
local current_task = nil

-- API: Register a new caching task
local function register_cache_task(target_wp_type, cache_func)
    -- target_wp_type: integer
    -- cache_func: function that performs caching, returns true if successful
    table.insert(cache_queue, { target_wp_type = target_wp_type, cache_func = cache_func })
end

-- Internal: Get next task in FIFO order
local function next_task()
    if #cache_queue == 0 then return nil end
    return table.remove(cache_queue, 1)
end

local TASK_STATE = {
    CHANGING = 1,
    CACHING = 2,
    RESTORING = 3,
    IDLE = 4,
}
local task_state = TASK_STATE.CHANGING
local retry_counter = 0

local function after_caching()
    current_task = next_task()
    if current_task then
        task_state = TASK_STATE.CHANGING
    else
        task_state = TASK_STATE.RESTORING
    end
    retry_counter = 0
end

local function init_wp_cache(task)
    if task_state == TASK_STATE.IDLE then return end

    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return end

    in_get_hunter_create_info = true
    local hunter_create_info = player_manager:getHunterCreateInfo()
    in_get_hunter_create_info = false
    if not hunter_create_info then return end
    local wp_type = get_wp_type()
    if not wp_type or wp_type == -1 then return end

    if task_state == TASK_STATE.CHANGING then

        if wp_type ~= task.target_wp_type then
            hunter_create_info:set_WpType(task.target_wp_type)
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

        if task.cache_func() then
            after_caching()
        else
            retry_counter = retry_counter + 1
            if retry_counter >= config.cache_function_retries then
                -- Failed to change weapon type in time, reset state
                log.warn("Weapon caching: Failed to cache weapon type " .. tostring(task.target_wp_type))
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
            current_task = nil
        end
    
    end
end

local skip_frame_counter = 0
re.on_frame(function()
    skip_frame_counter = skip_frame_counter + 1
    if skip_frame_counter < config.frame_skip then return end
    skip_frame_counter = 0

    if not current_task then
        current_task = next_task()
        if current_task then
            task_state = TASK_STATE.CHANGING
        end
    end

    init_wp_cache(current_task)
end)

-- Expose API
_WEAPON_CACHING = {
    register_cache_task = register_cache_task
}


-- UI
re.on_draw_ui(function()
    local changed, any_changed = false, false
    if imgui.tree_node("!Weapon Caching") then
        imgui.text("Increase Frame Skip slowers down caching, but may prevent disconnects/crashes.")
        changed, config.frame_skip = imgui.drag_int("Frame Skip", config.frame_skip, 1, 1, 1000)
        imgui.text("Number of retries for each caching function. Increase will make caching slower, but may improve success rate.")
        changed, config.cache_function_retries = imgui.drag_int("Cache Function Retries", config.cache_function_retries, 1, 1, 100)
        imgui.tree_pop()
    end
end)