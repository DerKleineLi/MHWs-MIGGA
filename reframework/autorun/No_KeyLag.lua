-- const
key_names = {[0]="triangle", [1]="circle", [2]="R2", [3]="R1", [6]="square", [7]="cross"}
weapon_names = {[0]="Great Sword", [1]="Sword & Shield", [2]="Dual Blades", [3]="Long Sword", [4]="Hammer", [5]="Hunting Horn", [6]="Lance", [7]="Gunlance", [8]="Switch Axe", [9]="Charge Blade", [10]="Insect Glaive", [11]="Bow", [12]="Heavy Bowgun", [13]="Light Bowgun"}
local function default_wps()
    return {
        [0]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [1]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05, [6]=0.05},
        [2]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [3]={[0]=0.05, [1]=0.05, [2]=0.1, [3]=0.05, [7]=0.1},
        [4]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [5]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05, [7]=0.05},
        [6]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [7]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [8]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [9]={[0]=0.05, [1]=0.05, [2]=0.02, [3]=0.05},
        [10]={[0]=0.05, [1]=0.05, [2]=0.1, [3]=0.05, [7]=0.1},
        [11]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [12]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
        [13]={[0]=0.05, [1]=0.05, [2]=0.05, [3]=0.05},
    }
end

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

local function convert_keys_to_integers(t)
    local new_table = {}
    for k, v in pairs(t) do
        local num_key = tonumber(k)
        if num_key then
            new_table[num_key] = v
        else
            new_table[k] = v
        end
        if type(v) == "table" then
            new_table[num_key or k] = convert_keys_to_integers(v)
        end
    end
    return new_table
end

local saved_config = json.load_file("No_KeyLag_settings.json") or {}
saved_config = convert_keys_to_integers(saved_config)

local config = {
    enabled = true,
    wps = default_wps()
}

merge_tables(config, saved_config)


-- vars
local on_weapon_change = false
local weapon_idx = -1
local cPlayerCommandController = nil

-- main function
local function overwrite_keylag()
    if not config.enabled then return end
    if weapon_idx == -1 then return end
    if not cPlayerCommandController then return end

    target = config.wps[weapon_idx]
    local merged_virtual_input = cPlayerCommandController:get_MergedVirtualInput()
    for k, v in pairs(target) do
        local key = merged_virtual_input:getKey(k)
        if key then
            key:set_LagTime(v)
        end
    end
end

-- hooks
sdk.hook(sdk.find_type_definition("app.HunterCharacter.cHunterExtendPlayer"):get_method("systemInputSetting"), function(args)
    local cHunterExtendPlayer = sdk.to_managed_object(args[2])
    if not cHunterExtendPlayer then return end
    local is_master = cHunterExtendPlayer:get_IsMaster()
    if not is_master then return end
    on_weapon_change = true
end, function(retval)
    on_weapon_change = false
end)

sdk.hook(sdk.find_type_definition("app.cPlayerCatalogHolder"):get_method("getWeaponActionParam(app.WeaponDef.TYPE)"), function(args)
    if not on_weapon_change then return end
    weapon_idx = sdk.to_int64(args[3])
end, nil)

sdk.hook(sdk.find_type_definition("app.cPlayerCommandController"):get_method("systemMergedInputSetting"), function(args)
    cPlayerCommandController = sdk.to_managed_object(args[2])
end, function(retval)
    overwrite_keylag()
end)


-- UI
re.on_draw_ui(function()
    local changed, any_changed = false, false

    if imgui.tree_node("No KeyLag") then
        changed, config.enabled = imgui.checkbox("Enable", config.enabled)

        if imgui.tree_node("Weapon Key Lag Settings") then
            for weapon_idx, weapon_name in pairs(weapon_names) do
                if imgui.tree_node(weapon_name) then
                    for key_idx, key_lag in pairs(config.wps[weapon_idx]) do
                        local key_name = key_names[key_idx]
                        changed, key_lag = imgui.drag_float(key_name, key_lag, 0.0001, 0, 0.2, "%.2f")
                        if changed then
                            config.wps[weapon_idx][key_idx] = key_lag
                            any_changed = true
                        end
                    end
                    if imgui.button("Reset") then
                        config.wps[weapon_idx] = default_wps()[weapon_idx]
                        any_changed = true
                    end
                    imgui.tree_pop()
                end
            end
            imgui.tree_pop()
        end

        if any_changed then
            overwrite_keylag()
        end
        imgui.tree_pop()
    end
end)

re.on_config_save(
    function()
        json.dump_file("No_KeyLag_settings.json", config)
    end
)