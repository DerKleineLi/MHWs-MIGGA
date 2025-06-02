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

local saved_config = json.load_file("kinsect_smart_extracts.json") or {}

local config = {
    enabled = true,
    replace_green = 3,
}

merge_tables(config, saved_config)

re.on_config_save(
    function()
        json.dump_file("kinsect_smart_extracts.json", config)
    end
)

-- core
local in_set_extra_stock = false
local skip_color = -1
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("setExtraStock(app.Wp10Def.EXTRACT_TYPE, via.vec3)"),
function(args)
    local Wp10Insect = sdk.to_managed_object(args[2])
    if not Wp10Insect then return end
    local hunter = Wp10Insect:get_Hunter()
    if not hunter:get_IsMaster() then return end

    local new_extra = sdk.to_int64(args[3])
    if new_extra == 3 and config.replace_green >= 0 then
        args[3] = sdk.to_ptr(config.replace_green)
        new_extra = config.replace_green
    end

    skip_color = -1
    in_set_extra_stock = true

    if not config.enabled then return end

    -- local flag = Wp10Insect:checkInsectActionFlag(4)
    -- log.debug("flag: " .. tostring(flag))
    Wp10Insect:offInsectActionFlag(4)

    local extra_stock_num = Wp10Insect._ExtraStockNum
    local extra_stock = Wp10Insect:get_ExtraStock():get_elements()
    local pre0 = extra_stock[1].value__
    local pre1 = extra_stock[2].value__
    local pre2 = extra_stock[3].value__
    
    local new_count = 1 -- the new color
    local color_counts = {
        [0] = 0,
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }
    if pre0 ~= -1 then
        new_count = new_count + 1
        color_counts[pre0] = color_counts[pre0] + 1
    end
    if pre1 ~= -1 then
        new_count = new_count + 1
        color_counts[pre1] = color_counts[pre1] + 1
    end
    if pre2 ~= -1 then
        new_count = new_count + 1
        color_counts[pre2] = color_counts[pre2] + 1
    end
    color_counts[new_extra] = color_counts[new_extra] + 1

    -- log.debug("new_count: " .. tostring(new_count))
    -- log.debug("color_counts: " .. tostring(color_counts[0]) .. " " .. tostring(color_counts[1]) .. " " .. tostring(color_counts[2]) .. " " .. tostring(color_counts[3]))

    if new_count <= extra_stock_num then
        return
    end
    for i = 0, 2 do
        if color_counts[i] > 1 then -- has duplicate color
            skip_color = i
            return
        end
    end
    skip_color = 3 -- skip green
end, function(retval)
    in_set_extra_stock = false
    return retval
end)

sdk.hook(sdk.find_type_definition("ace.cFixedRingBuffer`1<System.Int32>"):get_method("pushBack(System.Int32)"),
function(args)
    if not in_set_extra_stock then return end
    -- log.debug("skip_color: " .. tostring(skip_color))
    if skip_color == -1 and config.replace_green ~= -1 then return end

    local value = args[3]
    local value_type = sdk.find_type_definition("System.Int32")
    local m_value = sdk.get_native_field(value, value_type, "m_value")
    -- log.debug("m_value: " .. tostring(m_value))
    if m_value == skip_color then
        skip_color = -1
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
    if m_value == 3 and config.replace_green == -1 then
        return sdk.PreHookResult.SKIP_ORIGINAL
    end
end, nil)

-- ui
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("Kinsect Smart Extracts") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)
        any_changed = any_changed or changed

        changed, config.replace_green = imgui.slider_int("Replace Green", config.replace_green, -1, 3)
        any_changed = any_changed or changed

        imgui.text("Replace Green: with -1: Nothing, 0: Red, 1: White, 2: Orange, 3: Green")

        imgui.tree_pop()
    end
end)
