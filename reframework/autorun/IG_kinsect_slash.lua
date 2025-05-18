-- config
local function merge_tables(t1, t2)
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return
    end
    for k, v in pairs(t2) do
        if t1[k] ~= nil then
            if type(t1[k]) == "table" and type(v) == "table" then
                merge_tables(t1[k], v)
            else
                t1[k] = v
            end
        end
    end
end

local saved_config = json.load_file("IG_kinsect_slash.json") or {}

local config = {
    enabled = true,
    recall_kinsect_tripple_up = true,
    recall_kinsect_no_tripple_up = true,
    enemy_step_direction_fix = true,
    fall_direction_fix = true,
    trigger_on_everything = false,
    unlimited_jump = false,
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("IG_kinsect_slash.json", config)
    end
)

-- helper functions
function contains_token(haystack, needle)
    local needle_lower = needle:lower()
    for token in string.gmatch(haystack, "[^|]+") do
        if token:lower() == needle_lower then
            return true
        end
    end
    return false
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
    local wp = hunter:get_WeaponHandling()
    return wp
end

local function get_kinsect()
    local hunter = get_hunter()
    if not hunter then return nil end
    local kinsect = hunter:get_Wp10Insect()
    return kinsect
end

local function change_action(layer, category, index)
    local hunter = get_hunter()
    if not hunter then return end
    local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
    local instance = ValueType.new(ActionIDType)
    sdk.set_native_field(instance, ActionIDType, "_Category", category)
    sdk.set_native_field(instance, ActionIDType, "_Index", index)
    hunter:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", layer, instance, true)
end

local function change_kinsect_action(category, index)
    local kinsect = get_kinsect()
    if not kinsect then return end
    local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")
    local instance = ValueType.new(ActionIDType)
    sdk.set_native_field(instance, ActionIDType, "_Category", category)
    sdk.set_native_field(instance, ActionIDType, "_Index", index)
    kinsect:call("requestChangeAction(ace.ACTION_ID, System.Boolean)", instance, true)
end

local function get_input()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_controller = player_info:get_Controller()
    if not hunter_controller then return nil end
    local hunter_controller_entity_holder = hunter_controller:get_ControllerEntityHolder()
    if not hunter_controller_entity_holder then return nil end
    local master_player_controler_entity = hunter_controller_entity_holder:get_Master()
    if not master_player_controler_entity then return nil end
    local command_controller = master_player_controler_entity:get_CommandController()
    if not command_controller then return nil end
    local player_game_input_base = command_controller:get_MergedVirtualInput()
    return player_game_input_base
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
        EndFrame = layer:get_EndFrame(),
    }

    return result
end

local function change_motion(MotionBankID, MotionID, StartFrame, InterpolationFrame, InterpolationMode, InterpolationCurve, layer_id)
    StartFrame = StartFrame or 0
    InterpolationFrame = InterpolationFrame or 0
    InterpolationMode = InterpolationMode or 0
    InterpolationCurve = InterpolationCurve or 0
    layer_id = layer_id or 0
    local motion = get_motion(layer_id)
    motion.Layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
        MotionBankID, MotionID, StartFrame * 1.0, InterpolationFrame * 1.0, InterpolationMode, InterpolationCurve
    )
end

local function get_input_dir()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local player_context_holder = player_info:get_ContextHolder()
    if not player_context_holder then return nil end
    local hunter_context = player_context_holder:get_Hunter()
    if not hunter_context then return nil end
    local hunter_action_arg = hunter_context:get_ActionArg()
    if not hunter_action_arg then return nil end

    local output = {}
    output.camera_lookat_dir = hunter_action_arg:get_CameraLookAtDir()
    local camera_front_dir = Vector3f.new(output.camera_lookat_dir.x, 0, output.camera_lookat_dir.z)
    camera_front_dir:normalize()
    output.camera_front_dir = camera_front_dir
    output.xz_len = output.camera_lookat_dir:dot(camera_front_dir)
    output.is_aim = hunter_action_arg:get_IsAim()
    return output
end

-- global variables
_OMNIMOVE_GLOBAL_SEGMENT_CONFIG = _OMNIMOVE_GLOBAL_SEGMENT_CONFIG or {}
local omnimove_disabled = false

local in_thrust = false
local in_kinsect_slash_jump = false
local in_kinsect_slash_fall = 0
local fall_dir = {0.0, 0.0, 0.0}
local fall_fade_frame = 0

local should_jump = false

local should_kinsect_out = false
local kinsect_out = false
local kinsect_pre_recall = false

local R1_released = false


-- get key state
local key_R1_down = false
-- app.cPlayerCommandController.update
sdk.hook(sdk.find_type_definition("app.cPlayerCommandController"):get_method("update"), nil, 
function(retval)
    local player_input = get_input()
    if not player_input then return end
    local key_idx = 3 -- R1
    local key = player_input:getKey(key_idx)
    key_R1_down = key:get_On()
    return retval
end)

re.on_frame(function()
    if not config.enabled then return end
    local motion = get_motion()
    if not motion then return end
    local Wp10Handling = get_wp()
    if not Wp10Handling then return end
    local kinsect = get_kinsect()
    if not kinsect then return end
    
    in_thrust = motion.MotionBankID == 20 and motion.MotionID == 466
    in_kinsect_slash_jump = in_kinsect_slash_jump and motion.MotionBankID == 20 and motion.MotionID == 193
    if not (motion.MotionBankID == 20 and motion.MotionID == 190) then
        in_kinsect_slash_fall = 0
    end
    local kinsect_on_arm = kinsect:get_field("<IsArmConst>k__BackingField")
    should_jump = should_jump and in_thrust and (config.unlimited_jump or Wp10Handling:checkEnableEnemyStepCount())
    R1_released = (R1_released or (not key_R1_down)) and in_thrust

    if should_jump then
        if R1_released and not in_kinsect_slash_jump then
            change_action(0, 2, 53) -- step
            in_thrust = false
            in_kinsect_slash_jump = true
            in_kinsect_slash_fall = 0
            should_jump = false
        end
    end

    if should_kinsect_out then
        if kinsect_on_arm then
            change_kinsect_action(0, 20) -- send out
            kinsect_out = true
            should_kinsect_out = false
            kinsect_pre_recall = false
        elseif not kinsect_pre_recall then
            local is_tripple_up = Wp10Handling:get_IsTrippleUp()
            local recall_kinsect = config.recall_kinsect_tripple_up and is_tripple_up or config.recall_kinsect_no_tripple_up and not is_tripple_up
            if recall_kinsect then
                change_kinsect_action(0, 17) -- call back
                kinsect_pre_recall = true
            else
                should_kinsect_out = false
            end
        end
    end

    if motion.Frame > motion.EndFrame - 2 then
        if in_thrust and R1_released then
            change_motion(20, 190, 0, 20, 2, 1) -- kinsect slash fall
            in_kinsect_slash_fall = 1
            in_kinsect_slash_jump = false
            in_thrust = false
            local input_dir = get_input_dir()
            fall_dir = {0.0, input_dir.camera_lookat_dir.y, input_dir.xz_len}
            fall_fade_frame = (1 - input_dir.camera_lookat_dir.y) * 90 + 30
        elseif in_kinsect_slash_fall > 0 then
            change_motion(20, 190, 0, 20, 2, 1) -- kinsect slash fall
            in_kinsect_slash_fall = in_kinsect_slash_fall + 1
            in_kinsect_slash_jump = false
            in_thrust = false
        end
    end

    local omnimove_enabled_this_frame = false
    if in_thrust then
        local input_dir = get_input_dir()
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG = _OMNIMOVE_GLOBAL_SEGMENT_CONFIG or {}
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.enabled = true
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.speed_type = 3 -- 1: LStick, 2: LStick Trigger, 3: Fixed
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.direction_type = 6 -- 1: Omni, 2: Aligned, 3: Camera, 4: Camera3D_Omni, 5: Camera3D_Aligned, 6: Hunter
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.speed = 10.0
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.end_frame = 1000
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.start_frame = 0
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.direction_vector = {0.0, input_dir.camera_lookat_dir.y, input_dir.xz_len}
        omnimove_disabled = false
        omnimove_enabled_this_frame = true
    end
    if in_kinsect_slash_jump and config.enemy_step_direction_fix then
        local y_speed = 8.0 * (1 - motion.Frame / 120)
        local xz_speed = 10.0 * (1 - motion.Frame / 55)
        y_speed = y_speed > 0 and y_speed or 0
        xz_speed = xz_speed > 0 and xz_speed or 0
        local speed = math.sqrt(xz_speed * xz_speed + y_speed * y_speed)

        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG = _OMNIMOVE_GLOBAL_SEGMENT_CONFIG or {}
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.enabled = true
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.speed_type = 3 -- 1: LStick, 2: LStick Trigger, 3: Fixed
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.direction_type = 6 -- 1: Omni, 2: Aligned, 3: Camera, 4: Camera3D_Omni, 5: Camera3D_Aligned, 6: Hunter
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.speed = speed
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.end_frame = 120
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.start_frame = 15
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.direction_vector = {0.0, -y_speed, -xz_speed}
        omnimove_disabled = false
        omnimove_enabled_this_frame = true
    end
    if in_kinsect_slash_fall > 0 and config.fall_direction_fix then
        local eq_frame = (in_kinsect_slash_fall - 1) * (motion.EndFrame - 2) + motion.Frame
        local speed = 10.0 * (1 - eq_frame / fall_fade_frame)
        speed = speed > 0 and speed or 0

        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG = _OMNIMOVE_GLOBAL_SEGMENT_CONFIG or {}
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.enabled = true
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.speed_type = 3 -- 1: LStick, 2: LStick Trigger, 3: Fixed
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.direction_type = 6 -- 1: Omni, 2: Aligned, 3: Camera, 4: Camera3D_Omni, 5: Camera3D_Aligned, 6: Hunter
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.speed = speed
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.end_frame = 1000
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.start_frame = 0
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.direction_vector = fall_dir
        omnimove_disabled = false
        omnimove_enabled_this_frame = true
    end

    if not omnimove_disabled and not omnimove_enabled_this_frame then
        _OMNIMOVE_GLOBAL_SEGMENT_CONFIG.enabled = false
        omnimove_disabled = true
    end
end)

-- app.cHunterWp10Handling.doOnHit_AttackPre(app.HitInfo, System.Boolean, System.Boolean)
sdk.hook(sdk.find_type_definition("app.cHunterWp10Handling"):get_method("doOnHit_AttackPre(app.HitInfo, System.Boolean, System.Boolean)"), function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end
    local damage_owner = hit_info:get_field("<DamageOwner>k__BackingField")
    local damage_owner_tag = damage_owner:get_Tag()
    local is_shell = contains_token(damage_owner_tag, "Shell")
    local is_enemy = contains_token(damage_owner_tag, "Enemy")

    should_jump = in_thrust and (config.trigger_on_everything or (not is_shell and is_enemy))
    should_kinsect_out = should_jump
    if should_kinsect_out then
        kinsect_pre_recall = false
    end
end)



-- app.Wp10Insect.evAttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("evAttackPreProcess(app.HitInfo)"), 
function(args)
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    if kinsect_out then
        change_kinsect_action(0, 17) -- call back
        kinsect_out = false
    end
end)


re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Insect Glaive Kinsect Slash") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)
        changed, config.recall_kinsect_tripple_up = imgui.checkbox("Recall Kinsect Tripple Up", config.recall_kinsect_tripple_up)
        changed, config.recall_kinsect_no_tripple_up = imgui.checkbox("Recall Kinsect No Tripple Up", config.recall_kinsect_no_tripple_up)
        changed, config.enemy_step_direction_fix = imgui.checkbox("Enemy Step Direction Fix", config.enemy_step_direction_fix)
        changed, config.fall_direction_fix = imgui.checkbox("Fall Direction Fix", config.fall_direction_fix)
        changed, config.trigger_on_everything = imgui.checkbox("Trigger on Everything", config.trigger_on_everything)
        changed, config.unlimited_jump = imgui.checkbox("Unlimited Jump", config.unlimited_jump)
        imgui.tree_pop()
    end
end)