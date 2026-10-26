-- Pandora | https://www.nexusmods.com/monsterhunterwilds/mods/3381
-- Table-copy helper: https://gist.github.com/tylerneylon/81333721109155b2d244

log.info("Pandora loaded")
local config_file = "Pandora.json"
local preset_dir = "PandoraPresets\\\\"

local function merge_tables(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then return end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k] or false) == "table" then
            merge_tables(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

local function copy3(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[copy3(k, s)] = copy3(v, s) end
    return setmetatable(res, getmetatable(obj))
end

local saved_config = json.load_file(config_file) or {}

local function get_empty_shoot_args()
    mv_manager_properties = nil
    if _MV_MANAGER then
        mv_manager_properties = _MV_MANAGER.get_empty_property_config()
    end
    return {
        enabled = false,
        weapon_id = 0,
        shell_id = 1,
        frame = "hunter", 
        frame_args = {}, 
        follow_frame = {
            position = false,
            rotation = false,
        },
        follow_motion = {
            main_motion = false,
            sub_motion = false,
        }, 
        offset = {
            front = 0.0,
            right = 0.0,
            up = 0.0,
            yaw = 0.0,
            pitch = 0.0,
            roll = 0.0
        },
        delay_frame = 0.0,
        mv_manager_properties = mv_manager_properties, 
    }
end

local function get_empty_segment_config()
    return {
        enabled = false,
        start_frame = 0,
        shoot_args_container = {}, 
        description = "",
        segment_config_helper = "None",
        segment_config_helper_args = {}, 
    }
end

local config = {
    enabled = true,
    preview_segments = {},
}

merge_tables(config, saved_config)

local function get_empty_motion_config()
    return {
        enabled = true,
        name = "Unnamed",
        segments = {},
    }
end

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
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end

    if comp then
        table.sort(keys, function(a, b) return comp(t, a, b) end)
    else
        table.sort(keys)
    end

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

local function get_key(weapon_code, layer_id, motion_bank_id, motion_id)
    weapon_code = motion_bank_id == 20 and weapon_code or -1
    return string.format("%d_%d_%d_%d", weapon_code, layer_id, motion_bank_id, motion_id)
end

local function get_motion_config(key)
    local motion_config = get_empty_motion_config()

    for _, preset in pairs(preset_configs) do
        if not preset.enabled then goto continue end
        if preset.motion_configs[key] and preset.motion_configs[key].enabled then
            for _, segment in ipairs(preset.motion_configs[key].segments) do
                if segment.enabled then
                    table.insert(motion_config.segments, segment)
                end
            end
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

local function push_queue(queue, data, max_queue_size)
    table.insert(queue, data)
    if #queue > max_queue_size then
        table.remove(queue, 1)
    end
end

local function normalize_degrees(angle)
    angle = angle % 360
    if angle > 180 then
        angle = angle - 360
    end
    return angle
end

local function ypr_degrees2direction(yaw_deg, pitch_deg, roll_deg)
    local yaw   = math.rad(yaw_deg)
    local pitch = math.rad(pitch_deg)

    local x = math.cos(pitch) * math.sin(yaw)
    local y = math.sin(pitch)
    local z = math.cos(pitch) * math.cos(yaw)

    return Vector3f.new(x, y, z)
end

local function quat_multiply(q2, q1)
    return sdk.find_type_definition("via.quaternion"):get_method("mul(via.Quaternion, via.Quaternion)"):call(nil, q2, q1)
end

local function ypr_degrees2quat(yaw, pitch, roll)
    return sdk.find_type_definition("via.quaternion"):get_method("makeRotationRollPitchYaw(System.Single, System.Single, System.Single)"):call(nil, -math.rad(pitch), -math.rad(yaw), math.rad(roll))
end

local function ax2quat(x, y, z)
    return sdk.find_type_definition("via.MathEx"):get_method("makeQuatAxis3(via.vec3, via.vec3, via.vec3)"):call(nil, x, y, z)
end

local function rotate_quaternion_by_ypr_degrees(q, yaw, pitch, roll)
    local rot = ypr_degrees2quat(yaw, pitch, roll)
    return quat_multiply(rot, q)
end

local function constructor(type_name) 
	local output = (sdk.create_instance(type_name) or sdk.create_instance(type_name, true)):add_ref()
	if output then
		if output:get_type_definition():get_method(".ctor()") then 
			output:call(".ctor()")
		end
		return output
	end
end

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

local function get_wp()
    local hunter = get_hunter()
    if not hunter then return nil end
    local wp = hunter:get_Weapon()
    return wp
end

local function get_wp_type()
    local hunter = get_hunter()
    if not hunter then return nil end
    return hunter:get_WeaponType()
end

local function extract_transform(transform)
    if not transform then return nil end
    local output = {}
    output.transform = transform
    output.position = transform:get_Position()
    output.rotation = transform:get_Rotation()
    output.scale = transform:get_Scale()
    output.forward = transform:get_AxisZ()
    output.right = transform:get_AxisX() * -1
    output.up = transform:get_AxisY()
    return output
end

local function get_hunter_transform()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_object = player_info:get_Object()
    if not hunter_object then return nil end
    local hunter_transform = hunter_object:get_Transform()
    return extract_transform(hunter_transform)
end

local function get_motion(layer_id) 
    layer_id = layer_id or 0
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local player_object = player_info:get_Object()
    if not player_object then return nil end
    local motion = player_object:getComponent(sdk.typeof("via.motion.Motion"))
    if not motion then return nil end
    local layer = motion:getLayer(layer_id)
    if not layer then return nil end

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

local function get_shell_list(wp_type)
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local catalog = player_manager:get_Catalog()
    if not catalog then return nil end
    local wp_assets = catalog:getWeaponEquipUseAssets(wp_type)
    if not wp_assets then return nil end
    return wp_assets:get_ShellList()
end

local function get_epvref(wp_type)
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local catalog = player_manager:get_Catalog()
    if not catalog then return nil end
    local wp_assets = catalog:getWeaponEquipUseAssets(wp_type)
    if not wp_assets then return nil end
    return wp_assets:get_EpvRef()
end

local function get_sound_container()
    local wp = get_wp()
    if not wp then return nil end
    local shell_create_controller = wp._ShellCreateController
    if not shell_create_controller then return nil end
    local owner = shell_create_controller:get_ShellOwner()
    if not owner then return nil end
    local sound_container = owner:getComponent(sdk.typeof("soundlib.SoundContainer"))
    return sound_container
end

local function get_effect()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local player_object = player_info:get_Object()
    return player_object:getComponent(sdk.typeof("via.effect.script.ObjectEffectManager2"))
end

local function get_camera_lookat_position()
    local camera_manager = sdk.get_managed_singleton("app.CameraManager")
    if not camera_manager then return nil end
    local master_camera = camera_manager._MasterPlCamera
    if not master_camera then return nil end
    local camera = master_camera:get_Camera()
    if not camera then return nil end
    local eye_pos = camera:get_EyePos()
    local forward = camera:get_Forward()

    local attach_pos = master_camera:get_AttachPos()
    local eye_to_attach = attach_pos - eye_pos
    local forward_dot = eye_to_attach:dot(forward)
    local min_distance = forward_dot > 0 and forward_dot or 0

    local raycast_manager = sdk.get_managed_singleton("app.AppRaycastManager")
    if not raycast_manager then return nil end

    local raycast_result = raycast_manager:call("castRayImmediate(app.RAY_CAST_TYPE, via.vec3, via.vec3, System.Action`1<via.physics.CastRayResult>)", 15, eye_pos + forward * min_distance, eye_pos + forward * 1000, nil)
    if not raycast_result then return nil end
    local num_contact = raycast_result:get_NumContactPoints()

    if num_contact == 0 then
        raycast_result = raycast_manager:call("castRayImmediate(app.RAY_CAST_TYPE, via.vec3, via.vec3, System.Action`1<via.physics.CastRayResult>)", 0, eye_pos + forward * min_distance, eye_pos + forward * 1000, nil)
        if not raycast_result then return nil end
        num_contact = raycast_result:get_NumContactPoints()
    end

    if num_contact == 0 then
        return eye_pos + forward * 1000
    end
    local contact_point = raycast_result:getContactPoint(0)
    if not contact_point then return nil end
    local contact_pos = contact_point.Position
    return contact_pos
end

local MAX_WP_TYPE = 13
local weapon_caching = {}
for i = 0, MAX_WP_TYPE do
    weapon_caching[i] = {
        caching_registered = false,
        sound_shell_list_data = nil,
        shell_list = nil,
        epvref = nil,
    }
end
local sound_caching_table = {}

local sound_cache_contexts = {}

sdk.hook(sdk.find_type_definition("app.snd_user_data.SoundShellListData"):get_method("findData(System.UInt32)"),
    function(args)
        local wp_type=sound_cache_contexts[thread.get_id()]
        if wp_type == nil then return end
        if not weapon_caching[wp_type].sound_shell_list_data then
            local this = sdk.to_managed_object(args[2])
            if not this then return end
            weapon_caching[wp_type].sound_shell_list_data = this:MemberwiseClone()
            if weapon_caching[wp_type].sound_shell_list_data then
                weapon_caching[wp_type].sound_shell_list_data:add_ref()
            end
        end
    end,
    function(retval)
        return retval
    end
)

local function cache_func(wp_type)
    local function cache_shell_list()
        if weapon_caching[wp_type].shell_list then return end
        local original = get_shell_list(wp_type)
        if not original then return end

        original:add_ref()
        weapon_caching[wp_type].shell_list = original
        log.info("Pandora original shell list retained: weapon " .. tostring(wp_type))
    end

    local function cache_sound_shell_list_data()
        if weapon_caching[wp_type].sound_shell_list_data then return end

        local sound_container = get_sound_container()

        local cache_thread=thread.get_id()
        local previous_cache=sound_cache_contexts[cache_thread]
        sound_cache_contexts[cache_thread]=wp_type
        pcall(function() sound_container:findShellData(0) end)
        sound_cache_contexts[cache_thread]=previous_cache

        if not weapon_caching[wp_type].sound_shell_list_data then return end
        local data_list = weapon_caching[wp_type].sound_shell_list_data._DataList
        if not data_list then return end
        data_list = data_list:get_elements()
        for _, sound_data in ipairs(data_list) do
            local sound_id = sound_data:get_NameHash()
            sound_caching_table[sound_id] = sound_data
        end
    end

    local function cache_epvref()
        if weapon_caching[wp_type].epvref then return end
        weapon_caching[wp_type].epvref = get_epvref(wp_type)
        if not weapon_caching[wp_type].epvref then return end
        weapon_caching[wp_type].epvref = weapon_caching[wp_type].epvref:MemberwiseClone()
        weapon_caching[wp_type].epvref:add_ref()
    end

    cache_shell_list()
    cache_sound_shell_list_data()
    return weapon_caching[wp_type].sound_shell_list_data ~= nil and weapon_caching[wp_type].shell_list ~= nil
end

if _WEAPON_CACHING then
    for wp_type = 0, MAX_WP_TYPE do
        if not weapon_caching[wp_type].caching_registered then
            _WEAPON_CACHING.register_cache_task(wp_type, function() return cache_func(wp_type) end)
            weapon_caching[wp_type].caching_registered = true
        end
    end
else
    re.on_frame(function()
        if not _WEAPON_CACHING then return end
        for wp_type = 0, MAX_WP_TYPE do
            if not weapon_caching[wp_type].caching_registered then
                _WEAPON_CACHING.register_cache_task(wp_type, function() return cache_func(wp_type) end)
                weapon_caching[wp_type].caching_registered = true
            end
        end
    end)
end

local in_mod_shoot_shell = false
local spawn_fault = nil 

local MAX_PULSE_POOL_BATCH = 5
local MAX_PULSE_QUEUED = 10
local pulse_queue = {}
local pulse_update = 0
local pulse_update_ready = false
local pulse_update_running = false
local pulse_retry_at = 0
local pulse_property_getter = nil
local native_spawn_contexts = {}
local pulse_health = {queued=0,peak_queued=0,attempted=0,spawned=0,nil_returns=0,
    dropped=0,setup_calls=0,restore_calls=0,legacy_spawns=0,last_error=''}
local function is_pulse_request(args)
    return type(args)=='table' and type(args.mgs_pulse_pool_batch)=='string'
        and args.weapon_id==0 and args.shell_id==1
end
local function current_spawn_context()
    return native_spawn_contexts[thread.get_id()]
end
local function pulse_owner()
    local ok,result=pcall(function()
        local hunter=get_hunter()
        if not hunter or hunter:get_WeaponType()~=9 then return nil end
        local weapon=hunter:get_Weapon()
        local controller=weapon and weapon._ShellCreateController
        if not controller then return nil end
        return {hunter=tostring(hunter:get_address()),controller=tostring(controller:get_address())}
    end)
    return ok and result or nil
end
local function clear_pulses(key)
    if #pulse_queue==0 then return end
    local remaining={}
    for _,item in ipairs(pulse_queue) do
        if key and item.args.mgs_pulse_pool_batch~=key then remaining[#remaining+1]=item
        else pulse_health.dropped=pulse_health.dropped+1 end
    end
    pulse_queue=remaining;pulse_health.queued=#pulse_queue
end
local function can_queue_pulses(count)
    if not pulse_update_ready then return false,'Engine update spawning unavailable' end
    if spawn_fault then return false,spawn_fault end
    if os.clock()<pulse_retry_at then return false,'Native projectile pool cooling down' end
    if not config.enabled then return false,'Pandora disabled' end
    if type(count)~='number' or count<1 or count>MAX_PULSE_POOL_BATCH or count%1~=0 then
        return false,'Invalid projectile count'
    end
    if #pulse_queue+count>MAX_PULSE_QUEUED then return false,'Pulse queue full' end
    if not weapon_caching[0].shell_list then return false,'Great Sword shell cache not ready' end
    if not pulse_owner() then return false,'Charge Blade owner unavailable' end
    return true
end
local active_pool_batch = nil
local function finish_pool_batch()
    local batch = active_pool_batch
    active_pool_batch = nil
    if not batch or not batch.attempted then return end
    local ok, err = pcall(function()
        pulse_health.restore_calls=pulse_health.restore_calls+1
        batch.controller:setup(batch.owner, batch.original)
    end)
    if not ok then
        spawn_fault = 'batched controller restore failed: ' .. tostring(err)
        log.error('Pandora spawning halted: ' .. spawn_fault)
    end
end
local in_callMazzleFx = false
local shell_start_pos = nil
local shell_start_rot = nil
local should_skip_doAfterCreateEffectEventCore = false
local mod_managed_shell = {}
local MAX_MANAGED_SHELL = 100

re.on_frame(function()
    if not mod_managed_shell then
        mod_managed_shell = {}
        return
    end

    local new_managed_shell = {}
    for _, managed_shell in ipairs(mod_managed_shell) do
        local shell = managed_shell.shell
        if shell:get_ShellOwner() then
            push_queue(new_managed_shell, managed_shell, MAX_MANAGED_SHELL)
        end
    end
    mod_managed_shell = new_managed_shell
end)

local function get_sound_shell_data(sound_id)
    return sound_caching_table[sound_id]
end

sdk.hook(sdk.find_type_definition("soundlib.SoundContainer"):get_method("findShellData(System.UInt32)"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        if this ~= get_sound_container() then return end

        local storage = thread.get_hook_storage()
        local target_sound_id = sdk.to_int64(args[3]) & 0xFFFFFFFF
        storage["target_sound_id"] = target_sound_id
    end,
    function(retval)
        local ret = sdk.to_managed_object(retval)
        if ret then return retval end
        local target_sound_id = thread.get_hook_storage()["target_sound_id"]
        local sound_data = get_sound_shell_data(target_sound_id)
        if sound_data then
            return sdk.to_ptr(sound_data)
        end
        return retval
    end
)

sdk.hook(sdk.find_type_definition("app.mcShellCallEffect"):get_method("callMazzleFx()"),
    function(args)
        local ctx=current_spawn_context()
        thread.get_hook_storage().MGS_PandoraMuzzle=ctx
        if ctx then ctx.muzzle_depth=ctx.muzzle_depth+1 end
    end,
    function(retval)
        local ctx=thread.get_hook_storage().MGS_PandoraMuzzle
        if ctx then ctx.muzzle_depth=math.max(0,ctx.muzzle_depth-1) end
        return retval
    end
)

sdk.hook(sdk.find_type_definition("app.cEffectController"):get_method("playEffect(System.UInt32, app.EffectID_Common.ID, via.GameObject, app.cEffectOverwriteParams)"),
    function(args)
        local ctx=current_spawn_context()
        if not ctx or ctx.muzzle_depth<1 then return end
        local effect_override_params = sdk.to_managed_object(args[6])
        if not effect_override_params then return end

        effect_override_params:set_IsUpdatePos(true)
        effect_override_params:set_Pos(ctx.position)
        effect_override_params:set_IsUpdateRotation(true)
        effect_override_params:set_Rotation(ctx.rotation)
    end,
    nil
)

sdk.hook(sdk.find_type_definition("ace.EngineSingletonCallbackManager"):get_method("doAfterCreateEffectEventCore(via.effect.script.EffectManager.AfterCreateEffectInfo)"),
    function(args)
        if current_spawn_context() then
            return sdk.PreHookResult.SKIP_ORIGINAL
        end
    end,
    nil
)

local frame_types_id2str = {}
local frame_types_str2id = {}
local frame_types_str2func = {}
local frame_types_str2ui = {}
local frame_types_str2init_args = {}
local function register_frame_type(name, get_frame_func, ui, init_args)
    local id = #frame_types_id2str + 1
    frame_types_id2str[id] = name
    frame_types_str2id[name] = id
    frame_types_str2func[name] = get_frame_func
    frame_types_str2ui[name] = ui
    frame_types_str2init_args[name] = init_args
end

local function get_frame_transform(shoot_args, old_frame_transform)
    local get_frame_func = frame_types_str2func[shoot_args.frame]
    if not get_frame_func then return nil end
    local frame_transform = get_frame_func(shoot_args.frame_args)

    if not old_frame_transform then return frame_transform end

    if not shoot_args.follow_frame.position then
        frame_transform.position = old_frame_transform.position
    end

    if not shoot_args.follow_frame.rotation then
        frame_transform.rotation = old_frame_transform.rotation
        frame_transform.forward = old_frame_transform.forward
        frame_transform.right = old_frame_transform.right
        frame_transform.up = old_frame_transform.up
    end

    return frame_transform
end

local function get_shell_transform(shoot_args, old_frame_transform)
    local frame_transform = get_frame_transform(shoot_args, old_frame_transform)
    if not frame_transform then return nil end

    local position = frame_transform.position
        + frame_transform.forward * shoot_args.offset.front
        + frame_transform.right * shoot_args.offset.right
        + frame_transform.up * shoot_args.offset.up
    local rotation = rotate_quaternion_by_ypr_degrees(
        frame_transform.rotation,
        shoot_args.offset.yaw,
        shoot_args.offset.pitch,
        shoot_args.offset.roll
    )
    return {position = position, rotation = rotation}
end

local function shoot_single_shell(shoot_args, old_frame_transform)
    if spawn_fault then return end

    local weapon_id = shoot_args.weapon_id
    local shell_id = shoot_args.shell_id

    local function shoot(shell_create_controller, shell_id, shellShootingInfo)
        local pulse=is_pulse_request(shoot_args)
        if pulse then pulse_health.attempted=pulse_health.attempted+1 end
        local new_shell = shell_create_controller:shootShell(shell_id, shellShootingInfo, nil)
        if new_shell then
            if pulse then
                pulse_health.spawned=pulse_health.spawned+1
                pulse_health.last_unavailable=false
            else
                pulse_health.legacy_spawns=pulse_health.legacy_spawns+1
                local managed_shell = { shell = new_shell, shoot_args = shoot_args }
                push_queue(mod_managed_shell, managed_shell, MAX_MANAGED_SHELL)
            end
        else
            if pulse then
                pulse_health.nil_returns=pulse_health.nil_returns+1
                pulse_health.last_unavailable=true
                pulse_health.last_error='Native Dark Arts creation returned no shell; volley cancelled'
                pulse_retry_at=os.clock()+0.5
                if active_pool_batch then active_pool_batch.unavailable=true end
                log.warn(pulse_health.last_error)
                return false
            end
            log.warn("Failed to get shell instance: " .. tostring(weapon_id) .. " " .. tostring(shell_id))
        end
    end

    local transform = get_shell_transform(shoot_args, old_frame_transform)
    if not transform then return end
    local position = transform.position
    local rotation = transform.rotation

    local shellShootingInfo = constructor("app.cShellShootingInfo")
    if not shellShootingInfo then return end

    local start_pos = shellShootingInfo:get_field("<StartPos>k__BackingField")
    start_pos:set_field("_HasValue", true)
    start_pos:set_field("_Value", position)
    shellShootingInfo:set_field("<StartPos>k__BackingField", start_pos)

    local start_rot = shellShootingInfo:get_field("<StartRot>k__BackingField")
    start_rot:set_field("_HasValue", true)
    start_rot:set_field("_Value", rotation)
    shellShootingInfo:set_field("<StartRot>k__BackingField", start_rot)

    if weapon_id >= 0 then
        local wp = get_wp()
        if not wp then return end
        local wp_type = get_wp_type()
        if not wp_type or wp_type == -1 then return end
        local shell_create_controller = wp._ShellCreateController
        if not shell_create_controller then return end
        local current_shell_list = get_shell_list(wp_type)
        if not current_shell_list then return end

        local shell_list_cache = weapon_caching[weapon_id].shell_list
        if not shell_list_cache then return end
        local shell_owner = shell_create_controller:get_ShellOwner()
        if not shell_owner then
            error("Pandora spawn: weapon shell controller has no owner")
        end

        in_mod_shoot_shell = true
        should_skip_doAfterCreateEffectEventCore = true
        shell_start_pos = position
        shell_start_rot = rotation
        local spawn_thread=thread.get_id()
        local previous_context=native_spawn_contexts[spawn_thread]
        native_spawn_contexts[spawn_thread]={position=position,rotation=rotation,muzzle_depth=0}
        local spawn_stage = 'setup source shell list'
        local spawn_ok, spawn_error = pcall(function()
            local batch = active_pool_batch
            if batch then
                if batch.ready then
                    if batch.controller:get_address() ~= shell_create_controller:get_address() then
                        error('Weapon controller changed within pulse batch')
                    end
                else
                    batch.controller = shell_create_controller
                    batch.owner = shell_owner
                    batch.original = current_shell_list
                    batch.attempted = true
                    pulse_health.setup_calls=pulse_health.setup_calls+1
                    shell_create_controller:setup(shell_owner, shell_list_cache)
                    batch.ready = true
                end
            else
                shell_create_controller:setup(shell_owner, shell_list_cache)
            end
            spawn_stage = 'shootShell'
            shoot(shell_create_controller, shell_id, shellShootingInfo)
        end)
        native_spawn_contexts[spawn_thread]=previous_context
        shell_start_pos = nil
        shell_start_rot = nil
        should_skip_doAfterCreateEffectEventCore = false
        in_mod_shoot_shell = false

        local restore_ok, restore_error = pcall(function()
            if not active_pool_batch then
                shell_create_controller:setup(shell_owner, current_shell_list)
            end
        end)
        if not restore_ok then
            spawn_fault = 'controller restore failed: ' .. tostring(restore_error)
            log.error("Pandora spawn safety: disabled after controller restore failure: " .. tostring(restore_error))
        end
        if not spawn_ok then
            spawn_fault = spawn_fault or (spawn_stage .. ' failed: ' .. tostring(spawn_error))
            log.error("Pandora spawn halted for this session: " .. spawn_fault)
            error("Pandora spawn " .. tostring(weapon_id) .. "/" .. tostring(shell_id) .. ": " .. tostring(spawn_error))
        end
    elseif weapon_id == -1 then
        local hunter = get_hunter()
        if not hunter then return end
        local shell_create_controller = hunter._ShellCreateController
        if not shell_create_controller then return end

        in_mod_shoot_shell = true
        shell_start_pos = position
        shell_start_rot = rotation
        should_skip_doAfterCreateEffectEventCore = true
        local spawn_thread=thread.get_id()
        local previous_context=native_spawn_contexts[spawn_thread]
        native_spawn_contexts[spawn_thread]={position=position,rotation=rotation,muzzle_depth=0}
        pcall(shoot, shell_create_controller, shell_id, shellShootingInfo)
        native_spawn_contexts[spawn_thread]=previous_context
        should_skip_doAfterCreateEffectEventCore = false
        shell_start_pos = nil
        shell_start_rot = nil
        in_mod_shoot_shell = false
    end
end

local registered_shells = {}
local function register_shell(shoot_args)
    if spawn_fault then return false end
    local shoot_args = merge_tables(get_empty_shoot_args(), shoot_args or {})
    if not shoot_args.enabled then return end

    if is_pulse_request(shoot_args) then
        local ready,reason=can_queue_pulses(1)
        if not ready then pulse_health.last_error=tostring(reason);return false end
        local owner=pulse_owner()
        if not owner then return false end
        if not frame_types_str2func[shoot_args.frame] then return false end
        pulse_queue[#pulse_queue+1]={args=shoot_args,owner=owner,update=pulse_update}
        pulse_health.queued=#pulse_queue
        pulse_health.peak_queued=math.max(pulse_health.peak_queued,#pulse_queue)
        return true
    end

    local delay_time = shoot_args.delay_frame / 60.0
    table.insert(registered_shells, {
        time = os.clock() + delay_time,
        args = shoot_args,
        old_frame_transform = get_frame_transform(shoot_args, nil),
        old_motion = get_motion(),
        old_sub_motion = get_sub_motion(),
    })
end

local function update_pulses()
    if pulse_update_running then return end
    pulse_update=pulse_update+1
    if spawn_fault or not config.enabled then clear_pulses();return end
    if #pulse_queue==0 then return end
    if active_pool_batch or next(native_spawn_contexts) then return end
    local owner=pulse_owner()
    if not owner then clear_pulses();return end
    local key=pulse_queue[1].args.mgs_pulse_pool_batch
    local batch={}
    while #pulse_queue>0 and pulse_queue[1].args.mgs_pulse_pool_batch==key
        and #batch<MAX_PULSE_POOL_BATCH do
        batch[#batch+1]=table.remove(pulse_queue,1)
    end
    pulse_health.queued=#pulse_queue
    pulse_update_running=true
    local ok,err=pcall(function()
        for index,item in ipairs(batch) do
            if spawn_fault then
                pulse_health.dropped=pulse_health.dropped+#batch-index+1
                break
            end
            if pulse_update-item.update>2 or item.owner.hunter~=owner.hunter
                or item.owner.controller~=owner.controller then
                pulse_health.dropped=pulse_health.dropped+1
            else
                if not active_pool_batch then active_pool_batch={key=key,count=0} end
                active_pool_batch.count=active_pool_batch.count+1
                local before=pulse_health.spawned
                local success,why=pcall(shoot_single_shell,item.args,nil)
                if not success then
                    pulse_health.last_error=tostring(why):sub(1,220)
                    if not spawn_fault then pulse_health.dropped=pulse_health.dropped+1
                    else pulse_health.dropped=pulse_health.dropped+#batch-index+1;break end
                elseif active_pool_batch and active_pool_batch.unavailable then
                    pulse_health.dropped=pulse_health.dropped+#batch-index+1
                    clear_pulses()
                    break
                elseif pulse_health.spawned==before then
                    pulse_health.dropped=pulse_health.dropped+1
                end
            end
        end
    end)
    finish_pool_batch()
    pulse_update_running=false
    if not ok then
        spawn_fault='Pulse update failed: '..tostring(err):sub(1,180)
        pulse_health.last_error=spawn_fault
    end
    if spawn_fault then
        pulse_health.last_error=spawn_fault
        clear_pulses()
        log.error('Arkveld native spawning stopped: '..spawn_fault)
    end
end
if type(re.on_pre_application_entry)=='function' then
    pulse_update_ready=pcall(re.on_pre_application_entry,'UpdateBehavior',update_pulses)
end
if type(re.on_script_reset)=='function' then
    re.on_script_reset(function() clear_pulses() end)
end

local last_motion = nil
local last_sub_motion = nil
local last_update_motion_time = nil

local function should_register_shell(motion, start_frame)
    local last_motion = motion.LayerID == 0 and last_motion or last_sub_motion
    if not last_motion then return false end
    if not last_update_motion_time then return false end

    local is_same_motion = motion.MotionID == last_motion.MotionID and motion.MotionBankID == last_motion.MotionBankID
    local last_frame = is_same_motion and last_motion.Frame or (motion.Frame - (math.max(os.clock() - last_update_motion_time, 1.0) * 60))
    return motion.Frame >= start_frame and last_frame < start_frame
end

local function get_key_from_motion(motion, is_submotion)
    local motion_id = motion.MotionID
    local motion_bank_id = motion.MotionBankID
    local layer_id = motion.LayerID
    local weapon_code = motion_bank_id == 20 and get_wp_type() or -1
    return get_key(weapon_code, layer_id, motion_bank_id, motion_id)
end

re.on_application_entry("UpdateMotionFrame", function()
    if not config.enabled then return end

    local main_motion = get_motion()
    local sub_motion = get_sub_motion()
    for _, motion in ipairs({main_motion, sub_motion}) do
        if not motion then goto continue end

        local config_key = get_key_from_motion(motion)
        local target_motion_config = get_motion_config(config_key)

        for _, segment_config in ipairs(target_motion_config.segments) do
            if not segment_config.enabled then goto continue1 end
            if not should_register_shell(motion, segment_config.start_frame) then goto continue1 end

            for _, shoot_args in ipairs(segment_config.shoot_args_container) do
                register_shell(shoot_args)
            end

            ::continue1::
        end
        ::continue::
    end

    last_motion = main_motion
    last_sub_motion = sub_motion
    last_update_motion_time = os.clock()
end)

re.on_frame(function()
    if spawn_fault then registered_shells = {}; return end
    if not config.enabled then return end
    if #registered_shells==0 then return end
    if pulse_update_running or active_pool_batch or next(native_spawn_contexts) then return end

    local current_time = os.clock()
    local current_motion = get_motion()
    if not current_motion then return end
    local current_sub_motion = get_sub_motion()
    if not current_sub_motion then return end

    local remaining = {}
    for i, shell in ipairs(registered_shells) do
        if spawn_fault or not config.enabled then break end
        if shell.args.follow_motion.main_motion and (current_motion.MotionID ~= shell.old_motion.MotionID or current_motion.MotionBankID ~= shell.old_motion.MotionBankID) then
            goto continue
        end
        if shell.args.follow_motion.sub_motion and (current_sub_motion.MotionID ~= shell.old_sub_motion.MotionID or current_sub_motion.MotionBankID ~= shell.old_sub_motion.MotionBankID) then
            goto continue
        end

        if current_time >= shell.time then
            local key = shell.args.mgs_pulse_pool_batch

            if type(key) ~= 'string' or shell.args.weapon_id ~= 0 or shell.args.shell_id ~= 1 then key = nil end
            if active_pool_batch and (not key or active_pool_batch.key ~= key or active_pool_batch.count >= MAX_PULSE_POOL_BATCH) then
                finish_pool_batch()
            end
            if spawn_fault then break end
            if key and not active_pool_batch then active_pool_batch = {key=key,count=0} end
            if active_pool_batch then active_pool_batch.count = active_pool_batch.count + 1 end
            local success, err = pcall(shoot_single_shell, shell.args, shell.old_frame_transform)
            if not success then
                log.error("Failed to shoot shell: " .. tostring(err))
            end
        else
            table.insert(remaining, shell)
        end
        ::continue::
    end
    finish_pool_batch()
    if spawn_fault then remaining = {} end
    registered_shells = remaining
end)

local mv_manager_property_getter_registered = false

local function property_getter(this, hit_info)
    if not this then return nil end
    if not hit_info then return nil end
    local this_type = this:get_type_definition():get_full_name()
    if this_type ~= "app.mcShellColHit" then
        return nil
    end
    if pulse_property_getter then
        local ok,properties=pcall(pulse_property_getter,this,hit_info)
        if ok and properties then return properties end
    end
    local shell = this:get_Shell()
    if not shell then return end

    for _, managed_shell in ipairs(mod_managed_shell) do
        if shell:Equals(managed_shell.shell) then
            return managed_shell.shoot_args.mv_manager_properties
        end
    end
    return nil
end

if _MV_MANAGER then
    _MV_MANAGER.register_third_party_property_getter("pandora", property_getter)
    mv_manager_property_getter_registered = true
else
    re.on_frame(function()
        if not _MV_MANAGER then return end
        if not mv_manager_property_getter_registered then
            _MV_MANAGER.register_third_party_property_getter("pandora", property_getter)
            mv_manager_property_getter_registered = true
        end
    end)
end

local latest_shell_queue = {}
local MAX_QUEUE_SIZE = 20

sdk.hook(sdk.find_type_definition("ace.cShellCreateController"):get_method("shootShell(System.Int32, ace.cShellShootingInfoBase, System.Action`1<ace.ShellBase>)"),
    function(args)
        if current_spawn_context() then return end

        local this = sdk.to_managed_object(args[2])
        if not this then return end

        local wp = get_wp()
        if not wp then return end
        local wp_shell_create_controller = wp._ShellCreateController
        if not wp_shell_create_controller then return end

        local hunter = get_hunter()
        if not hunter then return end
        local hunter_shell_create_controller = hunter._ShellCreateController
        if not hunter_shell_create_controller then return end

        local is_hunter_controller = this:Equals(hunter_shell_create_controller)
        local is_wp_controller = this:Equals(wp_shell_create_controller)
        if not (is_hunter_controller or is_wp_controller) then return end

        local weapon_id = -1
        if is_wp_controller then
            weapon_id = wp:get_WpType()
            if not weapon_id or weapon_id == -1 then return end
        end

        local shell_id = sdk.to_int64(args[3]) & 0xFFFFFFFF
        push_queue(latest_shell_queue, {weapon_id = weapon_id, shell_id = shell_id}, MAX_QUEUE_SIZE)
    end,
    nil
)

local UI_vars = {
    motion_bank_id_to_add = 0,
    motion_id_to_add = 0,
    is_submotion_to_add = false,
    motion_name_to_add = "Unnamed",
    preset_to_add = "default",
    new_preset_name = "new_preset",
    segment_config_helper = "None",
}

local function get_key_from_ui_vars()
    local weapon_code = UI_vars.motion_bank_id_to_add == 20 and get_wp_type() or -1
    return get_key(weapon_code, UI_vars.is_submotion_to_add and 3 or 0, UI_vars.motion_bank_id_to_add, UI_vars.motion_id_to_add)
end

local function ui_combo(value, label, id2str, str2id)
    local changed, new_id = imgui.combo(label, str2id[value], id2str)
    return changed, id2str[new_id]
end

local function tooltip(text) 
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then imgui.set_tooltip("  "..text.."  ") end
end

local segment_config_helper_id2str = {}
local segment_config_helper_str2id = {}
local segment_config_helper_str2func = {}
local segment_config_helper_str2ui = {}
local segment_config_helper_str2set_args = {}
local segment_config_helper_str2get_args = {}
local function register_segment_config_helper(name, func, ui, set_args, get_args)
    local id = #segment_config_helper_id2str + 1
    segment_config_helper_id2str[id] = name
    segment_config_helper_str2id[name] = id
    segment_config_helper_str2func[name] = func
    segment_config_helper_str2ui[name] = ui
    segment_config_helper_str2set_args[name] = set_args
    segment_config_helper_str2get_args[name] = get_args
end

local function run_segment_config_helper(name, segment_config, shoot_args)
    local func = segment_config_helper_str2func[name]
    if func then
        func(segment_config, shoot_args)
    end
    local get_args = segment_config_helper_str2get_args[name]
    if get_args then
        segment_config.segment_config_helper = name
        segment_config.segment_config_helper_args = copy3(get_args())
    end
end

local function set_segment_config_helper_args(name, segment_config, shoot_args)
    local set_args = segment_config_helper_str2set_args[name]
    if set_args then
        set_args(segment_config.segment_config_helper_args)
    end
end

local function preset_combo(value, label)
    local id2str = {}
    local str2id = {}
    local i = 1
    for preset_name, preset_config in spairs(preset_configs) do
        id2str[i] = preset_name
        str2id[preset_name] = i
        i = i + 1
    end
    return ui_combo(value, label, id2str, str2id)
end

local function shoot_args_ui(shoot_args)
    local changed = false
    if not shoot_args then return end
    changed, shoot_args.enabled = imgui.checkbox("Enabled", shoot_args.enabled)
    changed, shoot_args.weapon_id = imgui.drag_int("Weapon ID", shoot_args.weapon_id, 1, -1, MAX_WP_TYPE)
    changed, shoot_args.shell_id = imgui.drag_int("Shell ID", shoot_args.shell_id, 1, 0, 1000)
    changed, shoot_args.frame = ui_combo(shoot_args.frame, "Frame", frame_types_id2str, frame_types_str2id)

    shoot_args.frame_args = merge_tables(frame_types_str2init_args[shoot_args.frame](), shoot_args.frame_args or {})

    if imgui.tree_node("Frame Options") then
        local ui_func = frame_types_str2ui[shoot_args.frame]
        if ui_func then
            ui_func(shoot_args.frame_args)
        end
        imgui.tree_pop()
    end
    if imgui.tree_node("Follow Frame") then
        changed, shoot_args.follow_frame.position = imgui.checkbox("Follow Frame Position", shoot_args.follow_frame.position)
        changed, shoot_args.follow_frame.rotation = imgui.checkbox("Follow Frame Rotation", shoot_args.follow_frame.rotation)
        imgui.tree_pop()
    end
    if imgui.tree_node("Follow Motion") then
        changed, shoot_args.follow_motion.main_motion = imgui.checkbox("Follow Main Motion", shoot_args.follow_motion.main_motion)
        changed, shoot_args.follow_motion.sub_motion = imgui.checkbox("Follow Sub Motion", shoot_args.follow_motion.sub_motion)
        imgui.tree_pop()
    end
    if imgui.tree_node("Offset") then
        changed, shoot_args.offset.front = imgui.drag_float("Front", shoot_args.offset.front, 0.1, -100.0, 100.0, "%.2f")
        changed, shoot_args.offset.right = imgui.drag_float("Right", shoot_args.offset.right, 0.1, -100.0, 100.0, "%.2f")
        changed, shoot_args.offset.up = imgui.drag_float("Up", shoot_args.offset.up, 0.1, -100.0, 100.0, "%.2f")
        changed, shoot_args.offset.yaw = imgui.drag_float("Yaw", shoot_args.offset.yaw, 1.0, -180.0, 180.0, "%.1f")
        changed, shoot_args.offset.pitch = imgui.drag_float("Pitch", shoot_args.offset.pitch, 1.0, -180.0, 180.0, "%.1f")
        changed, shoot_args.offset.roll = imgui.drag_float("Roll", shoot_args.offset.roll, 1.0, -180.0, 180.0, "%.1f")
        imgui.tree_pop()
    end
    changed, shoot_args.delay_frame = imgui.drag_float("Delay (frames)", shoot_args.delay_frame, 0.1, 0.0, 300.0, "%.2f")
    if _MV_MANAGER then
        if shoot_args.mv_manager_properties == nil then
            shoot_args.mv_manager_properties = _MV_MANAGER.get_empty_property_config()
        end
        if imgui.tree_node("MV Manager Properties") then
            _MV_MANAGER.ui_properties(shoot_args.mv_manager_properties)
            imgui.tree_pop()
        end
    end
end

local function segment_config_ui(segment_config)
    local changed = false
    changed, segment_config.description, _, _ = imgui.input_text_multiline("Description", segment_config.description, { 300, 100 })
    changed, segment_config.enabled = imgui.checkbox("Enabled", segment_config.enabled)
    changed, segment_config.start_frame = imgui.drag_int("Start Frame", segment_config.start_frame, 1, 0, 1000)
    if imgui.tree_node("Shoot Args Container") then
        if not segment_config.shoot_args_container then
            segment_config.shoot_args_container = {}
        end
        for i, shoot_args in ipairs(segment_config.shoot_args_container) do
            if imgui.tree_node("Shoot Args " .. tostring(i)) then
                shoot_args_ui(shoot_args)
                if imgui.button("Test Shoot") then
                    register_shell(shoot_args)
                end
                if imgui.tree_node("Config Helper") then
                    changed, UI_vars.segment_config_helper = ui_combo(UI_vars.segment_config_helper, "Helper", segment_config_helper_id2str, segment_config_helper_str2id)
                    if imgui.tree_node("Helper Args") then
                        local ui_func = segment_config_helper_str2ui[UI_vars.segment_config_helper]
                        if ui_func then
                            ui_func()
                        end
                        imgui.tree_pop()
                    end
                    if imgui.button("Run Helper") then
                        run_segment_config_helper(UI_vars.segment_config_helper, segment_config, shoot_args)
                    end
                    if imgui.button("Get Helper Args from Current Segment") then
                        UI_vars.segment_config_helper = segment_config.segment_config_helper
                        set_segment_config_helper_args(segment_config.segment_config_helper, segment_config, shoot_args)
                    end
                    imgui.tree_pop()
                end
                if imgui.button("Remove Shoot Args") then
                    table.remove(segment_config.shoot_args_container, i)
                end
                imgui.tree_pop()
            end
        end
        if imgui.button("Test Shoot") then
            for i, shoot_args in ipairs(segment_config.shoot_args_container) do
                register_shell(shoot_args)
            end
        end
        if imgui.button("Add Shoot Args") then
            table.insert(segment_config.shoot_args_container, get_empty_shoot_args())
        end
        if imgui.button("Clear Shoot Args") then
            segment_config.shoot_args_container = {}
        end
        imgui.tree_pop()
    end
end

local function segments_config_ui(segments)
    for i, segment_config in ipairs(segments) do
        if imgui.tree_node("Segment " .. tostring(i)) then
            segment_config_ui(segment_config)

            if #segments > 1 then
                if imgui.button("Remove Segment") then
                    table.remove(segments, i)
                end
            end
            imgui.tree_pop()
        end
    end
    if imgui.button("Add Segment") then
        table.insert(segments, get_empty_segment_config())
    end
    if imgui.button("Clear Segments") then
        segments = {}
    end
end

re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Pandora") then
        if spawn_fault then
            imgui.text("Spawning halted: " .. spawn_fault)
            imgui.text("Restart the game before attempting another spawn.")
        end
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)
        if imgui.tree_node("Preview Config") then
            if imgui.tree_node("Segments") then
                segments_config_ui(config.preview_segments)
                imgui.tree_pop()
            end

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

                local preset_id2str = {}
                local preset_str2id = {}
                for preset_name, _ in spairs(preset_configs) do
                    table.insert(preset_id2str, preset_name)
                    preset_str2id[preset_name] = #preset_id2str
                end
                changed, UI_vars.preset_to_add = ui_combo(UI_vars.preset_to_add, "Preset to Add", preset_id2str, preset_str2id)

                local key = get_key_from_ui_vars()
                local motion_config_exists = false
                local preset_config = preset_configs[UI_vars.preset_to_add]
                if preset_config then
                    motion_config_exists = preset_config.motion_configs[key] ~= nil
                else
                    log.error("Preset " .. UI_vars.preset_to_add .. " does not exist.")
                end
                local add_motion_button_name = motion_config_exists and "Overwrite" or "Add"

                if imgui.button(add_motion_button_name) then
                    local motion_config = get_empty_motion_config()
                    motion_config.name = UI_vars.motion_name_to_add
                    motion_config.segments = copy3(config.preview_segments)
                    preset_config.motion_configs[key] = motion_config
                end

                changed, UI_vars.new_preset_name, _, _ = imgui.input_text("New Preset Name", UI_vars.new_preset_name)
                local preset_exists = preset_configs[UI_vars.new_preset_name] ~= nil
                local add_preset_button_name = preset_exists and "Clear This Preset" or "Create New Preset"
                if imgui.button(add_preset_button_name) then
                    preset_configs[UI_vars.new_preset_name] = get_empty_preset_config()
                end
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

        if imgui.tree_node("Latest Shells Fired") then
            for i = #latest_shell_queue, 1, -1 do
                local shell = latest_shell_queue[i]
                imgui.text(string.format("%d: Weapon ID %d, Shell ID %d", i, shell.weapon_id, shell.shell_id))
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Presets") then
            for preset_name, preset_config in spairs(preset_configs) do
                if imgui.tree_node(preset_name) then
                    local motion_configs = preset_config.motion_configs
                    changed, preset_config.enabled = imgui.checkbox("Enabled", preset_config.enabled)

                    if imgui.tree_node("Saved Motions") then
                        for key, motion_config in spairs(motion_configs) do
                            local motion_id_str = motion_config.name .. " (" .. key .. ")"
                            if imgui.tree_node(motion_id_str) then
                                changed, motion_config.enabled = imgui.checkbox("Enabled", motion_config.enabled)

                                segments_config_ui(motion_config.segments)

                                if imgui.button("Copy to Preview") then
                                    config.preview_segments = copy3(motion_config.segments)
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

                    if imgui.button("Save Preset") then
                        json.dump_file(preset_dir .. preset_name .. ".json", preset_config)
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

        if imgui.tree_node("Debug") then
            if imgui.tree_node("Caching Stats") then
                if imgui.tree_node("ShellList") then
                    for wp_type = 0, MAX_WP_TYPE do
                        local cache = weapon_caching[wp_type]
                        local status = cache.shell_list and string.format('%x', cache.shell_list:get_address()) or "nil"
                        imgui.text("Weapon Type " .. tostring(wp_type) .. ": " .. status)
                    end
                    imgui.tree_pop()
                end
                if imgui.tree_node("SoundShellListData") then
                    for wp_type = 0, MAX_WP_TYPE do
                        local cache = weapon_caching[wp_type]
                        local status = cache.sound_shell_list_data and string.format('%x', cache.sound_shell_list_data:get_address()) or "nil"
                        imgui.text("Weapon Type " .. tostring(wp_type) .. ": " .. status)
                    end
                    imgui.tree_pop()
                end
                if imgui.tree_node("EpvRef") then
                    for wp_type = 0, MAX_WP_TYPE do
                        local cache = weapon_caching[wp_type]
                        local status = cache.epvref and string.format('%x', cache.epvref:get_address()) or "nil"
                        imgui.text("Weapon Type " .. tostring(wp_type) .. ": " .. status)
                    end
                    imgui.tree_pop()
                end
                if imgui.tree_node("Sound Data Cache") then
                    for sound_id, sound_data in pairs(sound_caching_table) do
                        local status = sound_data and string.format('%x', sound_data:get_address()) or "nil"
                        imgui.text("Shell Name Hash " .. tostring(sound_id) .. ": " .. status)
                    end
                    imgui.tree_pop()
                end
                imgui.tree_pop()
            end

            if imgui.tree_node("Managed Shell") then
                for i, managed_shell in ipairs(mod_managed_shell) do
                    local shell = managed_shell.shell
                    local status = shell and string.format('%x', shell:get_address()) or "nil"
                    imgui.text(string.format("%d: %s", i, status))
                end
                imgui.tree_pop()
            end

            imgui.tree_pop()
        end

        if any_changed then
            load_preset_configs()
        end
        imgui.tree_pop()
    end
end)

register_frame_type("hunter", 
function(frame_args) 
    return get_hunter_transform()
end, 
function(frame_args)
    imgui.text("The initial transform of the shell is based on the hunter's transform.")
end,
function()
    return {}
end)

local function register_aim_frame_type()
    local function init_args()
        return {
            offset_to_hunter = { front = 0.0, right = 0.0, up = 0.0 },
        }
    end

    local function get_frame(args)
        local hunter_transform = get_hunter_transform()
        local start_pos = hunter_transform.position
            + hunter_transform.forward * args.offset_to_hunter.front
            + hunter_transform.right * args.offset_to_hunter.right
            + hunter_transform.up * args.offset_to_hunter.up
        local target_pos = get_camera_lookat_position()
        if not target_pos then return nil end
        local forward = (target_pos - start_pos):normalized()
        if forward:length() == 0 then
            forward = hunter_transform.forward
        end
        local right = nil
        if math.abs(forward:dot(Vector3f.new(0, 1, 0))) > 0.999 then
            right = hunter_transform.right
        else
            right = forward:cross(Vector3f.new(0, 1, 0)):normalized()
        end
        local up = right:cross(forward):normalized()
        local rotation = ax2quat(right * -1, up, forward)
        return { 
            position = start_pos, 
            rotation = rotation,
            forward = forward,
            right = right,
            up = up,
        }
    end

    local function ui(args)
        local changed = false
        imgui.text("The initial transform of the shell is based on the hunter's transform, aiming at the camera look-at position.")
        changed, args.offset_to_hunter.front = imgui.drag_float("Front", args.offset_to_hunter.front, 0.1, -100.0, 100.0, "%.2f")
        changed, args.offset_to_hunter.right = imgui.drag_float("Right", args.offset_to_hunter.right, 0.1, -100.0, 100.0, "%.2f")
        changed, args.offset_to_hunter.up = imgui.drag_float("Up", args.offset_to_hunter.up, 0.1, -100.0, 100.0, "%.2f")
    end

    register_frame_type("aim", get_frame, ui, init_args)
end
register_aim_frame_type()

local function register_sphere_line_helper()
    local private_args = {
        double_sided = false,
        num_shells = 5,
        center_offset = { front = 0.0, right = 0.0, up = 0.0 , yaw = 0.0, pitch = 0.0, roll = 0.0 },
        spread_radius = 0.0,
        offset_increment = { yaw = 0.0, pitch = 0.0, roll = 0.0 },
        delay_frames = 0.0,
        interval_frames = 0.0,
        overwrite_description = true,
    }

    local function set_args(args)
        merge_tables(private_args, args or {})
    end

    local function get_args()
        return copy3(private_args)
    end

    local function ui()
        local changed = false
        imgui.text("This helper arranges shells in a spherical line pattern.")
        imgui.text("Will duplicate the current shell args multiple times, changing their offsets and delay frames.")
        imgui.text("The original shell args will be removed.")
        imgui.text("")

        changed, private_args.double_sided = imgui.checkbox("Double Sided", private_args.double_sided)
        changed, private_args.num_shells = imgui.drag_int("Number of Shells", private_args.num_shells, 1, 1, 100)
        if imgui.tree_node("Center Offset") then
            changed, private_args.center_offset.front = imgui.drag_float("Front", private_args.center_offset.front, 0.1, -100.0, 100.0, "%.2f")
            changed, private_args.center_offset.right = imgui.drag_float("Right", private_args.center_offset.right, 0.1, -100.0, 100.0, "%.2f")
            changed, private_args.center_offset.up = imgui.drag_float("Up", private_args.center_offset.up, 0.1, -100.0, 100.0, "%.2f")
            changed, private_args.center_offset.yaw = imgui.drag_float("Yaw", private_args.center_offset.yaw, 1.0, -180.0, 180.0, "%.1f")
            changed, private_args.center_offset.pitch = imgui.drag_float("Pitch", private_args.center_offset.pitch, 1.0, -180.0, 180.0, "%.1f")
            changed, private_args.center_offset.roll = imgui.drag_float("Roll", private_args.center_offset.roll, 1.0, -180.0, 180.0, "%.1f")
            imgui.tree_pop()
        end
        changed, private_args.spread_radius = imgui.drag_float("Spread Radius", private_args.spread_radius, 0.1, 0.0, 100.0, "%.2f")
        if imgui.tree_node("Offset Increment") then
            changed, private_args.offset_increment.yaw = imgui.drag_float("Yaw", private_args.offset_increment.yaw, 1.0, -180.0, 180.0, "%.1f")
            changed, private_args.offset_increment.pitch = imgui.drag_float("Pitch", private_args.offset_increment.pitch, 1.0, -180.0, 180.0, "%.1f")
            changed, private_args.offset_increment.roll = imgui.drag_float("Roll", private_args.offset_increment.roll, 1.0, -180.0, 180.0, "%.1f")
            imgui.tree_pop()
        end
        changed, private_args.delay_frames = imgui.drag_float("Delay Frames", private_args.delay_frames, 0.1, 0.0, 300.0, "%.2f")
        changed, private_args.interval_frames = imgui.drag_float("Interval Frames", private_args.interval_frames, 0.1, 0.0, 300.0, "%.2f")
        changed, private_args.overwrite_description = imgui.checkbox("Overwrite Description", private_args.overwrite_description)
    end

    local function get_new_shoot_args(ref_shoot_args, center_pos, rot, delay_frame)
        local new_shoot_args = copy3(ref_shoot_args)
        local position = center_pos + ypr_degrees2direction(rot.x, rot.y, rot.z) * private_args.spread_radius
        new_shoot_args.offset.right = position.x
        new_shoot_args.offset.up = position.y
        new_shoot_args.offset.front = position.z
        new_shoot_args.offset.yaw = normalize_degrees(rot.x)
        new_shoot_args.offset.pitch = normalize_degrees(rot.y)
        new_shoot_args.offset.roll = normalize_degrees(rot.z)
        new_shoot_args.delay_frame = delay_frame
        return new_shoot_args
    end

    local function func(segment_config, shoot_args)
        local new_shoot_args_container = {}
        local center_pos = Vector3f.new(private_args.center_offset.right, private_args.center_offset.up, private_args.center_offset.front)
        local center_rot = Vector3f.new(private_args.center_offset.yaw, private_args.center_offset.pitch, private_args.center_offset.roll)
        local rot_increment = Vector3f.new(private_args.offset_increment.yaw, private_args.offset_increment.pitch, private_args.offset_increment.roll)
        if private_args.double_sided then
            if private_args.num_shells % 2 == 0 then
                local accumulated_rot_increment = rot_increment / 2.0
                for i = 1, private_args.num_shells / 2 do
                    local new_shoot_args1 = get_new_shoot_args(
                        shoot_args, center_pos, accumulated_rot_increment + center_rot, private_args.delay_frames + (i - 1) * private_args.interval_frames
                    )
                    table.insert(new_shoot_args_container, new_shoot_args1)
                    local new_shoot_args2 = get_new_shoot_args(
                        shoot_args, center_pos, -accumulated_rot_increment + center_rot, private_args.delay_frames + (i - 1) * private_args.interval_frames
                    )
                    table.insert(new_shoot_args_container, new_shoot_args2)
                    accumulated_rot_increment = accumulated_rot_increment + rot_increment
                end
            else
                local accumulated_rot_increment = Vector3f.new(0.0, 0.0, 0.0)
                local new_shoot_args0 = get_new_shoot_args(
                    shoot_args, center_pos, center_rot, private_args.delay_frames
                )
                table.insert(new_shoot_args_container, new_shoot_args0)
                for i = 1, (private_args.num_shells - 1) / 2 do
                    accumulated_rot_increment = accumulated_rot_increment + rot_increment
                    local new_shoot_args1 = get_new_shoot_args(
                        shoot_args, center_pos, accumulated_rot_increment + center_rot, private_args.delay_frames + i * private_args.interval_frames
                    )
                    table.insert(new_shoot_args_container, new_shoot_args1)
                    local new_shoot_args2 = get_new_shoot_args(
                        shoot_args, center_pos, center_rot - accumulated_rot_increment, private_args.delay_frames + i * private_args.interval_frames
                    )
                    table.insert(new_shoot_args_container, new_shoot_args2)
                end
            end
        else
            local accumulated_rot_increment = Vector3f.new(0.0, 0.0, 0.0)
            for i = 1, private_args.num_shells do
                local new_shoot_args = get_new_shoot_args(
                    shoot_args, center_pos, accumulated_rot_increment + center_rot, private_args.delay_frames + (i - 1) * private_args.interval_frames
                )
                table.insert(new_shoot_args_container, new_shoot_args)
                accumulated_rot_increment = accumulated_rot_increment + rot_increment
            end
        end

        if private_args.overwrite_description then
            segment_config.description = "Generated by Sphere Line Helper"
        end
        segment_config.shoot_args_container = new_shoot_args_container
    end

    register_segment_config_helper("Sphere Line", func, ui, set_args, get_args)
end
register_sphere_line_helper()

_PANDORA = {}
_PANDORA.get_empty_shoot_args = get_empty_shoot_args
_PANDORA.register_frame_type = register_frame_type
_PANDORA.register_shell = register_shell
_PANDORA.mgs_pulse_pool_batch_version = 1
_PANDORA.mgs_pulse_pool_batch_max = MAX_PULSE_POOL_BATCH
_PANDORA.mgs_pulse_update_queue_version = 1
_PANDORA.can_queue_pulses = can_queue_pulses
_PANDORA.cancel_pulse_batch = clear_pulses
_PANDORA.register_pulse_property_getter = function(getter)
    if type(getter)~='function' then return false end
    pulse_property_getter=getter
    return true
end
_PANDORA.get_pulse_health = function()
    local out={}
    for k,v in pairs(pulse_health) do out[k]=v end
    out.queued=#pulse_queue;out.queue_limit=MAX_PULSE_QUEUED
    out.update_ready=pulse_update_ready;out.fault=spawn_fault
    out.cooldown_remaining=math.max(0,pulse_retry_at-os.clock())
    out.active_spawn_contexts=0
    for _ in pairs(native_spawn_contexts) do out.active_spawn_contexts=out.active_spawn_contexts+1 end
    out.phase='UpdateBehavior';out.lua_pulse_shell_refs=0
    return out
end
_PANDORA.register_segment_config_helper = register_segment_config_helper
