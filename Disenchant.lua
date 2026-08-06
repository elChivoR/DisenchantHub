local DH = DisenchantHub
DH.Disenchant = {}

local DISENCHANT_SPELL = GetSpellInfo(13262) or "Disenchant"
local ENCHANTING_NAMES = { ["Enchanting"] = true, ["Encantamiento"] = true }
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
    eventFrame:RegisterEvent("BAG_UPDATE")

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
        if isProcessing then
            if self.lastLogEntry then
                local loot = {}
                for i = 1, GetNumLootItems() do
                    local lootIcon, lootName, lootQty = GetLootSlotInfo(i)
                    local lootLink = GetLootSlotLink(i)
                    if lootName then
                        table.insert(loot, { link = lootLink, name = lootName, qty = lootQty or 1 })
                    end
                end
                self.lastLogEntry.loot = loot
                self.lastLogEntry = nil
                if DH.UI.logFrame and DH.UI.logFrame:IsShown() then
                    DH.UI:RefreshLog()
                end
            end

            if DH.Config:Get("autoLoot") then
                for i = GetNumLootItems(), 1, -1 do
                    LootSlot(i)
                end
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
                self.lastLogEntry = DH.Log:Add(self.currentItem.link, self.currentItem.bag, self.currentItem.slot, true)
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
            self:Stop(DH.L:Get("cast_interrupted"))
        end
    elseif event == "UI_ERROR_MESSAGE" then
        local msg = ...
        if isProcessing and msg then
            DH:Print(DH.L:Get("error_prefix") .. msg)
        end
    elseif event == "BAG_UPDATE" then
        if DH.UI.mainFrame and DH.UI.mainFrame:IsShown() and DH.UI.currentTab == 1 then
            DH.UI:RefreshItems()
        end
    end
end

function DH.Disenchant:GetEnchantingInfo()
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
        if not isHeader and ENCHANTING_NAMES[name] then
            return true, rank, maxRank
        end
    end
    return false, 0, 0
end

function DH.Disenchant:Start(items)
    if isProcessing then
        DH:Print(DH.L:Get("already_processing"))
        return
    end

    if not items or #items == 0 then
        DH:Print(DH.L:Get("no_items"))
        return
    end

    queue = {}
    for _, item in ipairs(items) do
        if item.canDE then
            table.insert(queue, item)
        end
    end

    if #queue == 0 then
        DH:Print(DH.L:Get("no_items_pass"))
        return
    end

    isProcessing = true
    DH:Print(string.format(DH.L:Get("queue_ready"), #queue))
    self:PrepareNext()
end

function DH.Disenchant:PrepareNext()
    if not isProcessing then return end

    if #queue == 0 then
        self:Stop(DH.L:Get("process_complete"))
        return
    end

    while #queue > 0 do
        local item = queue[1]
        local currentLink = GetContainerItemLink(item.bag, item.slot)
        if currentLink and currentLink == item.link then
            break
        end
        DH:Print(string.format(DH.L:Get("skipping"), item.name))
        table.remove(queue, 1)
    end

    if #queue == 0 then
        self:Stop(DH.L:Get("process_complete"))
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
    DH:Print(string.format(DH.L:Get("disenchanting"), item.link, #queue))
end

function DH.Disenchant:PrepareSingle(bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    if not itemLink then return end

    local canDE, reason = DH.Filter:CanDisenchant(itemLink)
    if not canDE then
        DH:Print(DH.L:Get("cannot_de") .. (reason or "unknown"))
        return
    end

    local name = GetItemInfo(itemLink) or "?"
    self.currentItem = { link = itemLink, bag = bag, slot = slot, name = name }
    queue = { self.currentItem }
    isProcessing = true
    self:SetupMacro(bag, slot)
    DH.UI:UpdateDEButton(self.currentItem, 1)
    DH:Print(string.format(DH.L:Get("ready_to_de"), itemLink))
end

function DH.Disenchant:Stop(reason)
    isProcessing = false
    queue = {}
    self.currentItem = nil
    self.lastLogEntry = nil
    self:ClearMacro()
    if reason then
        DH:Print(reason)
    end
    DH.UI:UpdateDEButton(nil, 0)
end

function DH.Disenchant:IsProcessing()
    return isProcessing
end

function DH.Disenchant:GetQueueCount()
    return #queue
end
