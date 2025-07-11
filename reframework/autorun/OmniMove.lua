-- config
local config_file = "OmniMove.json"
local preset_dir = "OmniMovePresets\\\\"

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
    LStick_active_threshold = 0.2,
    LStick_trigger_threshold = 0.5,
    global_motion_config = {
        enabled = false,
        speed = 0.0,
        start_frame = 0,
        end_frame = 0,
        direction_type = 1, -- Omni
        speed_type = 1, -- LStick
        block_original_move_xz = false, -- block original move XZ
        block_original_move_y = false, -- block original move Y
        direction_vector = {0, 0, 1.0}, -- front
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
        speed = 0.0,
        start_frame = 0,
        end_frame = 1000,
        direction_type = 1, -- 1: Omni, 2: Aligned, 3: Camera, 4: Camera3D_Omni, 5: Camera3D_Aligned, 6: Hunter
        speed_type = 1, -- 1: LStick, 2: LStick Trigger, 3: Fixed
        block_original_move_xz = false, 
        block_original_move_y = false, 
        direction_vector = {0, 0, 1.0}, 
    }
end
_OMNIMOVE_GLOBAL_SEGMENT_CONFIG = get_empty_segment_config()

local function get_motion_config(key)
    local segment_config = get_empty_segment_config()
    merge_tables(segment_config, _OMNIMOVE_GLOBAL_SEGMENT_CONFIG)
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
local function get_relative_angle(x1, y1, x2, y2)
    local angle = math.atan(y2, x2) - math.atan(y1, x1)
    return angle
end

local function rotate(x, y, angle)
    local cos_theta = math.cos(angle)
    local sin_theta = math.sin(angle)
    return x * cos_theta - y * sin_theta, x * sin_theta + y * cos_theta
end

local function rotate_vector_around_axis(front, up, alpha)
    local cos_alpha = math.cos(alpha)
    local sin_alpha = math.sin(alpha)

    local dot_product = front:dot(up)
    local cross_product = front:cross(up)

    return Vector3f.new(
        front.x * cos_alpha + cross_product.x * sin_alpha + up.x * dot_product * (1 - cos_alpha),
        front.y * cos_alpha + cross_product.y * sin_alpha + up.y * dot_product * (1 - cos_alpha),
        front.z * cos_alpha + cross_product.z * sin_alpha + up.z * dot_product * (1 - cos_alpha)
    )
end

local function get_hunter()
    local player_manager = sdk.get_managed_singleton("app.PlayerManager")
    if not player_manager then return nil end
    local player_info = player_manager:getMasterPlayer()
    if not player_info then return nil end
    local hunter_character = player_info:get_Character()
    return hunter_character
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
    -- output.is_enable_input_world_dir = hunter_action_arg:get_IsEnableInputWorldDir()
    -- output.input_world_dir = hunter_action_arg:get_InputWorldDir()
    -- output.lstick = player_command_result:get_LStick() -- in some actions the Lstick is disabled, so use the homemade virtual lstick instead
    -- output.lstick_magnitude = player_command_result:get_LStickMagnitude()
    -- output.is_enable_lstick = player_command_result:get_IsEnableLStick()
    -- output.is_aim = hunter_action_arg:get_IsAim()
    output.camera_lookat_dir = hunter_action_arg:get_CameraLookAtDir()

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

    local up_vector = Vector3f.new(0, 1, 0)
    local camera_right_vector = (output.camera_lookat_dir:cross(up_vector)):normalized()
    local camera_up_vector = (camera_right_vector:cross(output.camera_lookat_dir)):normalized()
    output.camera_right_dir = camera_right_vector
    output.camera_up_dir = camera_up_vector

    output.virtual_input_world_dir_3d = rotate_vector_around_axis(output.camera_lookat_dir, camera_up_vector, math.atan(virtual_lstick.x, virtual_lstick.y))

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

local function set_hunter_position(pos)
    local hunter_transform = get_hunter_transform()
    hunter_transform.transform:set_Position(pos)
end

local function set_hunter_offset(direction, distance)
    local hunter_transform = get_hunter_transform()
    if not hunter_transform then return end
    local current_pos = hunter_transform.position
    current_pos.x = current_pos.x + direction.x * distance
    current_pos.y = current_pos.y + direction.y * distance
    current_pos.z = current_pos.z + direction.z * distance
    hunter_transform.transform:set_Position(current_pos)
end

local function get_direction(front, right, up, direction_vector_table)
    local direction_vector = Vector3f.new(direction_vector_table[1], direction_vector_table[2], direction_vector_table[3])
    if direction_vector:length() == 0 then
        direction_vector = Vector3f.new(0, 0, 1.0)
    end
    local direction = front * direction_vector.z + right * direction_vector.x + up * direction_vector.y
    direction:normalize()
    return direction
end

-- core
local direction_types = {
    "Omni",
    "Aligned",
    "Camera",
    "Camera3D_Omni",
    "Camera3D_Aligned",
    "Hunter",
}
local speed_types = {
    "LStick",
    "LStick Trigger",
    "Fixed",
}

local last_frame_time = nil
local last_start_input_world_dir = Vector3f.new(0, 0, 0)
local start_input_world_dir_angle = 0.0
local last_hunter_position = nil
re.on_application_entry("UpdateMotionFrame", function()
    local input = get_input()
    local hunter_transform = get_hunter_transform()
    if not input or not hunter_transform then return end

    if last_frame_time and config.LStick_active_threshold < 1.0 and config.enabled then
        local main_motion = get_motion()
        local sub_motion = get_sub_motion()
        for _, motion in ipairs({main_motion, sub_motion}) do
            if motion then
                local motion_id = motion.MotionID
                local motion_bank_id = motion.MotionBankID
                local motion_frame = motion.Frame
                local layer_id = motion.LayerID
                local config_key = string.format("%d_%d_%d", layer_id, motion_bank_id, motion_id)
                local target_motion_config = get_motion_config(config_key)

                local position_changed = false
                for _, target_config in ipairs(target_motion_config.segments) do
                    if target_config.enabled and motion_frame >= target_config.start_frame and motion_frame <= target_config.end_frame then
                        local magnitude_scale = 1.0
                        local direction = nil
                        if direction_types[target_config.direction_type] == "Omni" then
                            direction = input.virtual_input_world_dir
                        elseif direction_types[target_config.direction_type] == "Aligned" then
                            local hunter_front = hunter_transform.forward
                            local new_x, new_z = rotate(hunter_front.x, hunter_front.z, start_input_world_dir_angle)
                            direction = Vector3f.new(new_x, 0, new_z)
                            local l_stick_direction = input.virtual_input_world_dir
                            magnitude_scale = direction.x * l_stick_direction.x + direction.y * l_stick_direction.y + direction.z * l_stick_direction.z
                        elseif direction_types[target_config.direction_type] == "Camera" then
                            direction = get_direction(input.camera_front_dir, input.camera_right_dir, Vector3f.new(0, 1, 0), target_config.direction_vector)
                            local l_stick_direction = input.virtual_input_world_dir
                            magnitude_scale = direction.x * l_stick_direction.x + direction.y * l_stick_direction.y + direction.z * l_stick_direction.z
                        elseif direction_types[target_config.direction_type] == "Camera3D_Omni" then
                            direction = input.virtual_input_world_dir_3d
                        elseif direction_types[target_config.direction_type] == "Camera3D_Aligned" then
                            direction = get_direction(input.camera_lookat_dir, input.camera_right_dir, input.camera_up_dir, target_config.direction_vector)
                            local camera_front = input.camera_front_dir
                            local l_stick_direction = input.virtual_input_world_dir
                            magnitude_scale = camera_front.x * l_stick_direction.x + camera_front.y * l_stick_direction.y + camera_front.z * l_stick_direction.z
                        elseif direction_types[target_config.direction_type] == "Hunter" then
                            direction = get_direction(hunter_transform.forward, hunter_transform.right, hunter_transform.up, target_config.direction_vector)
                            local l_stick_direction = input.virtual_input_world_dir
                            magnitude_scale = direction.x * l_stick_direction.x + direction.y * l_stick_direction.y + direction.z * l_stick_direction.z
                        end

                        local speed = target_config.speed
                        if speed_types[target_config.speed_type] == "LStick" then
                            local linear_magnitude = (input.virtual_lstick_magnitude - config.LStick_active_threshold) / (1 - config.LStick_active_threshold + 1e-6)
                            linear_magnitude = math.max(0, math.min(1, linear_magnitude))
                            speed = magnitude_scale * linear_magnitude * speed
                        elseif speed_types[target_config.speed_type] == "LStick Trigger" then
                            speed = input.virtual_lstick_magnitude * magnitude_scale >= config.LStick_trigger_threshold and speed or 0
                        elseif speed_types[target_config.speed_type] == "Fixed" then
                            speed = speed
                        end
                        local distance = speed * (os.clock() - last_frame_time)

                        if last_hunter_position then
                            local current_pos = hunter_transform.position
                            local new_pos = Vector3f.new(current_pos.x, current_pos.y, current_pos.z)
                            if target_config.block_original_move_xz then
                                new_pos.x = last_hunter_position.x
                                new_pos.z = last_hunter_position.z
                            end
                            if target_config.block_original_move_y then
                                new_pos.y = last_hunter_position.y
                            end
                            local no_update = (
                                new_pos.x == current_pos.x and
                                new_pos.y == current_pos.y and
                                new_pos.z == current_pos.z
                            )
                            if not no_update then
                                set_hunter_position(new_pos)
                                position_changed = true
                            end
                        end
                        if direction:length() > 0 and distance ~= 0 then
                            set_hunter_offset(direction, distance)
                            position_changed = true
                        end
                    end
                end
                if position_changed then break end
            end
        end
    end
    -- Late update
    last_frame_time = os.clock()
    local new_start_input_world_dir = input.start_input_world_dir
    local new_equal_old = (
        new_start_input_world_dir.x == last_start_input_world_dir.x and
        new_start_input_world_dir.y == last_start_input_world_dir.y and
        new_start_input_world_dir.z == last_start_input_world_dir.z
    )
    if input.is_enable_start_input_world_dir and not new_equal_old then
        local hunter_front = hunter_transform.forward
        local motion_front = input.start_input_world_dir
        start_input_world_dir_angle = get_relative_angle(hunter_front.x, hunter_front.z, motion_front.x, motion_front.z)
    elseif not input.is_enable_start_input_world_dir then
        start_input_world_dir_angle = 0.0
    end
    last_start_input_world_dir = new_start_input_world_dir
    last_hunter_position = get_hunter_transform().position
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
    
    local function imgui_vec3(config_var)
        local vec3 = Vector3f.new(config_var[1], config_var[2], config_var[3])
        changed, vec3 = imgui.drag_float3("Direction Vector", vec3, 0.01, -1.0, 1.0)
        config_var[1] = vec3.x
        config_var[2] = vec3.y
        config_var[3] = vec3.z
    end
    
    if imgui.tree_node("OmniMove") then

        if imgui.tree_node("Global Configs") then
            changed, config.enabled = imgui.checkbox("Enabled", config.enabled)
            changed, config.LStick_active_threshold = imgui.drag_float("LStick Active Threshold", config.LStick_active_threshold, 0.01, 0, 1.0, "%.2f")
            changed, config.LStick_trigger_threshold = imgui.drag_float("LStick Trigger Threshold", config.LStick_trigger_threshold, 0.01, 0, 1.0, "%.2f")
            
            if imgui.tree_node("Global Motion Configs") then
                changed, config.global_motion_config.enabled = imgui.checkbox("Enabled", config.global_motion_config.enabled)
                changed, config.global_motion_config.speed = imgui.drag_float("Speed", config.global_motion_config.speed, 0.01, -100.0, 100.0, "%.2f")
                imgui.text("Set the start and end frames of the motion to enable OmniMove.")
                imgui.begin_table("Frames", 2)
                imgui.table_next_row()
                imgui.table_next_column()
                changed, config.global_motion_config.start_frame = imgui.drag_int("Start Frame", config.global_motion_config.start_frame, 1, 0, 1000)
                imgui.table_next_column()
                changed, config.global_motion_config.end_frame = imgui.drag_int("End Frame", config.global_motion_config.end_frame, 1, 0, 1000)
                imgui.end_table()
                if imgui.tree_node("Direction Type:") then
                    imgui.text("Omni: direction aligns with the Lstick/WASD.")
                    imgui.text("Aligned: direction aligns with the hunter motion.")
                    imgui.text("Camera: direction aligns with the camera coordinate frame, regardless of the pitch.")
                    imgui.text("Camera3D_Omni: direction aligns with the XZ plane of the camera, with LStick/WASD determin the direction.")
                    imgui.text("Camera3D_Aligned: direction aligns with the camera coordinate frame, considering the pitch.")
                    imgui.text("Hunter: direction aligns with the hunter coordinate frame.")
                    imgui.tree_pop()
                end
                changed, config.global_motion_config.direction_type = imgui.combo("Direction Type", config.global_motion_config.direction_type, direction_types)
                if imgui.tree_node("Direction Vector:") then
                    imgui.text("Only works when the direction type is Camera, Camera3D_Aligned, or Hunter, sets the direction in corresponding frames.")
                    imgui.text("Forward: (0, 0, 1)")
                    imgui.text("Right: (1, 0, 0)")
                    imgui.text("Up: (0, 1, 0)")
                    imgui.text("Left: (-1, 0, 0)")
                    imgui.text("Back: (0, 0, -1)")
                    imgui.text("Down: (0, -1, 0)")
                    imgui.tree_pop()
                end
                imgui_vec3(config.global_motion_config.direction_vector)
                if imgui.tree_node("Speed Type:") then
                    imgui.text("LStick: speed scales linearly with the Lstick magnitude.")
                    imgui.text("LStick Trigger: speed is 0 until the Lstick trigger threshold is reached, afterwards the max speed.")
                    imgui.text("Fixed: speed is fixed to maximum.")
                    imgui.tree_pop()
                end
                changed, config.global_motion_config.speed_type = imgui.combo("Speed Type", config.global_motion_config.speed_type, speed_types)

                imgui.begin_table("Block Original Move", 2)
                imgui.table_next_row()
                imgui.table_next_column()
                changed, config.global_motion_config.block_original_move_xz = imgui.checkbox("Block Original Move XZ", config.global_motion_config.block_original_move_xz)
                imgui.table_next_column()
                changed, config.global_motion_config.block_original_move_y = imgui.checkbox("Block Original Move Y", config.global_motion_config.block_original_move_y)
                imgui.end_table()

                imgui.tree_pop()
            end
            
            imgui.tree_pop()
        end
        
        if imgui.tree_node("Current Motion") then
            local motion = get_motion()
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
                            local key = string.format("%d_%d_%d", UI_vars.is_submotion_to_add and 3 or 0, UI_vars.motion_bank_id_to_add, UI_vars.motion_id_to_add)
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
                                    segment.speed = segment.speed or 0.0
                                    segment.enabled = segment.enabled or false
                                    segment.direction_type = segment.direction_type or 1
                                    segment.speed_type = segment.speed_type or 1
                                    segment.start_frame = segment.start_frame or 0
                                    segment.end_frame = segment.end_frame or 0
                                    segment.block_original_move_xz = segment.block_original_move_xz or false
                                    segment.block_original_move_y = segment.block_original_move_y or false
                                    segment.direction_vector = segment.direction_vector or {0, 0, 1.0}

                                    if imgui.tree_node("Segment " .. tostring(segment_idx)) then
                                        changed, segment.enabled = imgui.checkbox("Enabled", segment.enabled)
                                        changed, segment.speed = imgui.drag_float("Speed", segment.speed, 0.01, -100.0, 100.0, "%.2f")
                                        imgui.begin_table("Frames", 2)
                                        imgui.table_next_row()
                                        imgui.table_next_column()
                                        changed, segment.start_frame = imgui.drag_int("Start Frame", segment.start_frame, 1, 0, 1000)
                                        imgui.table_next_column()
                                        changed, segment.end_frame = imgui.drag_int("End Frame", segment.end_frame, 1, 0, 1000)
                                        imgui.end_table()
                                        changed, segment.direction_type = imgui.combo("Direction Type", segment.direction_type, direction_types)
                                        imgui_vec3(segment.direction_vector)
                                        changed, segment.speed_type = imgui.combo("Speed Type", segment.speed_type, speed_types)
                                        
                                        imgui.begin_table("Block Original Move", 2)
                                        imgui.table_next_row()
                                        imgui.table_next_column()
                                        changed, segment.block_original_move_xz = imgui.checkbox("Block Original Move XZ", segment.block_original_move_xz)
                                        imgui.table_next_column()
                                        changed, segment.block_original_move_y = imgui.checkbox("Block Original Move Y", segment.block_original_move_y)
                                        imgui.end_table()
                                        
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