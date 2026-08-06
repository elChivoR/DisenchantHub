local ADDON_NAME = "DisenchantHub"

DisenchantHub = {}
DisenchantHub.name = ADDON_NAME
DisenchantHub.version = "1.0.0"

local DH = DisenchantHub

local frame = CreateFrame("Frame", "DisenchantHubFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == ADDON_NAME then
            DH.Config:Init()
            DH.L:Init()
            DH.Lists:Init()
            DH.Log:Init()
            DH.Filter:Init()
            DH.Disenchant:Init()
            DH.UI:Init()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        DH:OnLogin()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

function DH:OnLogin()
    self:Print(string.format(self.L:Get("loaded"), self.version))
    self.Config:RegisterHotkeys()
end

function DH:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffaa00ff[DH]|r " .. msg)
end

SLASH_DISENCHANTHUB1 = "/dh"
SLASH_DISENCHANTHUB2 = "/disenchanthub"
SlashCmdList["DISENCHANTHUB"] = function(input)
    local cmd = strtrim(strlower(input or ""))

    if cmd == "" or cmd == "toggle" then
        DH.UI:Toggle()
    elseif cmd == "config" or cmd == "options" then
        DH.UI:ShowConfig()
    elseif cmd == "log" or cmd == "logs" then
        DH.UI:ShowLog()
    elseif cmd == "reset" then
        DH.Config:Reset()
        DH:Print(DH.L:Get("config_reset"))
    elseif cmd == "help" then
        DH:Print(DH.L:Get("cmd_help_title"))
        DH:Print(DH.L:Get("cmd_help_toggle"))
        DH:Print(DH.L:Get("cmd_help_config"))
        DH:Print(DH.L:Get("cmd_help_log"))
        DH:Print(DH.L:Get("cmd_help_reset"))
    else
        DH:Print(DH.L:Get("cmd_unknown"))
    end
end
