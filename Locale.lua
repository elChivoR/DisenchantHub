local DH = DisenchantHub
DH.L = {}

local locales = {}

-- ============================================================
-- English (default)
-- ============================================================
locales["enUS"] = {
    -- Core
    loaded = "|cff00ccffDisenchantHub v%s|r loaded. Use |cff00ff00/dh|r to open.",
    cmd_unknown = "Unknown command. Use |cff00ff00/dh help|r to see commands.",
    cmd_help_title = "Available commands:",
    cmd_help_toggle = "  |cff00ff00/dh|r - Open/close main window",
    cmd_help_config = "  |cff00ff00/dh config|r - Open configuration",
    cmd_help_log = "  |cff00ff00/dh log|r - View disenchant history",
    cmd_help_reset = "  |cff00ff00/dh reset|r - Reset configuration",
    config_reset = "Configuration reset to defaults.",

    -- Filter
    not_armor_weapon = "Not armor or weapon",
    rarity_too_low = "Rarity too low",
    rarity_too_high = "Rarity too high",
    ilvl_too_low = "ilvl too low",
    ilvl_too_high = "ilvl too high",
    blacklisted = "Blacklisted",
    not_in_whitelist = "Not in whitelist",

    -- Lists
    added_whitelist = "Added to whitelist: ",
    removed_whitelist = "Removed from whitelist: ",
    added_blacklist = "Added to blacklist: ",
    removed_blacklist = "Removed from blacklist: ",
    whitelist_cleared = "Whitelist cleared.",
    blacklist_cleared = "Blacklist cleared.",

    -- Disenchant
    already_processing = "A disenchant process is already running.",
    no_items = "No items to disenchant.",
    no_items_pass = "No items pass the current filters.",
    queue_ready = "Queue of |cff00ff00%d|r items. Click |cff00ccff[Disenchant]|r for each one.",
    skipping = "|cffff9900Skipping|r %s (no longer in original position)",
    process_complete = "Process completed.",
    cast_interrupted = "Cast interrupted.",
    disenchanting = "Disenchanting: %s (%d remaining)",
    cannot_de = "Cannot disenchant: ",
    ready_to_de = "Ready to disenchant: %s - Click |cff00ccff[Disenchant]|r",
    stopped_by_user = "Stopped by user.",
    error_prefix = "|cffff0000Error:|r ",

    -- Log
    log_cleared = "Log cleared.",

    -- UI - Tabs
    tab_items = "Items",
    tab_lists = "Lists",
    tab_config = "Config",
    tab_log = "Log",

    -- UI - Item list headers
    header_item = "Item",
    header_rarity = "Rarity",
    header_ilvl = "ilvl",
    header_type = "Type",

    -- UI - Bottom bar
    btn_refresh = "Refresh",
    btn_de_selection = "DE Selection",
    btn_stop = "Stop",
    btn_no_item = "|cff666666No item|r",
    no_selected = "No items selected. Use checkboxes to choose.",
    selected_count = "%d/%d selected",

    -- UI - DE button
    de_label = "|cff00ff00DE: %s (%d)|r",

    -- UI - Context menu
    select_for_de = "Select for DE",
    add_whitelist = "Add to Whitelist",
    add_blacklist = "Add to Blacklist",

    -- UI - Config
    cfg_filters = "|cff00ccffFilters|r",
    cfg_min_rarity = "Min rarity:",
    cfg_max_rarity = "Max rarity:",
    cfg_min_ilvl = "Min ilvl:",
    cfg_max_ilvl = "Max ilvl:",
    cfg_options = "|cff00ccffOptions|r",
    cfg_auto_loot = "Auto-loot on disenchant",
    cfg_confirm_bulk = "Confirm before bulk DE",
    cfg_sound = "Sound on disenchant",
    cfg_hotkey_section = "|cff00ccffHotkey|r",
    cfg_hotkey_enabled = "Hotkey enabled",
    cfg_hotkey_current = "Current key:",
    cfg_hotkey_change = "Change",
    cfg_hotkey_capture = "Press a key to assign as hotkey...",
    cfg_hotkey_cancelled = "Hotkey capture cancelled.",
    cfg_hotkey_assigned = "Hotkey assigned: |cff00ff00%s|r",
    cfg_reset_btn = "Reset Config",
    cfg_reset_done = "Configuration reset.",
    cfg_language = "|cff00ccffLanguage|r",
    cfg_lang_label = "Language:",
    cfg_lang_reload = "Reload UI to apply language change.",

    -- UI - Log
    log_stats = "Total: |cffffffff%d|r  |cff00ff00OK: %d|r  |cffff4444Fail: %d|r",
    btn_clear = "Clear",

    -- UI - Lists
    whitelist_title = "|cff00ff00Whitelist|r",
    blacklist_title = "|cffff4444Blacklist|r",
    btn_clean = "Clear",
    lists_tip = "|cff888888Tip: Right-click an item in the Items tab to add it to a list|r",

    -- UI - Enchanting
    enchanting_level = "|cffFFD100Enchanting:|r %d/%d",
    no_enchanting = "|cffff4444No Enchanting|r",

    -- Popups
    popup_no_enchanting = "You don't have the Enchanting profession learned.\n\nDisenchantHub requires Enchanting to work.",
    popup_confirm_de = "You are about to disenchant %s items. Continue?",
    popup_ok = "Got it",
    popup_yes = "Yes",
    popup_no = "No",

    -- Rarity labels
    rarity_0 = "Poor",
    rarity_1 = "Common",
    rarity_2 = "Uncommon",
    rarity_3 = "Rare",
    rarity_4 = "Epic",
    rarity_5 = "Legendary",

    -- Language names
    lang_enUS = "English",
    lang_esES = "Espanol (ES)",
    lang_esMX = "Espanol (LATAM)",
}

-- ============================================================
-- Espanol Espana
-- ============================================================
locales["esES"] = {
    loaded = "|cff00ccffDisenchantHub v%s|r cargado. Usa |cff00ff00/dh|r para abrir.",
    cmd_unknown = "Comando desconocido. Usa |cff00ff00/dh help|r para ver los comandos.",
    cmd_help_title = "Comandos disponibles:",
    cmd_help_toggle = "  |cff00ff00/dh|r - Abrir/cerrar la ventana principal",
    cmd_help_config = "  |cff00ff00/dh config|r - Abrir configuracion",
    cmd_help_log = "  |cff00ff00/dh log|r - Ver historial de desencantamientos",
    cmd_help_reset = "  |cff00ff00/dh reset|r - Resetear configuracion",
    config_reset = "Configuracion reseteada a valores por defecto.",

    not_armor_weapon = "No es armadura ni arma",
    rarity_too_low = "Rareza muy baja",
    rarity_too_high = "Rareza muy alta",
    ilvl_too_low = "ilvl muy bajo",
    ilvl_too_high = "ilvl muy alto",
    blacklisted = "En lista negra",
    not_in_whitelist = "No esta en lista blanca",

    added_whitelist = "Agregado a lista blanca: ",
    removed_whitelist = "Quitado de lista blanca: ",
    added_blacklist = "Agregado a lista negra: ",
    removed_blacklist = "Quitado de lista negra: ",
    whitelist_cleared = "Lista blanca limpiada.",
    blacklist_cleared = "Lista negra limpiada.",

    already_processing = "Ya hay un proceso de desencantamiento en curso.",
    no_items = "No hay objetos para desencantar.",
    no_items_pass = "Ningun objeto pasa los filtros actuales.",
    queue_ready = "Cola de |cff00ff00%d|r objetos. Haz clic en |cff00ccff[Desencantar]|r para cada uno.",
    skipping = "|cffff9900Saltando|r %s (ya no esta en la posicion original)",
    process_complete = "Proceso completado.",
    cast_interrupted = "Lanzamiento interrumpido.",
    disenchanting = "Desencantando: %s (%d restantes)",
    cannot_de = "No se puede desencantar: ",
    ready_to_de = "Listo para desencantar: %s - Haz clic en |cff00ccff[Desencantar]|r",
    stopped_by_user = "Detenido por el usuario.",
    error_prefix = "|cffff0000Error:|r ",

    log_cleared = "Registro limpiado.",

    tab_items = "Objetos",
    tab_lists = "Listas",
    tab_config = "Config",
    tab_log = "Registro",

    header_item = "Objeto",
    header_rarity = "Rareza",
    header_ilvl = "ilvl",
    header_type = "Tipo",

    btn_refresh = "Actualizar",
    btn_de_selection = "DE Seleccion",
    btn_stop = "Parar",
    btn_no_item = "|cff666666Sin objeto|r",
    no_selected = "No hay objetos seleccionados. Usa los checkboxes para elegir.",
    selected_count = "%d/%d seleccionados",

    de_label = "|cff00ff00DE: %s (%d)|r",

    select_for_de = "Seleccionar para DE",
    add_whitelist = "Agregar a Lista Blanca",
    add_blacklist = "Agregar a Lista Negra",

    cfg_filters = "|cff00ccffFiltros|r",
    cfg_min_rarity = "Rareza minima:",
    cfg_max_rarity = "Rareza maxima:",
    cfg_min_ilvl = "ilvl minimo:",
    cfg_max_ilvl = "ilvl maximo:",
    cfg_options = "|cff00ccffOpciones|r",
    cfg_auto_loot = "Auto-loot al desencantar",
    cfg_confirm_bulk = "Confirmar antes de DE masivo",
    cfg_sound = "Sonido al desencantar",
    cfg_hotkey_section = "|cff00ccffTecla rapida|r",
    cfg_hotkey_enabled = "Tecla rapida habilitada",
    cfg_hotkey_current = "Tecla actual:",
    cfg_hotkey_change = "Cambiar",
    cfg_hotkey_capture = "Pulsa una tecla para asignar como atajo...",
    cfg_hotkey_cancelled = "Captura de tecla cancelada.",
    cfg_hotkey_assigned = "Tecla asignada: |cff00ff00%s|r",
    cfg_reset_btn = "Resetear Config",
    cfg_reset_done = "Configuracion reseteada.",
    cfg_language = "|cff00ccffIdioma|r",
    cfg_lang_label = "Idioma:",
    cfg_lang_reload = "Recarga la UI para aplicar el cambio de idioma.",

    log_stats = "Total: |cffffffff%d|r  |cff00ff00OK: %d|r  |cffff4444Fallo: %d|r",
    btn_clear = "Limpiar",

    whitelist_title = "|cff00ff00Lista Blanca|r",
    blacklist_title = "|cffff4444Lista Negra|r",
    btn_clean = "Limpiar",
    lists_tip = "|cff888888Tip: Clic derecho en un objeto de la pestana Objetos para agregarlo a una lista|r",

    enchanting_level = "|cffFFD100Encantamiento:|r %d/%d",
    no_enchanting = "|cffff4444Sin Encantamiento|r",

    popup_no_enchanting = "No tienes la profesion de Encantamiento aprendida.\n\nDisenchantHub necesita Encantamiento para funcionar.",
    popup_confirm_de = "Vas a desencantar %s objetos. Continuar?",
    popup_ok = "Entendido",
    popup_yes = "Si",
    popup_no = "No",

    rarity_0 = "Pobre",
    rarity_1 = "Comun",
    rarity_2 = "Poco comun",
    rarity_3 = "Raro",
    rarity_4 = "Epico",
    rarity_5 = "Legendario",

    lang_enUS = "English",
    lang_esES = "Espanol (ES)",
    lang_esMX = "Espanol (LATAM)",
}

-- ============================================================
-- Espanol Latinoamerica
-- ============================================================
locales["esMX"] = {}
for k, v in pairs(locales["esES"]) do
    locales["esMX"][k] = v
end

-- Overrides LATAM
locales["esMX"].queue_ready = "Cola de |cff00ff00%d|r items. Hacele click a |cff00ccff[Desencantar]|r para cada uno."
locales["esMX"].no_selected = "No hay items seleccionados. Usa los checkboxes para elegir."
locales["esMX"].no_items = "No hay items para desencantar."
locales["esMX"].no_items_pass = "Ningun item pasa los filtros actuales."
locales["esMX"].ready_to_de = "Listo para desencantar: %s - Hacele click a |cff00ccff[Desencantar]|r"
locales["esMX"].popup_no_enchanting = "No tenes la profesion Enchanting aprendida.\n\nDisenchantHub necesita Enchanting para funcionar."
locales["esMX"].cfg_hotkey_capture = "Presiona una tecla para asignar como hotkey..."
locales["esMX"].cfg_hotkey_cancelled = "Captura de hotkey cancelada."
locales["esMX"].cfg_hotkey_assigned = "Hotkey asignado: |cff00ff00%s|r"
locales["esMX"].cfg_lang_reload = "Recarga la UI para aplicar el cambio de idioma."

-- ============================================================
-- Public API
-- ============================================================

local SUPPORTED = { "enUS", "esES", "esMX" }

function DH.L:Init()
    local saved = DH.Config:Get("locale")
    local locale = saved or "enUS"
    self.current = locale
    self.strings = locales[locale] or locales["enUS"]
end

function DH.L:Get(key)
    return self.strings[key] or locales["enUS"][key] or key
end

function DH.L:SetLocale(locale)
    if locales[locale] then
        DH.Config:Set("locale", locale)
        self.current = locale
        self.strings = locales[locale]
    end
end

function DH.L:GetCurrent()
    return self.current
end

function DH.L:GetSupported()
    return SUPPORTED
end

function DH.L:GetRarityLabel(rarity)
    return self:Get("rarity_" .. rarity) or "?"
end
