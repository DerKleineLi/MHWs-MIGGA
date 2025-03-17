local config = json.load_file("No_KeyLag_settings.json")
local modified_keys = {}
local debug = false

config = config or {}
config.enabled = config.enabled or true
config.threshold = config.threshold or 0.099
config.set = config.set or 0.02

local function dbgprint(str)
    if debug then
        log.debug(str)
    end
end

local function restoreKeys()
    for k, v in pairs(modified_keys) do
        dbgprint("Restored: Key " .. v.key:get_KeyType() .. string.format("@%X", v.key:get_address()) .. ", original: " .. v.val)
        v.key:set_LagTime(v.val)
        modified_keys[k] = nil
    end
end

local function preHook(args)
    if not config.enabled then
        restoreKeys()
        return
    end
    -- local parent = args[1]
    local cLaggedKey = sdk.to_managed_object(args[2])
    if not cLaggedKey then return end
    -- dbgprint("cLaggedKey: " .. string.format("%X", cLaggedKey:get_address()))
    local key_type = cLaggedKey:get_KeyType()
    -- dbgprint("key_type: " .. key_type)
    local lag_frame = cLaggedKey:get_LagTime()
    -- dbgprint("lag_frame: " .. lag_frame)
    if lag_frame and lag_frame > config.threshold then
        local info = {key = cLaggedKey, val = lag_frame}
        table.insert(modified_keys, info)
        -- dbgprint(tostring(parent))
        dbgprint("Set: Key " .. key_type .. string.format("@%X", cLaggedKey:get_address()) .. ", lag_frame: " .. lag_frame .. ", new: " .. config.set)
        cLaggedKey:set_LagTime(config.set)
    end
end

sdk.hook(sdk.find_type_definition("app.cLaggedKey"):get_method("onCustomUpdate"), preHook, nil)


re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("No KeyLag") then
        local changed = false
        local any_changed = false

        changed, config.enabled = imgui.checkbox("Enable", config.enabled)
        any_changed = any_changed or changed

        if config.enabled then
            imgui.text("Lag Threshold")
            imgui.begin_group()
            changed, config.threshold = imgui.slider_float("##Threshold", config.threshold, 0.0, 0.20)
            imgui.end_group()
            any_changed = any_changed or changed

            imgui.text("Lag Value")
            imgui.begin_group()
            changed, config.set = imgui.slider_float("##Value", config.set, 0.0, 0.20)
            imgui.end_group()
            any_changed = any_changed or changed
           
            imgui.text("Will set all keys with lag > \"Lag Threshold\" to \"Lag Value\".")
        end

        if any_changed then
            restoreKeys()
        end

        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("No_KeyLag_settings.json", config)
    end
)