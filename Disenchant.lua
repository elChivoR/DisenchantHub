local DH = DisenchantHub
DH.Disenchant = {}

local DISENCHANT_SPELL = GetSpellInfo(13262) or "Disenchant"
local ENCHANTING_NAMES = { ["Enchanting"] = true, ["Encantamiento"] = true }

local eventFrame = CreateFrame("Frame")

function DH.Disenchant:Init()
    eventFrame:RegisterEvent("LOOT_OPENED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("BAG_UPDATE")

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        DH.Disenchant:OnEvent(event, ...)
    end)
end

function DH.Disenchant:GetMacroText(bag, slot)
    return string.format("/cast %s\n/use %d %d", DISENCHANT_SPELL, bag, slot)
end

function DH.Disenchant:OnItemClick(item)
    self.currentItem = { link = item.link, bag = item.bag, slot = item.slot, name = item.name }

    if DH.Config:Get("soundEnabled") then
        PlaySound("igMainMenuOption")
    end

    DH:Print(string.format(DH.L:Get("disenchanting_single"), item.link))
end

function DH.Disenchant:OnEvent(event, ...)
    if event == "LOOT_OPENED" then
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
