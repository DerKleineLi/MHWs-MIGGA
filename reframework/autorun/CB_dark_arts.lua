-- config
local config_file_path = "CB_dark_arts.json"
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
    enabled = true,
    check_for_skill = true,
    amount = 5,
    spread = 168.75,
    motion_value = 20.0,
    attribute_value = 40.0,
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file(config_file_path, config)
    end
)

-- helper functions
local function quat_multiply(q1, q2)
    local x1, y1, z1, w1 = q1.x, q1.y, q1.z, q1.w
    local x2, y2, z2, w2 = q2.x, q2.y, q2.z, q2.w

    return Vector4f.new(
        w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
        w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
        w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
        w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2
    )
end

local function ypr_degrees2quat(yaw, pitch, roll)
    -- Remap inputs: keep original formula
    -- X = Right = roll
    -- Y = Up = yaw
    -- Z = Forward = pitch
    local x = roll
    local y = yaw
    local z = pitch

    -- Convert degrees to radians
    x = math.rad(x)
    y = math.rad(y)
    z = math.rad(z)

    local cx = math.cos(x * 0.5)
    local sx = math.sin(x * 0.5)
    local cy = math.cos(y * 0.5)
    local sy = math.sin(y * 0.5)
    local cz = math.cos(z * 0.5)
    local sz = math.sin(z * 0.5)

    return Vector4f.new(
        sx * cy * cz - cx * sy * sz,
        cx * sy * cz + sx * cy * sz,
        cx * cy * sz - sx * sy * cz,
        cx * cy * cz + sx * sy * sz
    )
end

local function rotate_quaternion_by_ypr_degrees(q, yaw, pitch, roll)
    local rot = ypr_degrees2quat(yaw, pitch, roll)
    return quat_multiply(rot, q)
end

local function constructor(type_name) -- from EMV Engine
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
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_character = player_info:get_Character()
    return hunter_character
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

local function get_hunter_transform()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_object = player_info:get_Object()
    if not hunter_object then return nil end
    local hunter_transform = hunter_object:get_Transform()
    if not hunter_transform then return nil end
    local output = {}
    output.transform = hunter_transform
    output.position = hunter_transform:get_Position()
    output.rotation = hunter_transform:get_Rotation()
    output.scale = hunter_transform:get_Scale()
    output.forward = hunter_transform:get_AxisZ()
    output.right = hunter_transform:get_AxisX()
    output.up = hunter_transform:get_AxisY()
    return output
end

local function get_shell_list(wp_type)
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local catalog = player_manager:get_Catalog()
    if not catalog then return nil end
    local wp_assets = catalog:getWeaponEquipUseAssets(wp_type)
    if not wp_assets then return nil end
    return wp_assets:get_ShellList()
end

local function get_effect()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local player_object = player_info:get_Object()
    if not player_object then return nil end
    return player_object:getComponent(sdk.typeof("via.effect.script.ObjectEffectManager2"))
end

local function get_sound_data()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local player_object = player_info:get_Object()
    if not player_object then return nil end
    return player_object:getComponent(sdk.typeof("app.SoundRegisterMyContainerAndData"))
end

local function get_motion(layer_id) -- credits to lingsamuel
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

local function get_skill_activate(skill_id)
    local hunter = get_hunter()
    if not hunter then return nil end
    local hunter_skill = hunter:get_HunterSkill()
    if not hunter_skill then return nil end
    return hunter_skill:checkSkillActive(skill_id)
end

-- core
local SOUND_DATA_ID = 1999283982
local TARGET_WP_TYPE = 0 -- GS
local APPLIED_WP_TYPE = 9 -- CB
local APPLIED_MOTION_ID = 519 -- SAED
local APPLIED_MOTION_BANK_ID = 20
local DARK_ARTS_SKILL_ID = 241
local DARK_ARTS_FRAME = 120
local OFFSET_FRONT = 2.5
local OFFSET_RIGHT = 0.0
local OFFSET_UP = 2.0
local INNER_RADIUS = 0.25

-- init cache
local sound_data_list_cache = nil
local shell_list_cache = nil
local cache_task_submitted = false

local function cache_func()
    if not sound_data_list_cache then 
        local wp = get_wp()
        if not wp then return false end
        local shell_create_controller = wp._ShellCreateController
        if not shell_create_controller then return false end
        local sound_container = shell_create_controller:get_ShellOwner():getComponent(sdk.typeof("soundlib.SoundContainer"))
        if not sound_container then return false end
        local sound_data_list = sound_container:findShellData(SOUND_DATA_ID)
        if not sound_data_list then return false end
        sound_data_list_cache = sound_data_list:MemberwiseClone()
        if sound_data_list_cache then 
            sound_data_list_cache:add_ref_permanent()
        end
    end

    if not shell_list_cache then 
        shell_list_cache = get_shell_list(0)
        if shell_list_cache then 
            shell_list_cache:add_ref_permanent()
        end
    end

    return sound_data_list_cache ~= nil and shell_list_cache ~= nil
end

-- wait until _WEAPON_CACHING is loaded
if _WEAPON_CACHING then
    _WEAPON_CACHING.register_cache_task(TARGET_WP_TYPE, cache_func)
    cache_task_submitted = true
else
    re.on_frame(function()
        if not cache_task_submitted and _WEAPON_CACHING then
            _WEAPON_CACHING.register_cache_task(TARGET_WP_TYPE, cache_func)
            cache_task_submitted = true
        end
    end)
end


-- fix sound
-- soundlib.SoundContainer.findShellData(System.UInt32)
local target_sound_id_cache = nil
sdk.hook(sdk.find_type_definition("soundlib.SoundContainer"):get_method("findShellData(System.UInt32)"),
    function(args)
        local this = sdk.to_managed_object(args[2])
        local target_sound_id = sdk.to_int64(args[3]) & 0xFFFFFFFF
        target_sound_id_cache = target_sound_id
    end,
    function(retval)
        if target_sound_id_cache == SOUND_DATA_ID and sound_data_list_cache then
            return sdk.to_ptr(sound_data_list_cache)
        end
        return retval
    end
)

local function shoot(offset_front, offset_right, offset_up, yaw, pitch, roll)
    -- create shell shooting info
    local shellShootingInfo = constructor("app.cShellShootingInfo")
    if not shellShootingInfo then return end

    local hunter_tf = get_hunter_transform()
    local target_pos = hunter_tf.position + (hunter_tf.forward * (offset_front or 0)) + (hunter_tf.right * (offset_right or 0)) + (hunter_tf.up * (offset_up or 0))
    local target_rot = rotate_quaternion_by_ypr_degrees(hunter_tf.rotation, yaw or 0, pitch or 0, roll or 0)

    local start_pos = shellShootingInfo:get_field("<StartPos>k__BackingField")
    start_pos:set_field("_HasValue", true)
    start_pos:set_field("_Value", target_pos)
    shellShootingInfo:set_field("<StartPos>k__BackingField", start_pos)

    local start_rot = shellShootingInfo:get_field("<StartRot>k__BackingField")
    start_rot:set_field("_HasValue", true)
    start_rot:set_field("_Value", target_rot)
    shellShootingInfo:set_field("<StartRot>k__BackingField", start_rot)

    -- get shell controller and current data
    local wp = get_wp()
    if not wp then return end
    local wp_type = get_wp_type()
    if not wp_type or wp_type == -1 then return end
    local shell_create_controller = wp._ShellCreateController
    if not shell_create_controller then return end
    local current_shell_list = get_shell_list(wp_type)
    if not current_shell_list then return end
    
    -- replace shell list
    if not shell_list_cache then return end
    shell_create_controller:setup(shell_create_controller:get_ShellOwner(), shell_list_cache)
    
    -- shoot shell
    shell_create_controller:shootShell(1, shellShootingInfo, nil)

    -- restore
    shell_create_controller:setup(shell_create_controller:get_ShellOwner(), current_shell_list)
end

function shoot_shells(offset_front, offset_right, offset_up, amount, spread, inner_radius)
    amount = math.max(1, amount or 1)
    spread = spread or 0
    if spread < 0 then spread = 0 elseif spread > 360 then spread = 360 end
    inner_radius = inner_radius or 0

    -- Each shell sits at the **center** of its segment within [-spread/2, +spread/2]
    local segment = spread / amount

    for i = 1, amount do
        local yawDeg = -spread * 0.5 + (i - 0.5) * segment
        local pitchDeg = 0
        local rollDeg = 0

        -- Convert to radians
        local yawRad = math.rad(yawDeg)

        -- Direction vector in local (front-right-up) basis
        local dir_front = math.cos(yawRad)
        local dir_right = math.sin(yawRad)
        local dir_up    = 0

        -- Push the shell's starting offset outward by inner_radius
        local shell_front = offset_front + dir_front * inner_radius
        local shell_right = offset_right + dir_right * inner_radius
        local shell_up    = offset_up + dir_up * inner_radius

        -- log.debug(string.format("Shooting shell %d/%d: yaw=%.1f, pitch=%.1f, roll=%.1f, pos=(%.2f, %.2f, %.2f)", i, amount, yawDeg, pitchDeg, rollDeg, shell_front, shell_right, shell_up))

        shoot(shell_front, shell_right, shell_up, yawDeg, pitchDeg, rollDeg)
    end
end

local last_frame = 0
re.on_application_entry("UpdateMotionFrame", function()
    if not config.enabled then return end
    if config.check_for_skill and not get_skill_activate(DARK_ARTS_SKILL_ID) then return end

    local motion = get_motion()
    if not motion then return end
    if motion.MotionID ~= APPLIED_MOTION_ID or motion.MotionBankID ~= APPLIED_MOTION_BANK_ID then
        return
    end
    
    if last_frame < DARK_ARTS_FRAME and motion.Frame >= DARK_ARTS_FRAME then
        shoot_shells(OFFSET_FRONT, OFFSET_RIGHT, OFFSET_UP, config.amount, config.spread, INNER_RADIUS)
    end

    last_frame = motion.Frame
end)

-- change motion value
local function get_key(hit_data)
    return string.format("%s_%s_%d", tostring(hit_data.weapon_type), hit_data.attack_owner_name, hit_data.attack_index)
end
local TARGET_KEY = "-1_Wp00Shell_1"

local attack_data_cache = nil
sdk.hook(sdk.find_type_definition("app.mcShellColHit"):get_method("evAttackPreProcess(app.HitInfo)"),
function(args)
    attack_data_cache = nil
    local current_wp_type = get_wp_type()
    if current_wp_type ~= APPLIED_WP_TYPE then return end
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local owner = this:get_Owner()
    if not owner then return end

    -- get root owner, credits to kmyx
    local shell_base = owner:call("getComponent(System.Type)", sdk.typeof("ace.ShellBase"))
    -- if not shell_base then return end
    ---@cast shell_base ace.ShellBase
    local shell_owner = shell_base:get_ShellOwner()
    local shell_transform = shell_owner:get_Transform()

    for _ = 1, 100 do
        local parent = shell_transform:get_Parent()
        if parent then
            shell_transform = parent
        else
            break
        end
    end

    local actual_owner = shell_transform:get_GameObject()
    if not actual_owner then return end
    if actual_owner:get_Name() ~= "MasterPlayer" then return end

    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end
    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    if not attack_data then return end
    
    local weapon_type = attack_data._WeaponType

    local hit_data = {
        weapon_type = weapon_type,
        attack_index = hit_info:get_field("<AttackIndex>k__BackingField")._Index,
        attack_owner_name = hit_info:get_field("<AttackOwner>k__BackingField"):get_Name(),
        attack_owner_tag = hit_info:get_field("<AttackOwner>k__BackingField"):get_Tag(),
        attack_name = attack_data:get_field("_UserData"):get_Name(),
    }
    local key = get_key(hit_data)
    if key ~= TARGET_KEY then return end
    attack_data_cache = attack_data

end, function(retval)
    -- change motion value in post hook to overwrite MV_manager's possible changes
    if attack_data_cache then
        attack_data_cache:set_field("_Attack", config.motion_value)
        attack_data_cache:set_field("_AttrValue", config.attribute_value)
        attack_data_cache = nil
    end
    return retval
end)

-- UI
re.on_draw_ui(function()
    local changed, any_changed = false, false
    
    if imgui.tree_node("Charge Blade Dark Arts") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)
        changed, config.check_for_skill = imgui.checkbox("Check for Dark Arts Skill", config.check_for_skill)
        changed, config.amount = imgui.drag_int("Amount", config.amount, 1, 1, 10, "%d")
        changed, config.spread = imgui.drag_float("Spread in degrees", config.spread, 0.1, 0.0, 360.0, "%.2f")
        changed, config.motion_value = imgui.drag_float("Motion Value, defaults to 20", config.motion_value, 0.01, 0.0, 1000.0, "%.2f")
        changed, config.attribute_value = imgui.drag_float("Dragon Attribute Value, defaults to 40", config.attribute_value, 0.01, 0.0, 1000.0, "%.2f")

        imgui.tree_pop()
    end
end)