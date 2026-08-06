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
    self:Print("|cff00ccffDisenchantHub v" .. self.version .. "|r cargado. Usa |cff00ff00/dh|r para abrir.")
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
        DH:Print("Configuracion reseteada a valores por defecto.")
    elseif cmd == "help" then
        DH:Print("Comandos disponibles:")
        DH:Print("  |cff00ff00/dh|r - Abrir/cerrar la ventana principal")
        DH:Print("  |cff00ff00/dh config|r - Abrir configuracion")
        DH:Print("  |cff00ff00/dh log|r - Ver historial de desencantamientos")
        DH:Print("  |cff00ff00/dh reset|r - Resetear configuracion")
    else
        DH:Print("Comando desconocido. Usa |cff00ff00/dh help|r para ver los comandos.")
    end
end
