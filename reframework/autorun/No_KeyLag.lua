--[[
Put this lua file into the steamapps\common\MonsterHunterWilds\reframework\autorun folder
把这个lua文件放到steamapps\common\MonsterHunterWilds\reframework\autorun文件夹中
このluaファイルをsteamapps\common\MonsterHunterWilds\reframework\autorunフォルダに入れてください
Enregistrez ce code dans un fichier .lua à l'emplacement steamapps\common\MonsterHunterWilds\reframework\autorun
--]]

--[[
MOD Name: Input Lag Customizer (Formerly No KeyLag)
Description: Remove or customize input lag for various actions (dodging, attacks).
Allows choosing display format (PS, Xbox, KB/M) in UI.
Allows choosing language (English, Chinese, Japanese, French) in UI.
--]]

-- --- Constants ---

-- Weapon ID to internal name mapping (Used for translation keys)
local weapon_ids = {
    [0]="weapon_0", [1]="weapon_1", [2]="weapon_2", [3]="weapon_3", [4]="weapon_4",
    [5]="weapon_5", [6]="weapon_6", [7]="weapon_7", [8]="weapon_8", [9]="weapon_9",
    [10]="weapon_10", [11]="weapon_11", [12]="weapon_12", [13]="weapon_13"
}

-- Valid Key Indices targeted by this mod
local valid_key_indices = {[0]=true, [1]=true, [2]=true, [3]=true, [6]=true, [7]=true}

-- Language options
local languages = {
    { code = "en", name = "English" }, -- English first now
    { code = "zh", name = "中文" },
    { code = "jp", name = "日本語" },
    { code = "fr", name = "Français" },
}
local language_names = {} -- For combo box display
local language_codes = {} -- For mapping index back to code
for i, lang in ipairs(languages) do
    table.insert(language_names, lang.name)
    language_codes[i] = lang.code
end

-- --- UI Text Translations ---
local texts = {
    zh = {
        mod_title = "输入延迟自定义器 (No KeyLag)",
        enable_mod_label = "启用 Mod",
        language_label = "语言:",
        display_mode_label = "按键显示模式:",
        note_line1 = "注意：按键显示模式只会影响界面上按键名称的显示，不影响 Mod 的实际效果。",
        note_line2 = "即使你在游戏中重新绑定了按键，Mod 仍会对实际使用的按键生效，只是界面中显示的仍是默认按键。",
        weapon_settings_label = "武器按键延迟设置",
        reset_button_label = "重置为默认值",
        weapon_0 = "大剑", weapon_1 = "片手剑", weapon_2 = "双刀", weapon_3 = "太刀", weapon_4 = "大锤",
        weapon_5 = "狩猎笛", weapon_6 = "长枪", weapon_7 = "铳枪", weapon_8 = "斩斧", weapon_9 = "盾斧",
        weapon_10 = "操虫棍", weapon_11 = "弓", weapon_12 = "重弩", weapon_13 = "轻弩",
        enabled_log = "Mod 已通过 UI 启用。",
        disabled_log = "Mod 已通过 UI 禁用。切换武器或重启游戏以确保恢复默认延迟。",
        display_mode_change_log = "显示模式已更改为: %s",
        language_change_log = "语言已更改为: %s",
        settings_applied_log = "正在为 [%s] 应用更改。",
        settings_reset_log = "正在重置 [%s] 的设置。",
        weapon_change_log = "武器已切换至索引: %d (%s)",
        initial_weapon_log = "检测到初始武器索引: %d (%s)",
        unknown_weapon = "未知武器",
        load_success_log = "设置已从 %s 加载。",
        load_failure_log = "未找到有效的设置文件或加载 '%s' 失败。使用默认值。",
        save_log = "正在保存设置到 %s",
        save_failure_log = "保存设置失败: %s",
        mod_init_log = "Mod 已初始化。",
        error_get_mvi = "获取 MergedVirtualInput 对象失败。错误: %s",
        error_get_key = "获取索引 %s 的按键失败。错误: %s",
        warn_set_lag = "为按键索引 %s 设置 LagTime (%s) 失败。错误: %s",
        error_no_weapon_settings = "未找到当前武器索引 %s 的设置。",
        error_controller_nil = "systemMergedInputSetting hook post 中的 cPlayerCommandController 为 nil。",
        warn_no_player = "无法获取 MainPlayer 对象。",
        warn_no_player_manager = "无法获取 PlayerManager 单例。",
        warn_get_weapon_type_fail = "调用 get_WeaponType 失败: %s",
        warn_no_get_weapon_type = "在 player 对象上找不到 get_WeaponType 方法。无法确定初始武器。",
        warn_invalid_initial_weapon = "检测到初始武器索引为 %s，该索引无效或未知。",
        error_reset_fail = "重置期间获取武器索引 %s 的默认设置失败。",
        display_modes = { [1]="PlayStation", [2]="Xbox", [3]="键鼠" }, -- Use 1-based index table for combo
        ps_key_names = {[0]="三角", [1]="圆圈", [2]="R2", [3]="R1", [6]="方块", [7]="叉"},
        xbox_key_names = {[0]="Y", [1]="B", [2]="RT", [3]="RB", [6]="X", [7]="A"},
        kbm_key_names = {[0]="左键", [1]="右键", [2]="R", [3]="Shift", [6]="E", [7]="空格"} -- LMB=Left Mouse, RMB=Right Mouse
    },
    en = {
        mod_title = "Input Lag Customizer (No KeyLag)",
        enable_mod_label = "Enable Mod",
        language_label = "Language:",
        display_mode_label = "Button Display Mode:",
        note_line1 = "Note: The button display mode only affects how button names appear in the UI and does not impact the mod's actual functionality.",
        note_line2 = "Even if you've remapped your keys in-game, the mod still works with your current key bindings — only the default key names are shown in the UI.",
        weapon_settings_label = "Weapon Key Lag Settings",
        reset_button_label = "Reset to Defaults",
        weapon_0 = "Great Sword", weapon_1 = "Sword & Shield", weapon_2 = "Dual Blades", weapon_3 = "Long Sword", weapon_4 = "Hammer",
        weapon_5 = "Hunting Horn", weapon_6 = "Lance", weapon_7 = "Gunlance", weapon_8 = "Switch Axe", weapon_9 = "Charge Blade",
        weapon_10 = "Insect Glaive", weapon_11 = "Bow", weapon_12 = "Heavy Bowgun", weapon_13 = "Light Bowgun",
        enabled_log = "Mod enabled via UI.",
        disabled_log = "Mod disabled via UI. Switch weapon or restart game to ensure default lag restoration.",
        display_mode_change_log = "Display mode changed to: %s",
        language_change_log = "Language changed to: %s",
        settings_applied_log = "Applying changes for [%s].",
        settings_reset_log = "Resetting settings for [%s].",
        weapon_change_log = "Weapon changed to index: %d (%s)",
        initial_weapon_log = "Initial weapon index detected: %d (%s)",
        unknown_weapon = "Unknown Weapon",
        load_success_log = "Settings loaded from %s.",
        load_failure_log = "No valid settings file found or failed to load '%s'. Using defaults.",
        save_log = "Saving settings to %s",
        save_failure_log = "Failed to save settings: %s",
        mod_init_log = "Mod initialized.",
        error_get_mvi = "Failed to get MergedVirtualInput object. Error: %s",
        error_get_key = "Failed to get key for index %s. Error: %s",
        warn_set_lag = "Failed to set LagTime (%s) for key index %s. Error: %s",
        error_no_weapon_settings = "No settings found for current weapon index: %s",
        error_controller_nil = "cPlayerCommandController is nil in systemMergedInputSetting hook post.",
        warn_no_player = "Could not get MainPlayer object.",
        warn_no_player_manager = "Could not get PlayerManager singleton.",
        warn_get_weapon_type_fail = "Failed to call get_WeaponType: %s",
        warn_no_get_weapon_type = "Cannot find get_WeaponType method on player object. Unable to determine initial weapon.",
        warn_invalid_initial_weapon = "Initial weapon index detected as %s, which is invalid or unknown.",
        error_reset_fail = "Failed to get default settings for weapon index %s during reset.",
        display_modes = { [1]="PlayStation", [2]="Xbox", [3]="Keyboard/Mouse" }, -- Use 1-based index table for combo
        ps_key_names = { [0]="Triangle", [1]="Circle", [2]="R2", [3]="R1", [6]="Square", [7]="Cross" },
        xbox_key_names = { [0]="Y", [1]="B", [2]="RT", [3]="RB", [6]="X", [7]="A" },
        kbm_key_names = { [0]="LMB", [1]="RMB", [2]="R", [3]="Shift", [6]="E", [7]="Space" } -- LMB=Left Mouse, RMB=Right Mouse
    },
    jp = {
        mod_title = "入力遅延カスタマイザー (No KeyLag)",
        enable_mod_label = "Modを有効化",
        language_label = "言語:",
        display_mode_label = "ボタン表示モード:",
        note_line1 = "注意：ボタン表示モードはUI上のボタン名の表示にのみ影響し、Modの実際の動作には影響しません。",
        note_line2 = "ゲーム内でキーを変更していても、Modは現在のキー設定に対して正しく動作します（UIにはデフォルトのキーが表示されます）。",
        weapon_settings_label = "武器キー遅延設定",
        reset_button_label = "デフォルトにリセット",
        weapon_0 = "大剣", weapon_1 = "片手剣", weapon_2 = "双剣", weapon_3 = "太刀", weapon_4 = "ハンマー",
        weapon_5 = "狩猟笛", weapon_6 = "ランス", weapon_7 = "ガンランス", weapon_8 = "スラッシュアックス", weapon_9 = "チャージアックス",
        weapon_10 = "操虫棍", weapon_11 = "弓", weapon_12 = "ヘビィボウガン", weapon_13 = "ライトボウガン",
        enabled_log = "UIからModが有効化されました。",
        disabled_log = "UIからModが無効化されました。デフォルトの遅延を復元するには、武器を切り替えるかゲームを再起動してください。",
        display_mode_change_log = "表示モードが次のように変更されました: %s",
        language_change_log = "言語が次のように変更されました: %s",
        settings_applied_log = "[%s] に変更を適用中。",
        settings_reset_log = "[%s] の設定をリセット中。",
        weapon_change_log = "武器がインデックスに変更されました: %d (%s)",
        initial_weapon_log = "初期武器インデックスが検出されました: %d (%s)",
        unknown_weapon = "不明な武器",
        load_success_log = "%s から設定を読み込みました。",
        load_failure_log = "有効な設定ファイルが見つからないか、'%s' の読み込みに失敗しました。デフォルト値を使用します。",
        save_log = "設定を %s に保存中",
        save_failure_log = "設定の保存に失敗しました: %s",
        mod_init_log = "Modが初期化されました。",
        error_get_mvi = "MergedVirtualInput オブジェクトの取得に失敗しました。エラー: %s",
        error_get_key = "インデックス %s のキーの取得に失敗しました。エラー: %s",
        warn_set_lag = "キーインデックス %s の LagTime (%s) の設定に失敗しました。エラー: %s",
        error_no_weapon_settings = "現在の武器インデックス %s の設定が見つかりません。",
        error_controller_nil = "systemMergedInputSetting フックポストで cPlayerCommandController が nil です。",
        warn_no_player = "MainPlayer オブジェクトを取得できませんでした。",
        warn_no_player_manager = "PlayerManager シングルトンを取得できませんでした。",
        warn_get_weapon_type_fail = "get_WeaponType の呼び出しに失敗しました: %s",
        warn_no_get_weapon_type = "player オブジェクトに get_WeaponType メソッドが見つかりません。初期武器を特定できません。",
        warn_invalid_initial_weapon = "初期武器インデックスが %s として検出されましたが、これは無効または不明です。",
        error_reset_fail = "リセット中に武器インデックス %s のデフォルト設定の取得に失敗しました。",
        display_modes = { [1]="PlayStation", [2]="Xbox", [3]="Keyboard/Mouse" }, -- Use 1-based index table for combo
        ps_key_names = { [0]="Triangle", [1]="Circle", [2]="R2", [3]="R1", [6]="Square", [7]="Cross" },
        xbox_key_names = { [0]="Y", [1]="B", [2]="RT", [3]="RB", [6]="X", [7]="A" },
        kbm_key_names = { [0]="LMB", [1]="RMB", [2]="R", [3]="Shift", [6]="E", [7]="Space" } -- LMB=Left Mouse, RMB=Right Mouse
    },
    fr = {
        mod_title = "Input Lag Customizer (No KeyLag)",
        enable_mod_label = "Activer le Mod",
        language_label = "Langue:",
        display_mode_label = "Type de touches à afficher:",
        note_line1 = "Note: Le mode d'affichage des touches n'affecte que les noms affichés dans l'interface, et non le fonctionnement réel du mod.",
        note_line2 = "Même si vous avez modifié les touches dans le jeu, le mod fonctionne avec les nouvelles assignations — seule l’interface continue d’afficher les touches par défaut.",
        weapon_settings_label = "Paramètres de chaque arme",
        reset_button_label = "Configuration par défaut",
        weapon_0 = "Grande épée", weapon_1 = "Épée et bouclier", weapon_2 = "Lames doubles", weapon_3 = "Épée longue", weapon_4 = "Marteau",
        weapon_5 = "Corne de chasse", weapon_6 = "Lance", weapon_7 = "Lancecanon", weapon_8 = "Morpho-hache", weapon_9 = "Volto-hache",
        weapon_10 = "Insectoglaive", weapon_11 = "Arc", weapon_12 = "Fusarbalète lourd", weapon_13 = "Fusarbalète léger",
        enabled_log = "Mod activé via IU.",
        disabled_log = "Mod désactivé via IU. Veuillez changer d'arme ou redémarrer le jeu pour vous assurer que les modifications ont bien étées réinitialisées.",
        display_mode_change_log = "Type d'affichage des touches changé: %s",
        language_change_log = "Langue changée: %s",
        settings_applied_log = "Application de modifications pour [%s].",
        settings_reset_log = "Paramètres de [%s] réinitialisés.",
        weapon_change_log = "Changement d'arme détecté. inde de la nouvelle arme: %d (%s)",
        initial_weapon_log = "Index de l'arme initiale: %d (%s)",
        unknown_weapon = "Arme non reconnue",
        load_success_log = "Paramètres chargés depuis %s.",
        load_failure_log = "Aucun fichier de paramètres n'as pu être trouvé ou chargé '%s'. Application de la configuration par défaut.",
        save_log = "Enregistrement des paramètres vers %s",
        save_failure_log = "Echec de l'enregistrement des paramètres: %s",
        mod_init_log = "Mod initialisé.",
        error_get_mvi = "Failed to get MergedVirtualInput object. Error: %s",
        error_get_key = "Failed to get key for index %s. Error: %s",
        warn_set_lag = "Failed to set LagTime (%s) for key index %s. Error: %s",
        error_no_weapon_settings = "No settings found for current weapon index: %s",
        error_controller_nil = "cPlayerCommandController is nil in systemMergedInputSetting hook post.",
        warn_no_player = "Could not get MainPlayer object.",
        warn_no_player_manager = "Could not get PlayerManager singleton.",
        warn_get_weapon_type_fail = "Failed to call get_WeaponType: %s",
        warn_no_get_weapon_type = "Cannot find get_WeaponType method on player object. Echec de determination de l'arme initiale.",
        warn_invalid_initial_weapon = "L'Index de l'arme initiale à été détecté comme %s, ce qui est soit invalide, soit inconnu.",
        error_reset_fail = "Échec de récupération des paramètres par défaut de l'arme d'index %s lors de la réinitialisation.",
        display_modes = { [1]="PlayStation", [2]="Xbox", [3]="Clavier/Souris" }, -- Use 1-based index table for combo
        ps_key_names = { [0]="Triangle", [1]="Cercle", [2]="R2", [3]="R1", [6]="Carré", [7]="Croix" },
        xbox_key_names = { [0]="Y", [1]="B", [2]="RT", [3]="RB", [6]="X", [7]="A" },
        kbm_key_names = { [0]="Souris 1", [1]="Souris 2", [2]="R", [3]="Shift", [6]="E", [7]="Espace" }
    }
}

-- Initialize config with defaults *before* defining get_text
local config = {
    enabled = true,
    display_mode = "PlayStation",
    language = "en",
    wps = nil
}

-- Helper function to get translated text
local function get_text(id, ...)
    local lang_code = config.language or "en"
    local lang_texts = texts[lang_code] or texts["en"]
    local text_template = lang_texts[id]
    if not text_template and lang_code ~= "en" then
        text_template = texts["en"][id]
    end
    if not text_template then return id end

    if select('#', ...) > 0 then
        local success, result = pcall(string.format, text_template, ...)
        return success and result or text_template .. " (fmt err)"
    else
        return text_template
    end
end

-- --- Default Weapon Settings Generator ---
local function default_wps()
    local base_defaults = {
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
    local default_lag = 0.00 -- Default lag remains 0.00
    local final_defaults = {}
    for weapon_idx, _ in pairs(weapon_ids) do
        final_defaults[weapon_idx] = {}
        local base_weapon_config = base_defaults[weapon_idx] or {}
        for key_idx, _ in pairs(valid_key_indices) do
            final_defaults[weapon_idx][key_idx] = base_weapon_config[key_idx] or default_lag
        end
    end
    return final_defaults
end

-- Populate default weapon settings now
config.wps = default_wps()

-- --- Configuration Handling ---

-- *** MODIFICATION: Updated merge_tables for proper nested table merging ***
local function merge_tables(t1, t2)
    -- Add type checks for safety
    if type(t1) ~= "table" or type(t2) ~= "table" then
        -- Optional: Add logging here if you want to know about non-table merges attempt
        -- log.warn("merge_tables: non-table argument received. t1 type: " .. type(t1) .. ", t2 type: " .. type(t2))
        return
    end

    for k, v in pairs(t2) do -- Iterate through the source table (t2, loaded settings)
        -- Check if the key exists in the destination table (t1, current config)
        if t1[k] ~= nil then
            -- If both the existing value in t1 and the new value from t2 are tables, recurse
            if type(t1[k]) == "table" and type(v) == "table" then
                merge_tables(t1[k], v)
            -- Otherwise (if one or both are not tables, or key types differ), overwrite the value in t1
            else
                t1[k] = v -- This correctly overwrites simple values and the final numeric lag values
            end
        -- else
            -- If the key from t2 does not exist in t1, we ignore it here.
            -- We only want to update values that have a corresponding default setting.
            -- To add keys from t2 that are missing in t1, uncomment the next line:
            -- t1[k] = v
        end
    end
end


local function convert_wps_keys_to_integers(t)
    if type(t) ~= "table" then return t end
    local new_table = {}
    for k, v in pairs(t) do
        local num_key = tonumber(k)
        -- Ensure conversion results in an integer index
        if num_key ~= nil and math.floor(num_key) == num_key then
             -- Recursively convert nested tables (values might also be tables with numeric keys)
             new_table[num_key] = convert_wps_keys_to_integers(v)
        else
             -- Keep non-integer-convertible keys as they are (e.g., "enabled", "language")
             -- This part might not be strictly necessary if only called on wps, but harmless.
             new_table[k] = v
        end
    end
    return new_table
end

-- Load saved settings
local saved_config_raw = nil
local config_filename = "No_KeyLag.json"
local success, loaded_data = pcall(function() return json.load_file(config_filename) end)

if success and type(loaded_data) == "table" then
    saved_config_raw = loaded_data
    log.info(get_text("load_success_log", config_filename))
else
    log.warn(get_text("load_failure_log", config_filename))
end

-- Merge loaded settings into the default config structure
if saved_config_raw then
    local saved_config_filtered = {}
    -- Filter and copy basic settings
    if saved_config_raw.enabled ~= nil then saved_config_filtered.enabled = saved_config_raw.enabled end
    if saved_config_raw.display_mode ~= nil then saved_config_filtered.display_mode = saved_config_raw.display_mode end
    if saved_config_raw.language ~= nil then saved_config_filtered.language = saved_config_raw.language end

    -- Process 'wps' separately: check type, convert keys, then assign for merging
    if type(saved_config_raw.wps) == "table" then
        -- Convert JSON string keys ("0", "1") to Lua number keys (0, 1) *before* merging
        saved_config_filtered.wps = convert_wps_keys_to_integers(saved_config_raw.wps)
    end

    -- Now merge the filtered (and potentially key-converted) settings into the main config
    -- The updated merge_tables function will handle the nested structure correctly.
    merge_tables(config, saved_config_filtered)
end

-- --- Runtime Variables ---
local on_weapon_change = false
local current_weapon_idx = -1
local cPlayerCommandController = nil

-- --- Core Logic: Overwrite Key Lag ---
local function overwrite_keylag()
    if not config.enabled or current_weapon_idx == -1 or not cPlayerCommandController then return end
    if not config.wps[current_weapon_idx] then
        log.error(get_text("error_no_weapon_settings", current_weapon_idx))
        return
    end

    local target_settings = config.wps[current_weapon_idx]
    local merged_virtual_input = nil

    local success_get_mvi, result_mvi = pcall(function() return cPlayerCommandController:get_MergedVirtualInput() end)
    if not success_get_mvi or not result_mvi then
        log.error(get_text("error_get_mvi", tostring(result_mvi)))
        return
    end
    merged_virtual_input = result_mvi

    for key_idx, lag_value in pairs(target_settings) do
        -- Validate that lag_value is actually a number before trying to set it
        if valid_key_indices[key_idx] and type(lag_value) == "number" then
            local key_obj = nil
            local success_get_key, result_key = pcall(function() return merged_virtual_input:getKey(key_idx) end)
            if success_get_key and result_key then
                key_obj = result_key
            else
                log.error(get_text("error_get_key", tostring(key_idx), tostring(result_key)))
                goto continue
            end

            if key_obj then
                local success_set_lag, error_set_lag = pcall(function() key_obj:set_LagTime(lag_value) end)
                if not success_set_lag then
                    log.warn(get_text("warn_set_lag", tostring(lag_value), tostring(key_idx), tostring(error_set_lag)))
                end
            end
        -- Optional: Log warning if lag_value is not a number for a valid key
        -- elseif valid_key_indices[key_idx] and type(lag_value) ~= "number" then
        --    log.warn("overwrite_keylag: Invalid non-numeric lag value found for weapon " .. current_weapon_idx .. ", key " .. key_idx .. ": " .. tostring(lag_value))
        end
        ::continue::
    end
end

-- --- Game Hooks ---
sdk.hook(sdk.find_type_definition("app.HunterCharacter.cHunterExtendPlayer"):get_method("systemInputSetting"), function(args)
    local cHunterExtendPlayer = sdk.to_managed_object(args[2])
    if cHunterExtendPlayer and cHunterExtendPlayer:get_IsMaster() then
        on_weapon_change = true
    end
end, function(retval)
    on_weapon_change = false
end)

sdk.hook(sdk.find_type_definition("app.cPlayerCatalogHolder"):get_method("getWeaponActionParam(app.WeaponDef.TYPE)"), function(args)
    if on_weapon_change then
        local new_weapon_idx = sdk.to_int64(args[3])
        if new_weapon_idx ~= current_weapon_idx and weapon_ids[new_weapon_idx] then
            current_weapon_idx = new_weapon_idx
            -- log.debug(get_text("weapon_change_log", current_weapon_idx, get_text(weapon_ids[current_weapon_idx])))
            if config.enabled and cPlayerCommandController then
                overwrite_keylag()
            end
        end
    end
end, nil)

sdk.hook(sdk.find_type_definition("app.cPlayerCommandController"):get_method("systemMergedInputSetting"), function(args)
    cPlayerCommandController = sdk.to_managed_object(args[2])
end, function(retval)
    if cPlayerCommandController then
        if current_weapon_idx == -1 then
            local player_manager = sdk.get_managed_singleton("app.PlayerManager")
            if player_manager then
                 local player = player_manager:get_MainPlayer()
                 if player then
                     local get_weapon_type_method = sdk.find_method(player, "get_WeaponType")
                     if get_weapon_type_method then
                         local success_get_wt, wt_result = pcall(function() return player:get_WeaponType() end)
                         if success_get_wt and weapon_ids[wt_result] then
                             current_weapon_idx = wt_result
                             -- log.debug(get_text("initial_weapon_log", current_weapon_idx, get_text(weapon_ids[current_weapon_idx])))
                         else
                             if not success_get_wt then log.error(get_text("warn_get_weapon_type_fail", tostring(wt_result)))
                             else log.warn(get_text("warn_invalid_initial_weapon", tostring(wt_result))) end
                             current_weapon_idx = -1
                         end
                     else
                        log.warn(get_text("warn_no_get_weapon_type"))
                        current_weapon_idx = -1
                     end
                 else log.warn(get_text("warn_no_player")) end
            else log.warn(get_text("warn_no_player_manager")) end
        end
        -- Apply settings after controller is confirmed and initial weapon potentially detected
        overwrite_keylag()
    else
        log.error(get_text("error_controller_nil"))
    end
end)

-- --- User Interface (ReFramework) ---
local function draw_mod_ui()
    local ui_changed_this_frame = false

    if imgui.tree_node(get_text("mod_title") .. "##MainTree") then
        local enabled_changed, enabled_new_value = imgui.checkbox(get_text("enable_mod_label") .. "##EnableCheck", config.enabled)
        if enabled_changed then
            config.enabled = enabled_new_value
            ui_changed_this_frame = true
            if config.enabled then
                log.info(get_text("enabled_log"))
                if cPlayerCommandController and current_weapon_idx ~= -1 then overwrite_keylag() end
            else
                log.info(get_text("disabled_log"))
            end
        end

        imgui.text(get_text("language_label"))
        imgui.push_item_width(150)
        imgui.same_line()
        local current_language_index = 1
        for i, lang_code_iter in ipairs(language_codes) do
             if lang_code_iter == config.language then
                 current_language_index = i
                 break
             end
        end
        local language_combo_changed, new_language_index = imgui.combo("##LanguageComboSelector", current_language_index, language_names)
        if language_combo_changed then
            local new_lang_code = language_codes[new_language_index]
            if config.language ~= new_lang_code then
                config.language = new_lang_code
                ui_changed_this_frame = true
                log.info(get_text("language_change_log", config.language))
            end
        end
        imgui.pop_item_width()

        imgui.text(get_text("display_mode_label"))
        imgui.push_item_width(150)
        imgui.same_line()
        local current_display_mode_index = 1
        for i, mode_name in ipairs(get_text("display_modes")) do
            if mode_name == config.display_mode then
                current_display_mode_index = i
                break
            end
        end
        local display_combo_changed, new_display_mode_index = imgui.combo("##DisplayModeComboSelector", current_display_mode_index, get_text("display_modes"))
        if display_combo_changed then
            local new_mode_name = get_text("display_modes")[new_display_mode_index]
            if config.display_mode ~= new_mode_name then
                config.display_mode = new_mode_name
                ui_changed_this_frame = true
                log.info(get_text("display_mode_change_log", config.display_mode))
            end
        end
        imgui.pop_item_width()

        imgui.text(get_text("note_line1"))
        imgui.text(get_text("note_line2"))
        imgui.separator()

        if imgui.tree_node(get_text("weapon_settings_label") .. "##WeaponsTree") then
            local sorted_weapon_indices = {}
            for w_idx, _ in pairs(config.wps) do
                 if weapon_ids[w_idx] then table.insert(sorted_weapon_indices, w_idx) end
            end
            table.sort(sorted_weapon_indices)

            for _, w_idx in ipairs(sorted_weapon_indices) do
                -- Ensure weapon config exists before trying to access it
                if config.wps[w_idx] then
                    local weapon_config = config.wps[w_idx]
                    local weapon_display_name = get_text(weapon_ids[w_idx])

                    if imgui.tree_node(weapon_display_name .. "##WNode" .. w_idx) then
                        local weapon_settings_changed = false
                        local sorted_keys = {}
                        for k_idx, _ in pairs(weapon_config) do
                            if valid_key_indices[k_idx] then table.insert(sorted_keys, k_idx) end
                        end
                        table.sort(sorted_keys)

                        for _, k_idx in ipairs(sorted_keys) do
                            -- Ensure key exists before accessing
                            if weapon_config[k_idx] ~= nil then
                                local key_lag_value = weapon_config[k_idx]
                                local name_map = get_text("ps_key_names")
                                if config.display_mode == "PlayStation" then name_map = get_text("ps_key_names")
                                elseif config.display_mode == "Xbox" then name_map = get_text("xbox_key_names")
                                elseif config.display_mode == "Keyboard/Mouse" or "Clavier/Souris" then name_map = get_text("kbm_key_names") end
                                local key_display_name = name_map[k_idx] or ("Index " .. tostring(k_idx))

                                local value_changed, new_lag_value = imgui.drag_float(key_display_name .. "##Key" .. k_idx .. "W" .. w_idx, key_lag_value, 0.001, 0, 0.5, "%.4f")
                                if value_changed then
                                    new_lag_value = math.max(0, math.min(0.5, new_lag_value))
                                    if config.wps[w_idx][k_idx] ~= new_lag_value then
                                        config.wps[w_idx][k_idx] = new_lag_value
                                        weapon_settings_changed = true
                                        ui_changed_this_frame = true
                                    end
                                end
                            end -- end check key exists
                        end

                        if imgui.button(get_text("reset_button_label") .. "##ResetBtn" .. w_idx) then
                            -- log.debug(get_text("settings_reset_log", weapon_display_name))
                            local default_weapon_settings = default_wps()[w_idx]
                            if default_weapon_settings then
                                -- Deep copy default settings
                                config.wps[w_idx] = {}
                                for k, v in pairs(default_weapon_settings) do config.wps[w_idx][k] = v end
                                weapon_settings_changed = true
                                ui_changed_this_frame = true
                            else
                                log.error(get_text("error_reset_fail", w_idx))
                            end
                        end

                        if weapon_settings_changed and config.enabled and w_idx == current_weapon_idx then
                            -- log.debug(get_text("settings_applied_log", weapon_display_name))
                            overwrite_keylag()
                        end
                        imgui.tree_pop()
                    end -- end weapon node
                end -- end check weapon config exists
            end
            imgui.tree_pop()
        end
        imgui.tree_pop()
    end
end

re.on_draw_ui(draw_mod_ui)

-- --- Configuration Saving ---
re.on_config_save(
    function()
        local config_to_save = {
            enabled = config.enabled,
            display_mode = config.display_mode,
            language = config.language,
            wps = config.wps -- Save the current state of wps
        }
        log.info(get_text("save_log", config_filename))
        local success_save, err_save = pcall(function() json.dump_file(config_filename, config_to_save) end)
        if not success_save then
            log.error(get_text("save_failure_log", tostring(err_save)))
        end
    end
)

-- Log initialization message
log.info(get_text("mod_init_log"))