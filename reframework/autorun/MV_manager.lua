-----------------------------
-- const
-----------------------------
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
        name = "IsSensor",
        description = "Whether this hit is a helper, the mod won't process hits with IsSensor being true.",
        varname = "_IsSensor",
        type = "bool",
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
        name = "MultiHitRateCurve",
        description = nil,
        varname = "_MultiHitRateCurve",
        type = "nullable",
    },
    {
        name = "MultiHitStatusRateCurve",
        description = nil,
        varname = "_MultiHitStatusRateCurve",
        type = "nullable",
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

local function add_to_enum(enum, key, value)
    local field_value_name = string.format("%d - %s", key, value)
    enum.id2name[key] = field_value_name
    enum.idpp2name[key + 1] = field_value_name
    enum.name2id[field_value_name] = key
end
add_to_enum(enum_table["app.col_user_data.AttackParam.FLAG_BIT"], 3, "USE_MULIT_HIT|IGNORE_PARTS_PRIORITY")

local enum_fixed_table = {
    ["app.PlayerDef.HIT_STOP_TYPE_Fixed"] = get_enum_fixed("app.PlayerDef.HIT_STOP_TYPE", "app.PlayerDef.HIT_STOP_TYPE_Fixed"),
}

-----------------------------
-- config
-----------------------------
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

local function get_empty_property_config()
    local properties = {}
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        local value_type = lookup.type
        local property_config = {
            enabled = false,
        }
        if value_type == "float" then
            property_config.value = 0.0
            property_config.is_multiply = false
        elseif value_type == "bool" then
            property_config.value = false
        elseif value_type == "int" then
            property_config.value = 0
        elseif value_type == "nullable" then
            property_config.value = true
        elseif enum_table[value_type] then
            property_config.value = 0
        elseif enum_fixed_table[value_type] then
            property_config.value = enum_fixed_table[value_type].idpp2fixedid[1]
        end
        properties[lookup.name] = property_config
    end
    return properties
end

local function get_empty_motion_config()
    local properties = get_empty_property_config()
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
        default_colliders = {},
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
            if source[name].is_multiply ~= nil then
                target[name].is_multiply = source[name].is_multiply
            end
        end
    end
end

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
        end
        ::continue::
    end
    return motion_config
end

local function get_default_collider(key)
    for preset_name, preset in pairs(preset_configs) do
        if preset.default_colliders[key] then
            return preset.default_colliders[key]
        end
    end
    return nil
end

re.on_config_save(
    function()
        json.dump_file(config_file, config)
    end
)

-----------------------------
-- helper functions
-----------------------------
function contains_token(haystack, needle)
    local needle_lower = needle:lower()
    for token in string.gmatch(haystack, "[^|]+") do
        if token:lower() == needle_lower then
            return true
        end
    end
    return false
end

local function copy_table(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = copy_table(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function tooltip(text) -- credits to Bimmr
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then imgui.set_tooltip("  "..text.."  ") end
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

local function get_subwp()
    local hunter = get_hunter()
    if not hunter then return nil end
    local subwp = hunter:get_SubWeapon()
    return subwp
end

local function get_wp_type()
    local hunter = get_hunter()
    if not hunter then return nil end
    return hunter:get_WeaponType()
end

local function get_kinsect()
    local hunter = get_hunter()
    if not hunter then return nil end
    local kinsect = hunter:get_Wp10Insect()
    return kinsect
end

local function get_wp_colliders()
    local wp = get_wp()
    if not wp then return nil end
    local wp_collider = wp:get_RequestSetCollider()
    if not wp_collider then return nil end
    local output = {}
    local group_count = wp_collider:getRequestSetGroupsCount()
    for i = 0, group_count - 1 do
        output[i] = {}
        local num_request_sets = wp_collider:getNumRequestSetsFromIndex(i)
        for j = 0, num_request_sets - 1 do
            output[i][j] = {}
            local num_collidables = wp_collider:getNumCollidablesFromIndex(i, j)
            for k = 0, num_collidables - 1 do
                local collidable = wp_collider:getCollidableFromIndex(i, j, k)
                output[i][j][k] = collidable
            end
        end
    end
    return output
end

local function get_wp_num_collidables(group, set)
    local wp = get_wp()
    if not wp then return nil end
    local wp_collider = wp:get_RequestSetCollider()
    if not wp_collider then return nil end
    return wp_collider:getNumCollidables(group, set)
end

local function get_wp_collider(group, set, col)
    local wp = get_wp()
    if not wp then return nil end
    local wp_collider = wp:get_RequestSetCollider()
    if not wp_collider then return nil end
    return wp_collider:getCollidable(group, set, col)
end

local function get_subwp_num_collidables(group, set)
    local subwp = get_subwp()
    if not subwp then return nil end
    local subwp_collider = subwp:get_RequestSetCollider()
    if not subwp_collider then return nil end
    return subwp_collider:getNumCollidables(group, set)
end

local function get_subwp_collider(group, set, col)
    local subwp = get_subwp()
    if not subwp then return nil end
    local subwp_collider = subwp:get_RequestSetCollider()
    if not subwp_collider then return nil end
    return subwp_collider:getCollidable(group, set, col)
end

local function get_body_num_collidables(group, set)
    local hunter = get_hunter()
    if not hunter then return nil end
    local collider_switcher = hunter:get_ColSwitcherComponent()
    if not collider_switcher then return nil end
    local body_collider = collider_switcher:get_RequestSetCollider()
    if not body_collider then return nil end
    return body_collider:getNumCollidables(group, set)
end

local function get_body_collider(group, set, col)
    local hunter = get_hunter()
    if not hunter then return nil end
    local collider_switcher = hunter:get_ColSwitcherComponent()
    if not collider_switcher then return nil end
    local body_collider = collider_switcher:get_RequestSetCollider()
    if not body_collider then return nil end
    return body_collider:getCollidable(group, set, col)
end

local function get_kinsect_num_sets(group)
    local kinsect = get_kinsect()
    if not kinsect then return nil end
    local component = kinsect._Components
    if not component then return nil end
    local component_type = sdk.find_type_definition("app.Wp10Insect.COMPONENTS")
    local kinsect_collider = sdk.get_native_field(component, component_type, "_RequestSetCol")
    if not kinsect_collider then return nil end
    return kinsect_collider:getNumRequestSetsFromIndex(group)
end

local function get_kinsect_num_collidables(group, set)
    local kinsect = get_kinsect()
    if not kinsect then return nil end
    local component = kinsect._Components
    if not component then return nil end
    local component_type = sdk.find_type_definition("app.Wp10Insect.COMPONENTS")
    local kinsect_collider = sdk.get_native_field(component, component_type, "_RequestSetCol")
    if not kinsect_collider then return nil end
    return kinsect_collider:getNumCollidablesFromIndex(group, set)
end

local function get_kinsect_collider(group, set, col)
    local kinsect = get_kinsect()
    if not kinsect then return nil end
    local component = kinsect._Components
    if not component then return nil end
    local component_type = sdk.find_type_definition("app.Wp10Insect.COMPONENTS")
    local kinsect_collider = sdk.get_native_field(component, component_type, "_RequestSetCol")
    if not kinsect_collider then return nil end
    return kinsect_collider:getCollidableFromIndex(group, set, col)
end

local function get_num_collidables(part, group, set)
    if part == "Weapon" then
        return get_wp_num_collidables(group, set)
    elseif part == "SubWeapon" then
        return get_subwp_num_collidables(group, set)
    elseif part == "Body" then
        return get_body_num_collidables(group, set)
    elseif part == "Kinsect" then
        return get_kinsect_num_collidables(group, set)
    end
end

local function get_collider(part, group, set, col)
    if part == "Body" then
        return get_body_collider(group, set, col)
    elseif part == "Kinsect" then
        return get_kinsect_collider(group, set, col)
    elseif type(part) == "string" and part:sub(1, 3) == "Sub" then
        return get_subwp_collider(group, set, col)
    else
        return get_wp_collider(group, set, col)
    end
end

local function get_properties(attack_data)
    local properties = {}
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        local ok, value = pcall(function()
            return attack_data:get_field(lookup.varname)
        end)
        if lookup.type == "nullable" then
            value = value and true or false
        end
        if ok and value ~= nil then
            properties[lookup.name] = {enabled = false, value = value}
        else
            log.info(string.format("[MVMamager] Failed to get property '%s' from attack_data", lookup_table[i].name))
        end
    end
    return properties
end

local function set_properties(attack_data, properties)
    for i = 1, #lookup_table do
        local lookup = lookup_table[i]
        if properties[lookup.name] and properties[lookup.name].enabled then
            local current_value = attack_data:get_field(lookup.varname)
            if current_value == nil then goto continue end
            local is_multiply = properties[lookup.name].is_multiply
            local value = properties[lookup.name].value
            if is_multiply then
                value = current_value * value
            end
            if lookup.type == "nullable" then
                if value then
                    goto continue
                else
                    value = nil
                end
            end
            local ok = pcall(function()
                attack_data:set_field(lookup.varname, value)
            end)
            if not ok then
                log.info(string.format("[MVManager] Failed to set property '%s' on attack_data", lookup.name))
            end
        end
        ::continue::
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
        elseif value_type == "nullable" then
            imgui.text(string.format("%s: %s", lookup.name, properties[lookup.name].value and "true" or "false"))
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
            local label = properties[lookup.name].is_multiply and " x " or " = "
            changed, properties[lookup.name].is_multiply = imgui.checkbox(label .. "## is_multiply" .. lookup.name, properties[lookup.name].is_multiply)
            imgui.same_line()
            changed, properties[lookup.name].value = imgui.drag_float("## value" .. lookup.name, properties[lookup.name].value, 0.01, lookup.min, lookup.max, "%.2f")
        elseif value_type == "bool" then
            changed, properties[lookup.name].value = imgui.checkbox("## value" .. lookup.name, properties[lookup.name].value)
        elseif value_type == "int" then
            changed, properties[lookup.name].value = imgui.drag_int("## value" .. lookup.name, properties[lookup.name].value, 1, lookup.min, lookup.max)
        elseif value_type == "nullable" then
            local prefix = properties[lookup.name].value and "Enabled" or "Disabled"
            changed, properties[lookup.name].value = imgui.checkbox(prefix .. " ## value" .. lookup.name, properties[lookup.name].value)
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

local function get_collider_key(weapon_type, group, set, col)
    if weapon_type == nil or group == nil or set == nil or col == nil then
        return nil
    end
    return string.format("%s_%d_%d_%d", tostring(weapon_type), group, set, col)
end

local function extract_collider_properties(collidable, output)
    output = output or {}
    local shape = collidable:get_Shape()
    local shape_type = shape:get_type_definition():get_full_name()
    output.shape_type = shape_type
    if shape_type == "via.physics.ContinuousCapsuleShape" or shape_type == "via.physics.CapsuleShape" then
        local capsule = shape:get_Capsule()
        local start_pos = capsule.p0
        local end_pos = capsule.p1
        local radius = capsule.r
        output.start_pos = {enabled=false, value={start_pos.x, start_pos.y, start_pos.z}}
        output.end_pos = {enabled=false, value={end_pos.x, end_pos.y, end_pos.z}}
        output.radius = {enabled=false, value=radius}
    elseif shape_type == "via.physics.ContinuousSphereShape" or shape_type == "via.physics.SphereShape" then
        local sphere = shape:get_Sphere()
        local center = sphere.pos
        local radius = sphere.r
        output.center = {enabled=false, value={center.x, center.y, center.z}}
        output.radius = {enabled=false, value=radius}
    end
end

local function get_colliders(collidable, active_collider_list, weapon_type)
    local output = {}

    local found = false
    local active_colliders = {}
    for i = 1, #active_collider_list do
        local active_part, active_group_id, active_set_id = active_collider_list[i].part, active_collider_list[i].group, active_collider_list[i].set
        -- local active_collider_set = wp_colliders[active_group_id][active_set_id]
        local num_collidables = get_num_collidables(active_part, active_group_id, active_set_id)
        for k = 0, num_collidables - 1 do
            local collider_weapon_type = active_part
            if active_part == "Weapon" then
                if tostring(weapon_type):find("^Sub") then goto continue end
                -- if is subweapon then weapon type already have prefix "Sub"
                collider_weapon_type = weapon_type
            end
            if active_part == "SubWeapon" then
                if not tostring(weapon_type):find("^Sub") then goto continue end
                -- if is subweapon then weapon type already have prefix "Sub"
                collider_weapon_type = weapon_type
            end
            local collider = get_collider(collider_weapon_type, active_group_id, active_set_id, k)
            -- log.debug(string.format("%x", collider:get_address()))
            active_colliders[#active_colliders + 1] = {
                weapon_type = collider_weapon_type,
                group = active_group_id,
                set = active_set_id,
                col = k,
                collider = collider,
            }
            if collider == collidable then
                found = true
            end
            ::continue::
        end
    end
    if not found then
        -- log.debug("not found: " .. string.format("%x", collidable:get_address()))
        output[1] = {
            weapon_type = nil,
            group = nil,
            set = nil,
            col = nil,
            enabled = false,
        }
        extract_collider_properties(collidable, output[1])
    else
        for i = 1, #active_colliders do
            local active_collider = active_colliders[i]
            local key = get_collider_key(active_collider.weapon_type, active_collider.group, active_collider.set, active_collider.col)
            local default_collider = get_default_collider(key)
            if default_collider then 
                output[i] = default_collider 
            else
                output[i] = {
                    weapon_type = active_collider.weapon_type,
                    group = active_collider.group,
                    set = active_collider.set,
                    col = active_collider.col,
                    enabled = false,
                }
                extract_collider_properties(active_collider.collider, output[i])
            end
        end
    end
    return output
end

local function get_kinsect_colliders(collidable)
    local output = {}

    local found = false
    local active_colliders = {}
    local set_count = get_kinsect_num_sets(0)
    for set_id = 0, set_count - 1 do
        active_colliders = {}
        local num_collidables = get_kinsect_num_collidables(0, set_id)
        if num_collidables then
            for col = 0, num_collidables - 1 do
                local collider = get_kinsect_collider(0, set_id, col)
                if collider and collider == collidable then
                    found = true
                end
                active_colliders[#active_colliders + 1] = {
                    weapon_type = "Kinsect",
                    group = 0,
                    set = set_id,
                    col = col,
                    collider = collider,
                }
            end
        end
        if found then break end
    end
    
    if not found then
        -- log.debug("not found: " .. string.format("%x", collidable:get_address()))
        output[1] = {
            weapon_type = nil,
            group = nil,
            set = nil,
            col = nil,
            enabled = false,
        }
        extract_collider_properties(collidable, output[1])
    else
        for i = 1, #active_colliders do
            local active_collider = active_colliders[i]
            local key = get_collider_key(active_collider.weapon_type, active_collider.group, active_collider.set, active_collider.col)
            local default_collider = get_default_collider(key)
            if default_collider then 
                output[i] = default_collider 
            else
                output[i] = {
                    weapon_type = active_collider.weapon_type,
                    group = active_collider.group,
                    set = active_collider.set,
                    col = active_collider.col,
                    enabled = false,
                }
                extract_collider_properties(active_collider.collider, output[i])
            end
        end
    end
    return output
end

local function get_shell_colliders(collidable, shell_collider_queue)
    for i = #shell_collider_queue, 1, -1 do
        local shell_colliders = shell_collider_queue[i]
        for _, shell_collider in ipairs(shell_colliders) do
            if shell_collider.address == collidable:get_address() then
                return shell_colliders
            end
        end
    end

    -- local rsc = shell_collider_queue[#shell_collider_queue][1].rsc
    -- if rsc then
    --     for group = 0, 100 do
    --         local num_sets = rsc:getNumRequestSetsFromIndex(group)
    --         if num_sets then
    --             for set = 0, 500 do
    --                 local num_collidables = rsc:getNumCollidablesFromIndex(group, set)
    --                 for col = 0, num_collidables - 1 do
    --                     local collider = rsc:getCollidableFromIndex(group, set, col)
    --                     if collider and collider == collidable then
    --                         log.debug("[MVManager] Found shell collider in RSC: " .. get_collider_key(shell_collider_queue[#shell_collider_queue][1].weapon_type, group, set, col))
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- log.debug("not found: " .. string.format("%x", collidable:get_address()))
    local output = {}
    output[1] = {
        weapon_type = nil,
        group = nil,
        set = nil,
        col = nil,
        enabled = false,
    }
    extract_collider_properties(collidable, output[1])
    return output
end

local function set_collider(collider_config, force, collider)
    local function vec3(val)
        return Vector3f.new(val[1], val[2], val[3])
    end
    if not collider then
        collider = get_collider(collider_config.weapon_type, collider_config.group, collider_config.set, collider_config.col)
    end
    local shape = collider:get_Shape()
    local shape_type = collider_config.shape_type
    if shape_type == "via.physics.ContinuousCapsuleShape" or shape_type == "via.physics.CapsuleShape" then
        local capsule = shape:get_Capsule()
        if collider_config.start_pos.enabled or force then
            capsule:set_field("p0", vec3(collider_config.start_pos.value))
        end
        if collider_config.end_pos.enabled or force then
            capsule:set_field("p1", vec3(collider_config.end_pos.value))
        end
        if collider_config.radius.enabled or force then
            capsule:set_field("r", collider_config.radius.value)
        end
        shape:set_Capsule(capsule)
    elseif shape_type == "via.physics.ContinuousSphereShape" or shape_type == "via.physics.SphereShape" then
        local sphere = shape:get_Sphere()
        if collider_config.center.enabled or force then
            sphere:set_field("pos", vec3(collider_config.center.value))
        end
        if collider_config.radius.enabled or force then
            sphere:set_field("r", collider_config.radius.value)
        end
        shape:set_Sphere(sphere)
    end

    collider:set_Shape(shape)
end

local function set_colliders()
    local preset_managed_colliders = {}
    for preset_name, preset in pairs(preset_configs) do
        for _, motion_config in pairs(preset.motion_configs) do
            if not motion_config.colliders then goto continue end
            for _, collider_config in ipairs(motion_config.colliders) do
                if not collider_config or collider_config.weapon_type == nil then goto continue1 end
                -- check weapon state
                local is_weapon = collider_config.weapon_type == "Body"
                local current_wp_type = get_wp_type()
                local current_subwp_type = "Sub" .. tostring(current_wp_type)
                local is_weapon = is_weapon or collider_config.weapon_type == current_wp_type
                local is_weapon = is_weapon or collider_config.weapon_type == current_subwp_type
                local is_weapon = is_weapon or (collider_config.weapon_type == "Kinsect" and current_wp_type == 10)
                if not is_weapon then goto continue1 end
                local enabled = config.enabled and preset.enabled and motion_config.enabled and collider_config.enabled
                local key = get_collider_key(collider_config.weapon_type, collider_config.group, collider_config.set, collider_config.col)
                if not enabled and preset_managed_colliders[key] then goto continue1 end
                collider_config = enabled and collider_config or get_default_collider(key)
                set_collider(collider_config, not enabled)
                if enabled then preset_managed_colliders[key] = true end
                ::continue1::
            end
            ::continue::
        end
    end
end

local function get_shell_collider_config(query)
    local output = {}
    for preset_name, preset in pairs(preset_configs) do
        if not preset.enabled then goto continue end
        for _, motion_config in pairs(preset.motion_configs) do
            if not motion_config.enabled or not motion_config.shell_colliders then goto continue1 end
            for _, collider_config in ipairs(motion_config.shell_colliders) do
                if not collider_config or collider_config.weapon_type == nil or not collider_config.enabled then goto continue2 end
                local key = get_collider_key(collider_config.weapon_type, collider_config.group, collider_config.set, collider_config.col)
                if query == key then
                    output[#output + 1] = collider_config
                end
                ::continue2::
            end
            ::continue1::
        end
        ::continue::
    end
    return output
end

local function show_colliders(hit_data)
    local colliders = {}
    -- Combine colliders and shell_colliders into one table
    if hit_data.colliders then
        for i, v in pairs(hit_data.colliders) do
            colliders[i] = v
        end
    end
    if hit_data.shell_colliders then
        local offset = #colliders
        for i, v in pairs(hit_data.shell_colliders) do
            colliders[offset + i] = v
        end
    end
    if not colliders then return end
    for i, collider in spairs(colliders) do
        if not collider then goto continue end
        local id_text = ""
        if collider.group == nil or collider.set == nil or collider.col == nil then
            id_text = "Unsupported collider"
        else
            id_text = get_collider_key(collider.weapon_type, collider.group, collider.set, collider.col)
        end
        if imgui.tree_node(tostring(i) .. " - " .. collider.shape_type .. " (" .. id_text .. ")") then
            if collider then
                local shape_type = collider.shape_type
                imgui.text(string.format("Type: %s", shape_type))
                if shape_type == "via.physics.ContinuousCapsuleShape" or shape_type == "via.physics.CapsuleShape" then
                    local start_pos = collider.start_pos.value
                    local end_pos = collider.end_pos.value
                    local radius = collider.radius.value
                    imgui.text(string.format("Start: %.2f, %.2f, %.2f", start_pos[1], start_pos[2], start_pos[3]))
                    imgui.text(string.format("End: %.2f, %.2f, %.2f", end_pos[1], end_pos[2], end_pos[3]))
                    imgui.text(string.format("Radius: %.2f", radius))
                elseif shape_type == "via.physics.ContinuousSphereShape" or shape_type == "via.physics.SphereShape" then
                    local center = collider.center.value
                    local radius = collider.radius.value
                    imgui.text(string.format("Center: %.2f, %.2f, %.2f", center[1], center[2], center[3]))
                    imgui.text(string.format("Radius: %.2f", radius))
                end
            end
            imgui.tree_pop()
        end
        ::continue::
    end
end

local function ui_colliders(colliders)
    local function imgui_vec3(config_var, label)
        local vec3 = Vector3f.new(config_var[1], config_var[2], config_var[3])
        changed, vec3 = imgui.drag_float3(label, vec3, 0.01, -100.0, 100.0)
        config_var[1] = vec3.x
        config_var[2] = vec3.y
        config_var[3] = vec3.z
        return changed
    end
    if not colliders then return false end
    local changed, any_changed = false, false
    for i, collider in spairs(colliders) do
        if not collider then goto continue end
        local id_text = get_collider_key(collider.weapon_type, collider.group, collider.set, collider.col)
        if imgui.tree_node(tostring(i) .. " - " .. collider.shape_type .. " (" .. id_text .. ")") then
            changed, collider.enabled = imgui.checkbox("Enabled", collider.enabled)
            any_changed = any_changed or changed
            local shape_type = collider.shape_type
            if shape_type == "via.physics.ContinuousCapsuleShape" or shape_type == "via.physics.CapsuleShape" then
                changed, collider.start_pos.enabled = imgui.checkbox("Start Position: ", collider.start_pos.enabled)
                any_changed = any_changed or changed
                imgui.same_line()
                changed = imgui_vec3(collider.start_pos.value, "##Start Position")
                any_changed = any_changed or changed

                changed, collider.end_pos.enabled = imgui.checkbox("End Position: ", collider.end_pos.enabled)
                any_changed = any_changed or changed
                imgui.same_line()
                changed = imgui_vec3(collider.end_pos.value, "##End Position")
                any_changed = any_changed or changed

                changed, collider.radius.enabled = imgui.checkbox("Radius: ", collider.radius.enabled)
                any_changed = any_changed or changed
                imgui.same_line()
                changed, collider.radius.value = imgui.drag_float("##Radius", collider.radius.value, 0.01, 0.0, 100.0, "%.2f")
                any_changed = any_changed or changed
            elseif shape_type == "via.physics.ContinuousSphereShape" or shape_type == "via.physics.SphereShape" then
                changed, collider.center.enabled = imgui.checkbox("Center: ", collider.center.enabled)
                any_changed = any_changed or changed
                imgui.same_line()
                changed = imgui_vec3(collider.center.value, "##Center")
                any_changed = any_changed or changed

                changed, collider.radius.enabled = imgui.checkbox("Radius: ", collider.radius.enabled)
                any_changed = any_changed or changed
                imgui.same_line()
                changed, collider.radius.value = imgui.drag_float("##Radius", collider.radius.value, 0.01, 0.0, 100.0, "%.2f")
                any_changed = any_changed or changed
            end
            imgui.tree_pop()
        end
        ::continue::
    end
    return any_changed
end

-----------------------------
-- core
-----------------------------
local hit_data_queue = {}
local max_queue_size = 20
local function push_queue(queue, data)
    table.insert(queue, data)
    if #queue > max_queue_size then
        table.remove(queue, 1)
    end
end

local should_set_colliders = true
local has_reset_collider_list = false
local active_collider_list = {}

local shell_collider_queue = {}
local max_shell_collider_queue_size = 20

re.on_frame(
    function()
        if should_set_colliders then
            local success = pcall(function()
                set_colliders()
            end)
            if success then
                log.info("[MVManager] set colliders success")
                should_set_colliders = false
            end
        end
        has_reset_collider_list = false
    end
)

-- third party custom config getter
local third_party_property_getter = {}
function register_third_party_property_getter(name, func)
    if type(name) ~= "string" or type(func) ~= "function" then
        log.error("[MVManager] Invalid arguments to register_third_party_property_getter")
        return
    end
    third_party_property_getter[name] = func
end

-----------------------------
-- on hit
-----------------------------
local function get_key(hit_data)
    return string.format("%s_%s_%d", tostring(hit_data.weapon_type), hit_data.attack_owner_name, hit_data.attack_index)
end
-- app.Wp10Insect.evAttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.Wp10Insect"):get_method("evAttackPreProcess(app.HitInfo)"), 
function(args)
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
        weapon_type = "Kinsect",
        attack_index = hit_info:get_field("<AttackIndex>k__BackingField")._Index,
        attack_owner_name = hit_info:get_field("<AttackOwner>k__BackingField"):get_Name(),
        attack_owner_tag = hit_info:get_field("<AttackOwner>k__BackingField"):get_Tag(),
        attack_name = attack_data:get_field("_UserData"):get_Name(),
    }
    hit_data.key = get_key(hit_data)

    local motion_config = get_motion_config(hit_data.key)
    for name, func in pairs(third_party_property_getter) do
        local properties = func(this, hit_info)
        if properties then
            motion_config.enabled = true
            motion_config.properties = properties
            break
        end
    end

    if reframework:is_drawing_ui() then
        hit_data.name = motion_config.name
        hit_data.preset_id = motion_config.preset_id

        hit_data.properties = get_properties(attack_data)
        if hit_data.properties.IsSensor.value then return end
        hit_data.colliders = get_kinsect_colliders(hit_info:get_field("<AttackCollidable>k__BackingField"))
        hit_data.shell_colliders = {}

        push_queue(hit_data_queue, hit_data)
    end

    if motion_config.enabled then
        set_properties(attack_data, motion_config.properties)
    end
end, nil)

-- app.Weapon.evHit_AttackPreProcess(app.HitInfo)
local is_weapon_hit = nil
sdk.hook(sdk.find_type_definition("app.Weapon"):get_method("evHit_AttackPreProcess(app.HitInfo)"),
function(args)
    local this = sdk.to_managed_object(args[2])
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end

    if this:get_IsSubWeapon() then
        is_weapon_hit = "SubWeapon"
    else
        is_weapon_hit = "Weapon"
    end
end, function(retval)
    is_weapon_hit = nil
    return retval
end)

--app.mcShellColHit.evAttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.mcShellColHit"):get_method("evAttackPreProcess(app.HitInfo)"),
function(args)
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
    if is_weapon_hit == "SubWeapon" then
        weapon_type = "Sub" .. tostring(weapon_type)
    end

    local hit_data = {
        weapon_type = weapon_type,
        attack_index = hit_info:get_field("<AttackIndex>k__BackingField")._Index,
        attack_owner_name = hit_info:get_field("<AttackOwner>k__BackingField"):get_Name(),
        attack_owner_tag = hit_info:get_field("<AttackOwner>k__BackingField"):get_Tag(),
        attack_name = attack_data:get_field("_UserData"):get_Name(),
    }
    hit_data.key = get_key(hit_data)

    local motion_config = get_motion_config(hit_data.key)
    for name, func in pairs(third_party_property_getter) do
        local properties = func(this, hit_info)
        if properties then
            motion_config.enabled = true
            motion_config.properties = properties
            break
        end
    end

    if reframework:is_drawing_ui() then
        hit_data.name = motion_config.name
        hit_data.preset_id = motion_config.preset_id

        hit_data.properties = get_properties(attack_data)
        if hit_data.properties.IsSensor.value then return end

        hit_data.shell_colliders = get_shell_colliders(hit_info:get_field("<AttackCollidable>k__BackingField"), shell_collider_queue)
        hit_data.colliders = {}

        push_queue(hit_data_queue, hit_data)
    end

    if motion_config.enabled then
        set_properties(attack_data, motion_config.properties)
    end

end, function(retval)
    -- is_weapon_hit = nil
    return retval
end)

-- app.HunterCharacter.evHit_AttackPreProcess(app.HitInfo)
sdk.hook(sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_AttackPreProcess(app.HitInfo)"), 
function(args)
    if not config.enabled then return end
    local this_hunter = sdk.to_managed_object(args[2])
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    local hit_info = sdk.to_managed_object(args[3])
    if not hit_info then return end
    local attack_data = hit_info:get_field("<AttackData>k__BackingField")
    if not attack_data then return end

    local weapon_type = attack_data._WeaponType
    if is_weapon_hit == "SubWeapon" then
        weapon_type = "Sub" .. tostring(weapon_type)
    end

    local hit_data = {
        weapon_type = weapon_type,
        attack_index = hit_info:get_field("<AttackIndex>k__BackingField")._Index,
        attack_owner_name = hit_info:get_field("<AttackOwner>k__BackingField"):get_Name(),
        attack_owner_tag = hit_info:get_field("<AttackOwner>k__BackingField"):get_Tag(),
        attack_name = attack_data:get_field("_UserData"):get_Name(),
    }

    if contains_token(hit_data.attack_owner_tag, "Shell") then return end

    hit_data.key = get_key(hit_data)

    local motion_config = get_motion_config(hit_data.key)
    for name, func in pairs(third_party_property_getter) do
        local properties = func(this, hit_info)
        if properties then
            motion_config.enabled = true
            motion_config.properties = properties
            break
        end
    end

    if reframework:is_drawing_ui() then
        hit_data.name = motion_config.name
        hit_data.preset_id = motion_config.preset_id

        hit_data.properties = get_properties(attack_data)
        if hit_data.properties.IsSensor.value then return end

        hit_data.colliders = get_colliders(hit_info:get_field("<AttackCollidable>k__BackingField"), active_collider_list, hit_data.weapon_type)
        hit_data.shell_colliders = {}

        push_queue(hit_data_queue, hit_data)
    end

    if motion_config.enabled then
        set_properties(attack_data, motion_config.properties)
    end
end, nil)

-----------------------------
-- on activate collision
-----------------------------
-- app.Weapon.evMotionTrack_AttackCollision(app.motion_track.AttackCollision_PlWp, ace.MOTION_SEQUENCE_UPDATER_ARGS)
local in_attack_collision = nil
sdk.hook(sdk.find_type_definition("app.Weapon"):get_method("evMotionTrack_AttackCollision(app.motion_track.AttackCollision_PlWp, ace.MOTION_SEQUENCE_UPDATER_ARGS)"),
function(args)
    if not reframework:is_drawing_ui() then return end
    local this = sdk.to_managed_object(args[2])
    local this_hunter = this:get_Hunter()
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    if not has_reset_collider_list then
        active_collider_list = {}
        has_reset_collider_list = true
    end
    local is_sub = this:get_IsSubWeapon()
    if is_sub then
        in_attack_collision = "SubWeapon"
    else
        in_attack_collision = "Weapon"
    end
end, function(retval)
    in_attack_collision = nil
    return retval
end, nil)

-- app.HunterCharacter.cMotionSupporter.evMotionTrack_AttackCollision(app.motion_track.AttackCollision_PlBody, ace.MOTION_SEQUENCE_UPDATER_ARGS)
sdk.hook(sdk.find_type_definition("app.HunterCharacter.cMotionSupporter"):get_method("evMotionTrack_AttackCollision(app.motion_track.AttackCollision_PlBody, ace.MOTION_SEQUENCE_UPDATER_ARGS)"),
function(args)
    if not reframework:is_drawing_ui() then return end
    local this = sdk.to_managed_object(args[2])
    local this_hunter = this._Chara
    if not this_hunter then return end
    if not (this_hunter:get_IsMaster() and this_hunter:get_IsUserControl()) then return end
    if not has_reset_collider_list then
        active_collider_list = {}
        has_reset_collider_list = true
    end
    in_attack_collision = "Body"
end, function(retval)
    in_attack_collision = nil
    return retval
end, nil)

sdk.hook( -- credits to kmyx
	sdk.find_type_definition("app.ColliderSwitcher"):get_method(
		"activateAttack(System.Boolean, System.UInt32, System.UInt32, System.Nullable`1<System.Boolean>, app.Hit.HIT_ID_GROUP, System.Nullable`1<System.Single>, System.Nullable`1<System.Single>)"
	),
	function(args)
        if not in_attack_collision then return end
        local this = sdk.to_managed_object(args[2])
        local rsc = this:get_RequestSetCollider()
        local group_index = sdk.to_int64(args[4]) & 0xFFFFFFFF
		local set_index = sdk.to_int64(args[5]) & 0xFFFFFFFF
        active_collider_list[#active_collider_list + 1] = {
            part = in_attack_collision,
            group = group_index,
            set = set_index,
        }
    end, nil
)

-----------------------------
-- on create shell collider
-----------------------------

local in_create_shell = false
local set_ids = nil

local function handle_shell_colliders(shell_col_hit)
    if not shell_col_hit or set_ids == nil then return end
    local hit_controller = shell_col_hit:get_field("_HitController")
    local owner = hit_controller:get_field("_Owner")
    local owner_name = owner:get_Name()
    local shell_collider = hit_controller:get_field("_ReqSetCollider")

    local group_id = shell_col_hit._CollisionResourceIndex

    local active_colliders = {}
    for _, set_id in ipairs(set_ids) do
        local num_collidables = shell_collider:getNumCollidables(group_id, set_id)
        for k = 0, num_collidables - 1 do
            local collider = shell_collider:getCollidable(group_id, set_id, k)
            if not collider then goto continue end
            active_colliders[#active_colliders + 1] = {
                weapon_type = owner_name,
                group = group_id,
                set = set_id,
                col = k,
                collider = collider,
            }
            ::continue::
        end
    end

    local output = {}

    for i = 1, #active_colliders do
        local active_collider = active_colliders[i]
        local key = get_collider_key(active_collider.weapon_type, active_collider.group, active_collider.set, active_collider.col)
        if reframework:is_drawing_ui() then
            output[i] = {
                weapon_type = active_collider.weapon_type,
                group = active_collider.group,
                set = active_collider.set,
                col = active_collider.col,
                enabled = false,
                address = active_collider.collider:get_address(),
                -- rsc = shell_collider,
            }
            extract_collider_properties(active_collider.collider, output[i])
        end

        collider_configs = get_shell_collider_config(key)
        for _, collider_config in ipairs(collider_configs) do
            set_collider(collider_config, false, active_collider.collider)
        end
    end
    if reframework:is_drawing_ui() then
        push_queue(shell_collider_queue, output)
    end
end

-- app.mcShellColHit.setupCollision()
local shell_col_hit = nil
sdk.hook(sdk.find_type_definition("app.mcShellColHit"):get_method("setupCollision"),
function(args)
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

    in_create_shell = true
    set_ids = nil
    shell_col_hit = sdk.to_managed_object(args[2])
end, function(retval)
    if not in_create_shell then return retval end
    in_create_shell = false
    handle_shell_colliders(shell_col_hit)
    return retval
end)

-- app.mcShellPlPenetrateHit.onSetup()
local shell_post_threads = {}
local function shell_post_pre(args)
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
    
    if #shell_post_threads == 0 then
        set_ids = nil
    end

    shell_post_threads[#shell_post_threads + 1] = this
end

local function shell_post_post(retval)
    if #shell_post_threads == 0 then return retval end
    local this = shell_post_threads[1]
    table.remove(shell_post_threads, 1)
    local shell_col_hit = this._ShellColHitComponent
    handle_shell_colliders(shell_col_hit)
    return retval
end

sdk.hook(sdk.find_type_definition("app.mcShellPlPenetrateHit"):get_method("onSetup()"), shell_post_pre, shell_post_post)
sdk.hook(sdk.find_type_definition("app.mcShellPlWp11Arrow"):get_method("applyBottle()"), shell_post_pre, shell_post_post)
sdk.hook(sdk.find_type_definition("app.mcShellPlWp09"):get_method("onSetup()"), shell_post_pre, shell_post_post)

sdk.hook(sdk.find_type_definition("app.HitController"):get_method("refreshHitID(System.UInt32, app.Hit.HIT_ID_GROUP, System.UInt32)"),
function(args)
    if not in_create_shell and #shell_post_threads == 0 then return end
    set_ids = set_ids or {}
    local this_id = sdk.to_int64(args[3]) & 0xFFFFFFFF
    local already_exists = false
    for _, v in ipairs(set_ids) do
        if v == this_id then
            already_exists = true
            break
        end
    end
    if not already_exists then
        set_ids[#set_ids + 1] = this_id
    end
end, nil)

-----------------------------
-- change weapon
-----------------------------
-- app.mcHunterWeaponBuilder.updateRegularWp(System.Boolean)
sdk.hook(sdk.find_type_definition("app.mcHunterWeaponBuilder"):get_method("updateRegularWp(System.Boolean)"),
function(args)
    should_set_colliders = true
end, nil)

-----------------------------
-- ui
-----------------------------
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

local presets_to_delete = {}
local presets_to_clear = {}
local motions_to_delete = {}
re.on_draw_ui(function()
    local changed, any_changed = false, false
    if not should_set_colliders then
        for preset_name, preset_config in pairs(presets_to_delete) do
            preset_config.deleted = true
            json.dump_file(preset_dir .. preset_name .. ".json", preset_config)
            any_changed = true
        end
        presets_to_delete = {}

        for preset_name, preset_enabled in pairs(presets_to_clear) do
            local preset_config = preset_configs[preset_name]
            preset_config.enabled = preset_enabled
            preset_config.motion_configs = {}
            preset_config.default_colliders = {}
        end
        presets_to_clear = {}

        for preset_name, motion_key in pairs(motions_to_delete) do
            local motion_configs = preset_configs[preset_name].motion_configs
            motion_configs[motion_key] = nil
        end
        motions_to_delete = {}
    end

    if imgui.tree_node("Motion Value Manager") then
        changed, config.enabled = imgui.checkbox("Enabled", config.enabled)
        if changed then should_set_colliders = true end

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
                    imgui.text("Attack Name: " .. hit_data.attack_name)
                    if imgui.tree_node("Default Properties") then
                        show_properties(hit_data.properties)
                        imgui.tree_pop()
                    end
                    if imgui.tree_node("Default Collider") then
                        show_colliders(hit_data)
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
                        preset_configs[preset_name].motion_configs[hit_data.key].weapon_type = hit_data.weapon_type
                        preset_configs[preset_name].motion_configs[hit_data.key].attack_index = hit_data.attack_index
                        preset_configs[preset_name].motion_configs[hit_data.key].attack_owner_name = hit_data.attack_owner_name
                        preset_configs[preset_name].motion_configs[hit_data.key].attack_owner_tag = hit_data.attack_owner_tag
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
                        preset_configs[preset_name].motion_configs[hit_data.key].colliders = {}
                        for i, collider in spairs(hit_data.colliders) do
                            if collider.group and collider.set and collider.col then
                                local collider_key = get_collider_key(collider.weapon_type, collider.group, collider.set, collider.col)
                                preset_configs[preset_name].default_colliders[collider_key] = collider
                                local new_collider = copy_table(collider)
                                preset_configs[preset_name].motion_configs[hit_data.key].colliders[i] = new_collider
                            end
                        end
                        preset_configs[preset_name].motion_configs[hit_data.key].shell_colliders = {}
                        for i, shell_collider in spairs(hit_data.shell_colliders) do
                            if shell_collider.group and shell_collider.set and shell_collider.col then
                                local new_shell_collider = copy_table(shell_collider)
                                new_shell_collider.address = nil
                                preset_configs[preset_name].motion_configs[hit_data.key].shell_colliders[i] = new_shell_collider
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
                    if changed then should_set_colliders = true end

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
                                if changed then should_set_colliders = true end
                                if imgui.tree_node("Properties") then
                                    ui_properties(motion_config.properties)
                                    imgui.tree_pop()
                                end
                                if imgui.tree_node("Colliders") then
                                    changed = ui_colliders(motion_config.colliders)
                                    if changed then should_set_colliders = true end
                                    changed = ui_colliders(motion_config.shell_colliders)
                                    imgui.tree_pop()
                                end

                                if imgui.button("Remove Motion") then
                                    motions_to_delete[preset_name] = key
                                    motion_config.enabled = false
                                    should_set_colliders = true
                                end
                                imgui.tree_pop()
                            end
                        end
        
                        imgui.tree_pop()
                    end
        
                    if imgui.button("Clear Preset") then
                        presets_to_clear[preset_name] = preset_config.enabled
                        preset_config.enabled = false
                        should_set_colliders = true
                    end

                    changed, UI_vars.preset_save_as = imgui.input_text("Save As", UI_vars.preset_save_as)

                    if imgui.button("Save Preset") then
                        json.dump_file(preset_dir .. UI_vars.preset_save_as .. ".json", preset_config)
                        any_changed = true
                    end

                    if preset_name ~= "default" then
                        if imgui.button("Delete Preset") then
                            preset_config.enabled = false
                            presets_to_delete[preset_name] = preset_config
                            should_set_colliders = true
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

-- expose API
_MV_MANAGER = {}
_MV_MANAGER.get_empty_property_config = get_empty_property_config
_MV_MANAGER.ui_properties = ui_properties
_MV_MANAGER.register_third_party_property_getter = register_third_party_property_getter
-- args: name, func(this, hit_info) -> motion_config or nil
_MV_MANAGER.set_properties = set_properties