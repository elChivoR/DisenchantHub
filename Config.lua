local DH = DisenchantHub
DH.Config = {}

local DEFAULTS = {
    minRarity = 2, -- 0=Poor,1=Common,2=Uncommon,3=Rare,4=Epic
    maxRarity = 4,
    minIlvl = 0,
    maxIlvl = 999,
    autoLoot = true,
    confirmDisenchant = true,
    hotkey = "F5",
    hotkeyEnabled = true,
    logMaxEntries = 200,
    soundEnabled = true,
}

function DH.Config:Init()
    if not DisenchantHubDB then
        DisenchantHubDB = {}
    end

    if not DisenchantHubDB.config then
        DisenchantHubDB.config = CopyTable(DEFAULTS)
    end

    for k, v in pairs(DEFAULTS) do
        if DisenchantHubDB.config[k] == nil then
            DisenchantHubDB.config[k] = v
        end
    end

    self.db = DisenchantHubDB.config
end

function DH.Config:Get(key)
    return self.db[key]
end

function DH.Config:Set(key, value)
    self.db[key] = value
    if key == "hotkey" or key == "hotkeyEnabled" then
        self:RegisterHotkeys()
    end
end

function DH.Config:Reset()
    DisenchantHubDB.config = CopyTable(DEFAULTS)
    self.db = DisenchantHubDB.config
    self:RegisterHotkeys()
end

function DH.Config:RegisterHotkeys()
    if self.binding then
        SetOverrideBindingClick(DisenchantHubFrame, false, self.binding, nil)
        self.binding = nil
    end

    if self.db.hotkeyEnabled and self.db.hotkey and self.db.hotkey ~= "" then
        if not self.hotkeyButton then
            self.hotkeyButton = CreateFrame("Button", "DHHotkeyButton", UIParent, "SecureActionButtonTemplate")
            self.hotkeyButton:SetScript("OnClick", function()
                DH.UI:Toggle()
            end)
        end
        SetOverrideBindingClick(DisenchantHubFrame, false, self.db.hotkey, "DHHotkeyButton")
        self.binding = self.db.hotkey
    end
end

function CopyTable(src)
    local dest = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = CopyTable(v)
        else
            dest[k] = v
        end
    end
    return dest
end
