-- const
local lookup_table = {
    {
        name="Attack",
        description="Motion Value",
        varname="_Attack",
        type="float",
        min=0.0,
        max=1000.0,
    },
    {
        name = "FixAttack",
        description = "Fixed Damage",
        varname = "_FixAttack",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "AttackCond",
        description = nil,
        varname = "_AttackCond",
        type = "app.HitDef.CONDITION",
    },
    -- is_force_cond = {
    --     name = "IsForceCond",
    --     description = "Whether the attack is a force condition.",
    --     varname = "_IsForceCond",
    --     type = "bool",
    -- },
    {
        name = "PoisonDamage",
        description = nil,
        varname = "_PoisonDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "SleepDamage",
        description = nil,
        varname = "_SleepDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "BlastDamage",
        description = nil,
        varname = "_BlastDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "BleedDamage",
        description = nil,
        varname = "_BleedDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "DefenceDownDamage",
        description = nil,
        varname = "_DefenceDownDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "StunDamage",
        description = "This only acuumulates the stun value, not necessarily trigger the stun. Set SpecialType to WP10_DUST to make the attack trigger stun.",
        varname = "_StunDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "StaminaDamage",
        description = nil,
        varname = "_StaminaDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "StenchDamage",
        description = nil,
        varname = "_StenchDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "FreezeDamage",
        description = nil,
        varname = "_FreezeDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "FrenzyDamage",
        description = nil,
        varname = "_FrenzyDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "FlagBit",
        description = "MultiHit Property",
        varname = "_FlagBit",
        type = "app.col_user_data.AttackParam.FLAG_BIT",
    },
    {
        name = "MultiHitTimer",
        description = "Interval of the MultiHit",
        varname = "_MultiHitTimer",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "ActionType",
        description = nil, -- 使用肉质
        varname = "_ActionType",
        type = "app.HitDef.ACTION_TYPE",
        min = 0,
        max = 1000,
    },
    {
        name = "PartsBreakRate",
        description = nil, -- 部位破坏
        varname = "_PartsBreakRate",
        type = "float",
        min = 0.0,
        max = 100.0,
    },
    {
        name = "ParryDamage",
        description = nil,
        varname = "_ParryDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "RideDamage",
        description = nil,
        varname = "_RideDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "IsSkillHien",
        description = "Whether this attack benefits from Hien.", -- 是否技能飞燕
        varname = "_IsSkillHien",
        type = "bool",
    },
    {
        name = "IsPointAttack",
        description = nil, -- 未知
        varname = "_IsPointAttack",
        type = "bool",
    },
    {
        name = "IsPrePointHitReaction",
        description = "Whether to force stop enemy's motion when hit on wound.", -- 是否触发击中伤口强制硬直
        varname = "_IsPrePointHitReaction",
        type = "bool",
    },
    {
        name = "TearScarCreateRate",
        description = "Speed of creating Tear Scar", -- 撕裂伤口
        varname = "_TearScarCreateRate",
        type = "float",
        min = 0.0,
        max = 100.0,
    },
    {
        name = "TearScarDamageRate",
        description = "Rate of damage dealt on Tear Scar to create Raw Scar",
        varname = "_TearScarDamageRate",
        type = "float",
        min = 0.0,
        max = 100.0,
    },
    {
        name = "RawScarDamageRate",
        description = "Rate of damage dealt on Raw Scar to break it",
        varname = "_RawScarDamageRate",
        type = "float",
        min = 0.0,
        max = 100.0,
    },
    {
        name = "OldScarDamageRate",
        description = "Rate of damage dealt on Old Scar",
        varname = "_OldScarDamageRate",
        type = "float",
        min = 0.0,
        max = 100.0,
    },
    {
        name = "IsRawScarLimit",
        description = "Whether to force not breaking Raw Scar",
        varname = "_IsRawScarLimit",
        type = "bool",
    },
    {
        name = "IsWeakPointLimit",
        description = nil,
        varname = "_IsWeakPointLimit",
        type = "bool",
    },
    {
        name = "NoDamageReaction",
        description = nil,
        varname = "_NoDamageReaction",
        type = "bool",
    },
    {
        name = "Kireaji",
        description = "The Kireaji on hit",
        varname = "_Kireaji",
        type = "app.WeaponDef.KIREAJI_TYPE",
    },
    {
        name = "IsNoUseKireaji",
        description = "Whether Kireaji is not used and the damage is not scaled by Kireaji.",
        varname = "_IsNoUseKireaji",
        type = "bool",
    },
    {
        name = "IsForceUseKireajiAttackRate",
        description = "Force scale damage by Kireaji.",
        varname = "_IsForceUseKireajiAttackRate",
        type = "bool",
    },
    {
        name = "IsCustomKireajiReduce",
        description = "Whether to use custom Kireaji reduction. If not, the default Kireaji reduction of 10 is used.",
        varname = "_IsCustomKireajiReduce",
        type = "bool",
    },
    {
        name = "CustomKireajiReduce",
        description = "Custom Kireaji reduction value.",
        varname = "_CustomKireajiReduce",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "UseStatusAttackPower",
        description = nil,
        varname = "_UseStatusAttackPower",
        type = "bool",
    },
    {
        name = "UseStatusAttrPower",
        description = nil,
        varname = "_UseStatusAttrPower",
        type = "bool",
    },
    {
        name = "StatusAttrRate",
        description = nil,
        varname = "_StatusAttrRate",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "StatusConditionRate",
        description = nil,
        varname = "_StatusConditionRate",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "UseSkillAdditionalDamage",
        description = "Affects Weakness Exploit, Whiteflame Torrent, Corrupted Mantle, etc.",
        varname = "_UseSkillAdditionalDamage",
        type = "bool",
    },
    {
        name = "UseSkillContinuousAttack",
        description = nil,
        varname = "_UseSkillContinuousAttack",
        type = "bool",
    },
    {
        name = "CriticaType",
        description = "Force a Critical Type when IsNoCritical is true",
        varname = "_CriticaType",
        type = "app.Hit.CRITICAL_TYPE",
    },
    {
        name = "IsNoCritical",
        description = nil,
        varname = "_IsNoCritical",
        type = "bool",
    },
    {
        name = "HitEffectType",
        description = nil,
        varname = "_HitEffectType",
        type = "app.HitDef.HIT_EFFECT_TYPE_PL",
        min = 0,
        max = 1000,
    },
    {
        name = "GeneralValue1",
        description = nil,
        varname = "_GeneralValue1",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "GeneralValue2",
        description = nil,
        varname = "_GeneralValue2",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "GeneralValue3",
        description = nil,
        varname = "_GeneralValue3",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "FriendDamageType",
        description = nil,
        varname = "_FriendDamageType",
        type = "app.HitDef.DAMAGE_TYPE",
    },
    {
        name = "IgnoreRecoil",
        description = "Mind's Eye",
        varname = "_IgnoreRecoil",
        type = "bool",
    },
    {
        name = "IsDisableHitStop",
        description = nil,
        varname = "_IsDisableHitStop",
        type = "bool",
    },
    {
        name = "HitStopTypeFixed",
        description = nil,
        varname = "_HitStopTypeFixed",
        type = "app.PlayerDef.HIT_STOP_TYPE_Fixed",
    },
    {
        name = "HitStopIgnoreResponse",
        description = nil,
        varname = "_HitStopIgnoreResponse",
        type = "bool",
    },
    {
        name = "CaptureDamage",
        description = nil,
        varname = "_CaptureDamage",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "SpecialType",
        description = "Set to WP10_DUST to make the attack trigger stun.",
        varname = "_SpecialType",
        type = "app.HunterDef.SHELL_SPECIAL_TYPE",
    },
    {
        name = "DamageType",
        description = nil,
        varname = "_DamageType",
        type = "app.HitDef.DAMAGE_TYPE",
    },
    {
        name = "DamageTypeCustom",
        description = nil,
        varname = "_DamageTypeCustom",
        type = "app.HitDef.DAMAGE_TYPE_CUSTOM",
    },
    {
        name = "DamageAngle",
        description = nil,
        varname = "_DamageAngle",
        type = "app.HitDef.DAMAGE_ANGLE",
    },
    {
        name = "AttackAttr",
        description = nil,
        varname = "_AttackAttr",
        type = "app.HitDef.ATTR",
    },
    {
        name = "AttrLevel",
        description = nil,
        varname = "_AttrLevel",
        type = "int",
        min = 0,
        max = 1000,
    },
    {
        name = "AttrValue",
        description = nil,
        varname = "_AttrValue",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "StageDamageType",
        description = nil,
        varname = "_StageDamageType",
        type = "app.HitDef.STAGE_DAMAGE_TYPE",
    },
    {
        name = "StageDamageExID",
        description = nil,
        varname = "_StageDamageExID",
        type = "app.HitDef.STAGE_DAMAGE_EX_ID",
    },
    {
        name = "StageDamageOld",
        description = nil,
        varname = "_StageDamageOld",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },
    {
        name = "HealValue",
        description = nil,
        varname = "_HealValue",
        type = "float",
        min = 0.0,
        max = 1000.0,
    },

}

local function get_enum(type_name)
    local type_def = sdk.find_type_definition(type_name)
    if not type_def then return nil end
    local id2name = {}
    local idpp2name = {}
    local name2id = {}
    for _, field in ipairs(type_def:get_fields()) do
        if field:is_static() then
            local field_name = field:get_name()
            local field_value = field:get_data(nil)
            local field_value_name = tostring(field_value) .. " - " .. field_name
            if field_name == "MAX" then
                goto continue
            end
            id2name[field_value] = field_value_name -- credits to lingsamuel
            idpp2name[field_value + 1] = field_value_name
            name2id[field_value_name] = field_value
        end
        ::continue::
    end
    return {id2name = id2name, idpp2name = idpp2name, name2id = name2id}
end

local function get_enum_fixed(type_name, fixed_type_name)
    local type_def = sdk.find_type_definition(type_name)
    if not type_def then return nil end
    local name2table = {}
    local id2name = {}
    local idpp2name = {}
    local name2id = {}
    for _, field in ipairs(type_def:get_fields()) do
        if field:is_static() then
            local field_name = field:get_name()
            local field_value = field:get_data(nil)
            local field_value_name = tostring(field_value) .. " - " .. field_name
            if field_name == "MAX" then
                goto continue
            end
            name2table[field_name] = {}
            name2table[field_name].value = field_value
            name2table[field_name].field_value_name = field_value_name
            id2name[field_value] = field_value_name -- credits to lingsamuel
            idpp2name[field_value + 1] = field_value_name
            name2id[field_value_name] = field_value
        end
        ::continue::
    end

    local type_def = sdk.find_type_definition(fixed_type_name)
    if not type_def then return nil end
    local fixedid2name = {}
    local idpp2fixedid = {}
    local fixedid2idpp = {}
    for _, field in ipairs(type_def:get_fields()) do
        if field:is_static() then
            local field_name = field:get_name()
            local fixed_value = field:get_data(nil)
            if field_name == "MAX" then
                goto continue
            end
            local field_value_name = name2table[field_name].field_value_name
            local idpp = name2table[field_name].value + 1
            fixedid2name[fixed_value] = field_value_name
            idpp2fixedid[idpp] = fixed_value
            fixedid2idpp[fixed_value] = idpp
        end
        ::continue::
    end

    return {
        id2name = id2name,
        idpp2name = idpp2name,
        name2id = name2id,
        fixedid2name = fixedid2name,
        idpp2fixedid = idpp2fixedid,
        fixedid2idpp = fixedid2idpp,
    }
end

local enum_table = {
    ["app.HitDef.CONDITION"] = get_enum("app.HitDef.CONDITION"),
    ["app.col_user_data.AttackParam.FLAG_BIT"] = get_enum("app.col_user_data.AttackParam.FLAG_BIT"),
    ["app.HitDef.ACTION_TYPE"] = get_enum("app.HitDef.ACTION_TYPE"),
    ["app.HitDef.DAMAGE_TYPE"] = get_enum("app.HitDef.DAMAGE_TYPE"),
    ["app.WeaponDef.KIREAJI_TYPE"] = get_enum("app.WeaponDef.KIREAJI_TYPE"),
    ["app.Hit.CRITICAL_TYPE"] = get_enum("app.Hit.CRITICAL_TYPE"),
    ["app.HunterDef.SHELL_SPECIAL_TYPE"] = get_enum("app.HunterDef.SHELL_SPECIAL_TYPE"),
    ["app.HitDef.HIT_EFFECT_TYPE_PL"] = get_enum("app.HitDef.HIT_EFFECT_TYPE_PL"),
    ["app.HitDef.DAMAGE_TYPE_CUSTOM"] = get_enum("app.HitDef.DAMAGE_TYPE_CUSTOM"),
    ["app.HitDef.DAMAGE_ANGLE"] = get_enum("app.HitDef.DAMAGE_ANGLE"),
    ["app.HitDef.ATTR"] = get_enum("app.HitDef.ATTR"),
    ["app.HitDef.STAGE_DAMAGE_TYPE"] = get_enum("app.HitDef.STAGE_DAMAGE_TYPE"),
    ["app.HitDef.STAGE_DAMAGE_EX_ID"] = get_enum("app.HitDef.STAGE_DAMAGE_EX_ID"),
}

local enum_fixed_table = {
    ["app.PlayerDef.HIT_STOP_TYPE_Fixed"] = get_enum_fixed("app.PlayerDef.HIT_STOP_TYPE", "app.PlayerDef.HIT_STOP_TYPE_Fixed"),
}

-- config
local config_file = "MV_manager.json"
local preset_dir = "MVManagerPresets\\\\"

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

local function get_empty_motion_config()
    local properties = {}
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        local value_type = lookup.type
        local property_config = {
            enabled = false,
        }
        if value_type == "float" then
            property_config.value = 0.0
        elseif value_type == "bool" then
            property_config.value = false
        elseif value_type == "int" then
            property_config.value = 0
        elseif enum_table[value_type] then
            property_config.value = 0
        elseif enum_fixed_table[value_type] then
            property_config.value = enum_fixed_table[value_type].idpp2fixedid[1]
        end
        properties[lookup.name] = property_config
    end

    return {
        enabled = false,
        name = "Unnamed",
        preset_id = nil,
        properties = properties,
    }
end

local saved_config = json.load_file(config_file) or {}

local config = {
    enabled = true,
    global_motion_config = get_empty_motion_config(),
    global_property_toggle = {},
}
for i = 1, #lookup_table do
    local lookup = lookup_table[i]
    config.global_property_toggle[lookup.name] = true
end


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
local preset_names = {}
local preset_idxs = {}

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
    preset_names = {}
    preset_idxs = {}
    for preset_name, _ in spairs(preset_configs) do
        preset_names[#preset_names + 1] = preset_name
        preset_idxs[preset_name] = #preset_names
    end
end
load_preset_configs()

local function merge_motion_config_properties(target, source)
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        local name = lookup.name
        if source[name] and source[name].enabled then
            target[name] = target[name] or {}
            target[name].enabled = source[name].enabled
            target[name].value = source[name].value
        end
    end
end

-- _MVMANAGER_GLOBAL_MOTION_CONFIG = get_empty_motion_config()

local function get_motion_config(key)
    local motion_config = get_empty_motion_config()
    motion_config.enabled = true
    -- if _MVMANAGER_GLOBAL_MOTION_CONFIG.enabled then
    --     return _MVMANAGER_GLOBAL_MOTION_CONFIG
    -- end

    if config.global_motion_config.enabled then
        merge_motion_config_properties(motion_config.properties, config.global_motion_config.properties)
    end
    for preset_name, preset in pairs(preset_configs) do
        if not preset.enabled then goto continue end
        if preset.motion_configs[key] and preset.motion_configs[key].enabled then
            motion_config.name = preset.motion_configs[key].name
            motion_config.preset_id = preset_idxs[preset_name]
            merge_motion_config_properties(motion_config.properties, preset.motion_configs[key].properties)
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
function tooltip(text)
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then imgui.set_tooltip("  "..text.."  ") end
end

local function get_properties(attack_data)
    local properties = {}
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        local ok, value = pcall(function()
            return attack_data:get_field(lookup.varname)
        end)
        if ok and value ~= nil then
            properties[lookup.name] = {enabled = false, value = value}
        else
            log.debug(string.format("Failed to get property '%s' from attack_data", lookup_table[i].name))
        end
    end
    return properties
end

local function set_properties(attack_data, properties)
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        if properties[lookup.name] and properties[lookup.name].enabled then
            local ok = pcall(function()
                attack_data:set_field(lookup.varname, properties[lookup.name].value)
            end)
            if not ok then
                log.debug(string.format("Failed to set property '%s' on attack_data", lookup.name))
            end
        end
    end
end

local function show_properties(properties)
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        if not properties[lookup.name] then goto continue end
        if not config.global_property_toggle[lookup.name] then goto continue end

        local value_type = lookup.type
        if value_type == "float" then
            imgui.text(string.format("%s: %.2f", lookup.name, properties[lookup.name].value))
        elseif value_type == "bool" then
            imgui.text(string.format("%s: %s", lookup.name, properties[lookup.name].value and "true" or "false"))
        elseif value_type == "int" then
            imgui.text(string.format("%s: %d", lookup.name, properties[lookup.name].value))
        elseif enum_table[value_type] then
            local enum = enum_table[value_type]
            local value = properties[lookup.name].value
            local name = enum.id2name[value]
            imgui.text(string.format("%s: %s", lookup.name, name))
        elseif enum_fixed_table[value_type] then
            local enum = enum_fixed_table[value_type]
            local value = properties[lookup.name].value
            local name = enum.fixedid2name[value]
            imgui.text(string.format("%s: %s", lookup.name, name))
        end

        if lookup.description then
            tooltip(lookup.description)
        end

        ::continue::
    end
end

local function ui_properties(properties)
    local changed = false
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        if not properties[lookup.name] then goto continue end
        if not config.global_property_toggle[lookup.name] then goto continue end

        changed, properties[lookup.name].enabled = imgui.checkbox(lookup.name .. ": ", properties[lookup.name].enabled)
        imgui.same_line()
        local value_type = lookup.type
        if value_type == "float" then
            changed, properties[lookup.name].value = imgui.drag_float("## value" .. lookup.name, properties[lookup.name].value, 0.01, lookup.min, lookup.max, "%.2f")
        elseif value_type == "bool" then
            changed, properties[lookup.name].value = imgui.checkbox("## value" .. lookup.name, properties[lookup.name].value)
        elseif value_type == "int" then
            changed, properties[lookup.name].value = imgui.drag_int("## value" .. lookup.name, properties[lookup.name].value, 1, lookup.min, lookup.max)
        elseif enum_table[value_type] then
            local enum = enum_table[value_type]
            local valuepp = properties[lookup.name].value + 1
            changed, valuepp = imgui.combo("## value" .. lookup.name, valuepp, enum.idpp2name)
            if changed then
                properties[lookup.name].value = valuepp - 1
            end
        elseif enum_fixed_table[value_type] then
            local enum = enum_fixed_table[value_type]
            local fixedid = properties[lookup.name].value
            local valuepp = enum.fixedid2idpp[fixedid]
            changed, valuepp = imgui.combo("## value" .. lookup.name, valuepp, enum.idpp2name)
            if changed then
                properties[lookup.name].value = enum.idpp2fixedid[valuepp]
            end
        end

        if lookup.description then
            tooltip(lookup.description)
        end

        ::continue::
    end
end

-- core
local hit_data_queue = {}
local max_queue_size = 20
local function push_queue(hit_data)
    table.insert(hit_data_queue, hit_data)
    if #hit_data_queue > max_queue_size then
        table.remove(hit_data_queue, 1)
    end
end

-- on hit
local function get_key(hit_data)
    return string.format("%d_%s_%d", hit_data.weapon_type, hit_data.attack_owner_name, hit_data.attack_index)
end

local function hit_pre(args)
    if not config.enabled then return end
    local this = sdk.to_managed_object(args[2])
    if not this then return end
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end
    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    if not attack_data then return end
    local hit_data = {
        weapon_type = attack_data._WeaponType,
        attack_index = hit_info:get_field("<AttackIndex>k__BackingField")._Index,
        attack_owner_name = hit_info:get_field("<AttackOwner>k__BackingField"):get_Name(),
        attack_owner_tag = hit_info:get_field("<AttackOwner>k__BackingField"):get_Tag(),
    }
    hit_data.key = get_key(hit_data)
    local motion_config = get_motion_config(hit_data.key)
    hit_data.name = motion_config.name
    hit_data.preset_id = motion_config.preset_id

    hit_data.properties = get_properties(attack_data)

    push_queue(hit_data)

    if motion_config.enabled then
        set_properties(attack_data, motion_config.properties)
    end
end
-- app.Wp10Insect.evAttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("evAttackPreProcess(app.HitInfo)"), hit_pre, nil)
-- app.cHunterWeaponHandlingBase.evHit_AttackPreProcess(app.HitInfo, System.Boolean, System.Boolean)
sdk.hook(sdk.find_type_definition("app.cHunterWeaponHandlingBase"):get_method("evHit_AttackPreProcess(app.HitInfo, System.Boolean, System.Boolean)"), hit_pre, nil)

-- ui
local UI_preset_table = {}
local function update_UI_preset_table()
    for preset_name, preset_config in pairs(preset_configs) do
        local default_UI_table = {
            preset_save_as = preset_name,
        }
        merge_tables(default_UI_table, UI_preset_table[preset_name])
        UI_preset_table[preset_name] = default_UI_table
    end
end
update_UI_preset_table()

re.on_draw_ui(function()
    local changed, any_changed = false, false
    
    if imgui.tree_node("Motion Value Manager") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)

        if imgui.tree_node("Global Motion Config") then
            changed, config.global_motion_config.enabled = imgui.checkbox("Enabled", config.global_motion_config.enabled)
            ui_properties(config.global_motion_config.properties)

            imgui.tree_pop()
        end

        if imgui.tree_node("Global Property Visibility Toggle") then
            for i = 1, #lookup_table do
                local lookup = lookup_table[i]
                changed, config.global_property_toggle[lookup.name] = imgui.checkbox(lookup.name, config.global_property_toggle[lookup.name])
                if lookup.description then
                    tooltip(lookup.description)
                end
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Recent Hits") then
            for i = #hit_data_queue, 1, -1 do
                local hit_data = hit_data_queue[i]
                local motion_config = hit_data.motion_config
                local motion_name = hit_data.name
                if imgui.tree_node(hit_data.key .. "##" .. i) then
                    imgui.text("Weapon Type: " .. hit_data.weapon_type)
                    imgui.text("Attack Index: " .. hit_data.attack_index)
                    imgui.text("Attack Owner Name: " .. hit_data.attack_owner_name)
                    imgui.text("Attack Owner Tag: " .. hit_data.attack_owner_tag)
                    if imgui.tree_node("Default Properties") then
                        show_properties(hit_data.properties)
                        imgui.tree_pop()
                    end
                    changed, hit_data.name = imgui.input_text("Name", hit_data.name)
                    changed, hit_data.preset_id = imgui.combo("Preset Name", hit_data.preset_id, preset_names)
                    local preset_name = preset_names[hit_data.preset_id] or "Not Found"
                    if imgui.button("Add") then
                        preset_configs[preset_name].motion_configs[hit_data.key] = preset_configs[preset_name].motion_configs[hit_data.key] or get_empty_motion_config()
                        preset_configs[preset_name].motion_configs[hit_data.key].name = hit_data.name
                        preset_configs[preset_name].motion_configs[hit_data.key].preset_id = hit_data.preset_id
                        preset_configs[preset_name].motion_configs[hit_data.key].enabled = true
                        local new_properties = preset_configs[preset_name].motion_configs[hit_data.key].properties
                        for key, value in pairs(hit_data.properties) do
                            if not new_properties[key] then
                                new_properties[key] = {}
                                new_properties[key].enabled = false
                            end
                            if not new_properties[key].enabled then
                                new_properties[key].value = value.value
                            end
                        end
                    end
                    imgui.tree_pop()
                end
            end
            imgui.tree_pop()
        end

        if imgui.tree_node("Presets") then
            for preset_name, preset_config in spairs(preset_configs) do
                if imgui.tree_node(preset_name) then
                    local UI_vars = UI_preset_table[preset_name]
                    local motion_configs = preset_config.motion_configs
                    changed, preset_config.enabled = imgui.checkbox("Enabled", preset_config.enabled)
                    if imgui.tree_node("Saved Motions") then
                        for key, motion_config in spairs(motion_configs) do
                            -- make sure motion_config contains all the required fields
                            motion_config.enabled = motion_config.enabled or false
                            motion_config.name = motion_config.name or "Unnamed"
                            motion_config.preset_id = motion_config.preset_id or preset_idxs["default"]
                            motion_config.properties = motion_config.properties or {}
                            local motion_id_str = motion_config.name .. " (" .. key .. ")"
                            if imgui.tree_node(motion_id_str) then
                                changed, motion_config.enabled = imgui.checkbox("Enabled", motion_config.enabled)
                                ui_properties(motion_config.properties)

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