local DH = DisenchantHub
DH.Filter = {}

local RARITY_NAMES = {
    [0] = "|cff9d9d9dPoor|r",
    [1] = "|cffffffffCommon|r",
    [2] = "|cff1eff00Uncommon|r",
    [3] = "|cff0070ddRare|r",
    [4] = "|cffa335eeEpic|r",
    [5] = "|cffff8000Legendary|r",
}

local DISENCHANTABLE_TYPES = {
    ["Armor"] = true,
    ["Weapon"] = true,
}

function DH.Filter:Init()
end

function DH.Filter:GetRarityName(rarity)
    return RARITY_NAMES[rarity] or "Unknown"
end

function DH.Filter:CanDisenchant(itemLink)
    if not itemLink then return false, "No item link" end

    local name, _, rarity, ilvl, _, itemType = GetItemInfo(itemLink)
    if not name then return false, "Item info not available" end

    if not DISENCHANTABLE_TYPES[itemType] then
        return false, "Not armor or weapon"
    end

    local cfg = DH.Config

    if rarity < cfg:Get("minRarity") then
        return false, "Rarity too low (" .. (RARITY_NAMES[rarity] or rarity) .. ")"
    end

    if rarity > cfg:Get("maxRarity") then
        return false, "Rarity too high (" .. (RARITY_NAMES[rarity] or rarity) .. ")"
    end

    if ilvl < cfg:Get("minIlvl") then
        return false, "ilvl too low (" .. ilvl .. ")"
    end

    if ilvl > cfg:Get("maxIlvl") then
        return false, "ilvl too high (" .. ilvl .. ")"
    end

    local itemId = DH.Filter:GetItemId(itemLink)
    if itemId then
        if DH.Lists:IsBlacklisted(itemId) then
            return false, "Blacklisted"
        end
        local whitelistOnly = DH.Lists:HasWhitelistEntries()
        if whitelistOnly and not DH.Lists:IsWhitelisted(itemId) then
            return false, "Not in whitelist"
        end
    end

    return true
end

function DH.Filter:GetItemId(itemLink)
    if not itemLink then return nil end
    local id = itemLink:match("item:(%d+)")
    return id and tonumber(id)
end

function DH.Filter:GetDisenchantableItems()
    local items = {}
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local canDE, reason = self:CanDisenchant(itemLink)
                if canDE then
                    local name, _, rarity, ilvl, _, itemType = GetItemInfo(itemLink)
                    local _, count = GetContainerItemInfo(bag, slot)
                    table.insert(items, {
                        bag = bag,
                        slot = slot,
                        link = itemLink,
                        name = name or "?",
                        rarity = rarity or 0,
                        ilvl = ilvl or 0,
                        itemType = itemType or "?",
                        count = count or 1,
                        canDE = true,
                        itemId = self:GetItemId(itemLink),
                    })
                end
            end
        end
    end
    table.sort(items, function(a, b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.ilvl > b.ilvl
    end)
    return items
end
