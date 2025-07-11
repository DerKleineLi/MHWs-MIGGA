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

local saved_config = json.load_file("IG_better_stab.json") or {}

local config = {
    charge_stab_double_stab = true,
    always_left_double_stab = true,
    combo2_charge_stab = false,
    hotkey_left_double_stab = true,
    combo1_no_charge = false,
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("IG_better_stab.json", config)
    end
)

-- helper functions
local function rotate(x, y, angle)
    local cos_theta = math.cos(angle)
    local sin_theta = math.sin(angle)
    return x * cos_theta - y * sin_theta, x * sin_theta + y * cos_theta
end

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

local function get_wp()
    local hunter = get_hunter()
    if not hunter then return nil end
    local wp = hunter:get_WeaponHandling()
    return wp
end

local function get_motion_data() -- credits to lingsamuel
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return 0 end
    local player_object = player_info:get_Object()
    if not player_object then return 0 end
    local motion = player_object:getComponent(sdk.typeof("via.motion.Motion"))
    if not motion then return 0 end
    local layer = motion:getLayer(0)
    if not layer then return 0 end

    local nodeCount = layer:getMotionNodeCount()
    local result = {
        Layer = layer,
        MotionID = layer:get_MotionID(),
        MotionBankID = layer:get_MotionBankID(),
        Frame = layer:get_Frame(),
    }

    return result
end

local function get_merged_input()
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

local function get_input()
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
    -- local player_command_result = hunter_context:get_CommandResult()
    -- if not player_command_result then return nil end

    local gamepad = sdk.get_native_singleton("via.hid.GamePad")
    local gamepad_type = sdk.find_type_definition("via.hid.GamePad")
    local gamepad_device = sdk.call_native_func(gamepad, gamepad_type, "get_MergedDevice")
    if not gamepad_device then return nil end

    local keyboard = sdk.get_native_singleton("via.hid.Keyboard")
    local keyboard_type = sdk.find_type_definition("via.hid.Keyboard")
    local keyboard_device = sdk.call_native_func(keyboard, keyboard_type, "get_MergedDevice")
    if not keyboard_device then return nil end

    local output = {}
    output.is_enable_start_input_world_dir = hunter_action_arg:get_IsEnableStartInputWorldDir()
    output.start_input_world_dir = hunter_action_arg:get_StartInputWorldDir()
    output.is_aim = hunter_action_arg:get_IsAim()
    output.camera_lookat_dir = hunter_action_arg:get_CameraLookAtDir()
    
    -- output.is_enable_input_world_dir = hunter_action_arg:get_IsEnableInputWorldDir()
    -- output.input_world_dir = hunter_action_arg:get_InputWorldDir()
    -- output.lstick = player_command_result:get_LStick() -- in some actions the Lstick is disabled, so use the homemade virtual lstick instead
    -- output.lstick_magnitude = player_command_result:get_LStickMagnitude()
    -- output.is_enable_lstick = player_command_result:get_IsEnableLStick()

    output.gamepad_raw_lstick = gamepad_device:get_RawAxisL()
    output.gamepad_lstick = gamepad_device:get_AxisL()
    output.W_down = keyboard_device:isDown(87) -- W key
    output.A_down = keyboard_device:isDown(65) -- A key
    output.S_down = keyboard_device:isDown(83) -- S key
    output.D_down = keyboard_device:isDown(68) -- D key

    -- virtual lstick
    local virtual_lstick = Vector2f.new(0.0, 0.0)
    if output.gamepad_lstick.x ~= 0 or output.gamepad_lstick.y ~= 0 then
        virtual_lstick = output.gamepad_lstick
    else
        if output.W_down then
            virtual_lstick.y = virtual_lstick.y + 1.0
        end
        if output.A_down then
            virtual_lstick.x = virtual_lstick.x - 1.0
        end
        if output.S_down then
            virtual_lstick.y = virtual_lstick.y - 1.0
        end
        if output.D_down then
            virtual_lstick.x = virtual_lstick.x + 1.0
        end
        if virtual_lstick:length() > 0 then
            virtual_lstick:normalize()
        end
    end
    output.virtual_lstick = virtual_lstick
    output.virtual_lstick_magnitude = virtual_lstick:length()

    local camera_front_dir = Vector3f.new(output.camera_lookat_dir.x, 0, output.camera_lookat_dir.z)
    camera_front_dir:normalize()
    output.camera_front_dir = camera_front_dir

    local virtual_input_world_x, virtual_input_world_z = 0.0, 0.0
    if virtual_lstick:length() > 0 then
        virtual_input_world_x, virtual_input_world_z = rotate(camera_front_dir.x, camera_front_dir.z, math.atan(virtual_lstick.x, virtual_lstick.y))
    end
    output.virtual_input_world_dir = Vector3f.new(virtual_input_world_x, 0, virtual_input_world_z)

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

local DIR_STATE = {
    C = 0,
    L = 1,
    R = 2,
    U = 3,
    D = 4,
}

local xy_queue = {}
local world_dir_queue = {}
local max_queue_size = 10
local time_threshold = 0.5

function determine_direction(x_ref, z_ref, x_input, z_input)
    -- Normalize input vectors just in case
    local ref_length = math.sqrt(x_ref * x_ref + z_ref * z_ref)
    local input_length = math.sqrt(x_input * x_input + z_input * z_input)
    
    if ref_length == 0 or input_length == 0 then
        return "undetermined"
    end

    x_ref = x_ref / ref_length
    z_ref = z_ref / ref_length
    x_input = x_input / input_length
    z_input = z_input / input_length

    -- Dot and cross product
    local dot = x_ref * x_input + z_ref * z_input
    local cross = x_ref * z_input - z_ref * x_input

    -- Calculate signed angle in radians
    local angle = math.atan(cross, dot)  -- returns value between -pi and pi

    -- Convert to degrees
    local deg = math.deg(angle)

    -- Normalize angle to [-180, 180]
    if deg > 180 then deg = deg - 360 end
    if deg < -180 then deg = deg + 360 end

    -- Determine region
    if deg >= -45 and deg < 45 then
        return DIR_STATE.U
    elseif deg >= 45 and deg < 135 then
        return DIR_STATE.R
    elseif deg >= -135 and deg < -45 then
        return DIR_STATE.L
    else
        return DIR_STATE.D
    end
end

local function hotkey_maintainer()
    local input = get_input()
    if not input then return end
    -- xy_queue
    local last_xy = xy_queue[#xy_queue]
    local last_xy_state = last_xy and last_xy.state or nil
    local new_xy_state = nil
    local x, y = input.virtual_lstick.x, input.virtual_lstick.y
    if input.virtual_lstick_magnitude < 0.5 then
        new_xy_state = DIR_STATE.C
    elseif x > 0 and x > math.abs(y) then
        new_xy_state = DIR_STATE.R
    elseif x < 0 and math.abs(x) > y then
        new_xy_state = DIR_STATE.L
    elseif y > 0 and y > math.abs(x) then
        new_xy_state = DIR_STATE.U
    elseif y < 0 and math.abs(y) > x then
        new_xy_state = DIR_STATE.D
    end
    if new_xy_state then
        if new_xy_state ~= last_xy_state then
            table.insert(xy_queue, {state = new_xy_state, time = os.clock()})
        else
            -- last_xy.time = os.clock()
        end
    end
    if #xy_queue > max_queue_size then
        table.remove(xy_queue, 1)
    end
    -- world_dir_queue
    local last_world_dir = world_dir_queue[#world_dir_queue]
    local last_world_dir_state = last_world_dir and last_world_dir.state or nil
    local new_world_dir_state = nil
    local ref_dir = get_hunter_transform().forward
    local input_dir = input.virtual_input_world_dir
    if input.virtual_lstick_magnitude < 0.5 then
        new_world_dir_state = DIR_STATE.C
    else
        local ref_x, ref_z = ref_dir.x, ref_dir.z
        local input_x, input_z = input_dir.x, input_dir.z
        new_world_dir_state = determine_direction(ref_x, ref_z, input_x, input_z)
    end
    if new_world_dir_state then
        if new_world_dir_state ~= last_world_dir_state then
            table.insert(world_dir_queue, {state = new_world_dir_state, time = os.clock()})
        else
            -- last_world_dir.time = os.clock()
        end
    end
    if #world_dir_queue > max_queue_size then
        table.remove(world_dir_queue, 1)
    end
end

local function get_is_back_forward()
    local input = get_input()
    if not input then return false end
    local stack_to_check = nil
    if input.is_aim then
        stack_to_check = xy_queue
    else
        stack_to_check = world_dir_queue
    end
    if #stack_to_check == 0 then return false end
    local found_forward = false
    for i = #stack_to_check, 1, -1 do
        local state = stack_to_check[i].state
        if state == DIR_STATE.L or state == DIR_STATE.R then
            if found_forward then
                goto continue
            else
                return false
            end
        elseif state == DIR_STATE.U then
            found_forward = true
        elseif state == DIR_STATE.D then
            if found_forward then
                local time_diff = os.clock() - stack_to_check[i].time
                if time_diff < time_threshold then
                    return true
                else
                    return false
                end
            end
        end
        ::continue::
    end
    return false
end


-- Global vars
local MotionStage = {
    None = 0,
    InTriggeredLeftDoubleStab = 1,
}
local motion_stage = MotionStage.None
local last_triangle_is_back_forward = false

-- app.cPlayerCommandController.update
sdk.hook(sdk.find_type_definition("app.cPlayerCommandController"):get_method("update"), nil, 
function(retval)
    local player_input = get_merged_input()
    if not player_input then return end
    local key_idx = 0 -- triangle
    local key = player_input:getKey(key_idx)
    local on_trigger = key:get_OnTrigger()
    if on_trigger then
        last_triangle_is_back_forward = get_is_back_forward()
    end

    return retval
end)

-- app.Wp10Action.cWp10BatonAttackBase.doEnter()
local should_left_double_stab = false
local target_attacks = {
    "app.Wp10Action.cBatonUSlash", 
    "app.Wp10Action.cBatonUSlashSuper",
    "app.Wp10Action.cBatonVSlash",
    "app.Wp10Action.cBatonVSlashSuper",
}
sdk.hook(sdk.find_type_definition("app.Wp10Action.cWp10BatonAttackBase"):get_method("doEnter()"),
function(args)
    should_left_double_stab = false
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    local this_type = this:get_type_definition()
    local this_type_name = this_type:get_full_name()
    local is_target_attack = false
    for _, target_attack in ipairs(target_attacks) do
        if this_type_name == target_attack then
            is_target_attack = true
            break
        end
    end
    local is_combo1_charge_no_aim = this_type_name == "app.Wp10Action.cBatonMoveAttackNoCombo"
    -- log.debug("doEnter() called on: " .. this_type_name)

    should_left_double_stab = config.hotkey_left_double_stab and last_triangle_is_back_forward and is_target_attack
    should_left_double_stab = should_left_double_stab or (config.combo1_no_charge and is_combo1_charge_no_aim)

end,
function(retval)
    if should_left_double_stab then
        local motion_data = get_motion_data()
        local layer = motion_data.Layer
        layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
            20, 278, 0.0, 10.0, 1, 0) -- left double
        motion_stage = MotionStage.InTriggeredLeftDoubleStab
    end

    return retval
end)

-- app.Wp10Action.cBatonMoveAttack.doEnter()
local slash_dir = nil
local combo_stage = nil
sdk.hook(sdk.find_type_definition("app.Wp10Action.cBatonMoveAttack"):get_method("doEnter()"),
function(args)
    slash_dir = -1
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Chara()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    slash_dir = this:judgeSlashDir()
    local this_type = this:get_type_definition()
    local this_type_name = this_type:get_full_name()
    -- log.debug("doEnter() called on: " .. this_type_name)
    combo_stage = this_type_name == "app.Wp10Action.cBatonMoveAttack2" and 2 or 1

    if slash_dir == 0 and config.combo2_charge_stab then
        local motion_data = get_motion_data()
        local layer = motion_data.Layer

        layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 0, 0.0, 0.0, 1, 0)
    end

end, function(retval)
    if slash_dir == -1 then return retval end
    local motion_data = get_motion_data()
    local layer = motion_data.Layer
    local motion_id = motion_data.MotionID
    local motion_bank_id = motion_data.MotionBankID
    local frame = motion_data.Frame

    if config.hotkey_left_double_stab and last_triangle_is_back_forward then
        layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
            20, 278, 0.0, 10.0, 1, 0) -- left double
        motion_stage = MotionStage.InTriggeredLeftDoubleStab
        return retval
    end
    
    if slash_dir == 0 then
        if combo_stage == 1 and config.combo1_no_charge then -- charge stab
            layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 278, 0.0, 10.0, 1, 0) -- left double
            motion_stage = MotionStage.InTriggeredLeftDoubleStab
            return retval
        end
        if combo_stage == 2 and config.combo2_charge_stab then
            layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 270, 0.0, 10.0, 1, 0) -- charge stab
            return retval
        end

        if config.always_left_double_stab and (motion_id == 261 and motion_bank_id == 20 and frame <= 10 or motion_stage == MotionStage.InTriggeredLeftDoubleStab) then
            layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 278, 0.0, 10.0, 1, 0) -- left double
            motion_stage = MotionStage.InTriggeredLeftDoubleStab
            return retval
        end

        if motion_stage == MotionStage.InTriggeredLeftDoubleStab then
            layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 261, 0.0, 20.0, 2, 1) -- right double
            motion_stage = MotionStage.None
            return retval
        end
    end
    return retval
end)


re.on_application_entry("UpdateMotionFrame", function()
    hotkey_maintainer()
    -- local is_back_forward = get_is_back_forward()
    -- log.debug("is_back_forward: " .. tostring(is_back_forward))
    if get_wp_type() ~= 10 then return end
    local motion_data = get_motion_data()
    local layer = motion_data.Layer
    local frame = motion_data.Frame
    local motion_id = motion_data.MotionID
    local motion_bank_id = motion_data.MotionBankID

    -- log.debug("motion_stage: " .. tostring(motion_stage))

    if motion_stage == MotionStage.InTriggeredLeftDoubleStab then
        if motion_id == 278 and motion_bank_id == 20 then
            if frame >= 55 then 
                layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                    20, 261, 70.0, 20.0, 2, 1) -- right double
                motion_stage = MotionStage.None
            end
        else
            motion_stage = MotionStage.None
        end
    end

    if false then
        if frame > 15 and motion_id == 272 and motion_bank_id == 20 then
            layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 261, 5.0, 20.0, 2, 1) -- right double
            motion_stage = MotionStage.None
            return
        end
    end

    if config.charge_stab_double_stab then
        if frame > 15 and motion_id == 270 and motion_bank_id == 20 then
            layer:call("changeMotion(System.UInt32, System.UInt32, System.Single, System.Single, via.motion.InterpolationMode, via.motion.InterpolationCurve)", 
                20, 278, 5.0, 20.0, 2, 1) -- left double
            motion_stage = MotionStage.InTriggeredLeftDoubleStab
            return
        end
    end

end)

-- UI
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Insect Glaive Better Stab") then
        changed, config.charge_stab_double_stab = imgui.checkbox("Charge Stab -> Charge Double Stab", config.charge_stab_double_stab)
        changed, config.combo1_no_charge = imgui.checkbox("Combo 1 Charge Stab -> Left Double Stab", config.combo1_no_charge)
        changed, config.combo2_charge_stab = imgui.checkbox("Combo 2 Double Stab -> Charge Stab", config.combo2_charge_stab)
        changed, config.always_left_double_stab = imgui.checkbox("Combo 2 Right Double Stab -> Left Double Stab", config.always_left_double_stab)
        imgui.text("Hotkey Left Double Stab: when enabled, use back + forward + attack to trigger left double stab in first two stages of light attacks.")
        changed, config.hotkey_left_double_stab = imgui.checkbox("Hotkey Left Double Stab", config.hotkey_left_double_stab)

        imgui.tree_pop()
    end
end)