local DH = DisenchantHub
DH.Disenchant = {}

local DISENCHANT_SPELL = GetSpellInfo(13262) or "Disenchant"
local isProcessing = false
local queue = {}

local eventFrame = CreateFrame("Frame")

function DH.Disenchant:Init()
    self:CreateSecureButton()

    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("LOOT_CLOSED")
    eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        DH.Disenchant:OnEvent(event, ...)
    end)
end

function DH.Disenchant:CreateSecureButton()
    local btn = CreateFrame("Button", "DHSecureDE", UIParent, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "")
    btn:Hide()
    self.secureBtn = btn
end

function DH.Disenchant:SetupMacro(bag, slot)
    local macro = string.format("/cast %s\n/use %d %d", DISENCHANT_SPELL, bag, slot)
    self.secureBtn:SetAttribute("macrotext", macro)
end

function DH.Disenchant:ClearMacro()
    self.secureBtn:SetAttribute("macrotext", "")
end

function DH.Disenchant:OnEvent(event, ...)
    if event == "LOOT_OPENED" then
        if isProcessing and DH.Config:Get("autoLoot") then
            for i = GetNumLootItems(), 1, -1 do
                LootSlot(i)
            end
        end
    elseif event == "LOOT_CLOSED" then
        if isProcessing then
            self:PrepareNext()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, spell = ...
        if unit == "player" and spell == DISENCHANT_SPELL then
            if self.currentItem then
                DH.Log:Add(self.currentItem.link, self.currentItem.bag, self.currentItem.slot, true)
                self.currentItem = nil
            end
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit, spell = ...
        if unit == "player" and spell == DISENCHANT_SPELL then
            if self.currentItem then
                DH.Log:Add(self.currentItem.link, self.currentItem.bag, self.currentItem.slot, false, "Cast failed")
                self.currentItem = nil
            end
            self:Stop("Cast interrumpido.")
        end
    elseif event == "UI_ERROR_MESSAGE" then
        local msg = ...
        if isProcessing and msg then
            DH:Print("|cffff0000Error:|r " .. msg)
        end
    end
end

function DH.Disenchant:Start(items)
    if isProcessing then
        DH:Print("Ya hay un proceso de desencantamiento en curso.")
        return
    end

    if not items or #items == 0 then
        DH:Print("No hay items para desencantar.")
        return
    end

    queue = {}
    for _, item in ipairs(items) do
        if item.canDE then
            table.insert(queue, item)
        end
    end

    if #queue == 0 then
        DH:Print("Ningun item pasa los filtros actuales.")
        return
    end

    isProcessing = true
    DH:Print("Cola de |cff00ff00" .. #queue .. "|r items. Haz click en |cff00ccff[Desencantar]|r para cada uno.")
    self:PrepareNext()
end

function DH.Disenchant:PrepareNext()
    if not isProcessing then return end

    if #queue == 0 then
        self:Stop("Proceso completado.")
        return
    end

    while #queue > 0 do
        local item = queue[1]
        local currentLink = GetContainerItemLink(item.bag, item.slot)
        if currentLink and currentLink == item.link then
            break
        end
        DH:Print("|cffff9900Saltando|r " .. item.name .. " (ya no esta en la posicion original)")
        table.remove(queue, 1)
    end

    if #queue == 0 then
        self:Stop("Proceso completado.")
        return
    end

    local item = queue[1]
    self.currentItem = item
    self:SetupMacro(item.bag, item.slot)
    DH.UI:UpdateDEButton(item, #queue)
end

function DH.Disenchant:OnSecureClick()
    if not isProcessing or #queue == 0 then return end

    if DH.Config:Get("soundEnabled") then
        PlaySound("igMainMenuOption")
    end

    local item = table.remove(queue, 1)
    DH:Print("Desencantando: " .. item.link .. " (" .. #queue .. " restantes)")
end

function DH.Disenchant:PrepareSingle(bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    if not itemLink then return end

    local canDE, reason = DH.Filter:CanDisenchant(itemLink)
    if not canDE then
        DH:Print("No se puede desencantar: " .. (reason or "unknown"))
        return
    end

    local name = GetItemInfo(itemLink) or "?"
    self.currentItem = { link = itemLink, bag = bag, slot = slot, name = name }
    queue = { self.currentItem }
    isProcessing = true
    self:SetupMacro(bag, slot)
    DH.UI:UpdateDEButton(self.currentItem, 1)
    DH:Print("Listo para desencantar: " .. itemLink .. " - Haz click en |cff00ccff[Desencantar]|r")
end

function DH.Disenchant:Stop(reason)
    isProcessing = false
    queue = {}
    self.currentItem = nil
    self:ClearMacro()
    if reason then
        DH:Print(reason)
    end
    DH.UI:UpdateDEButton(nil, 0)
    DH.UI:RefreshItems()
end

function DH.Disenchant:IsProcessing()
    return isProcessing
end

function DH.Disenchant:GetQueueCount()
    return #queue
end
