local DH = DisenchantHub
DH.Lists = {}

function DH.Lists:Init()
    if not DisenchantHubDB.whitelist then
        DisenchantHubDB.whitelist = {}
    end
    if not DisenchantHubDB.blacklist then
        DisenchantHubDB.blacklist = {}
    end
    self.whitelist = DisenchantHubDB.whitelist
    self.blacklist = DisenchantHubDB.blacklist
end

function DH.Lists:AddToWhitelist(itemId, itemName)
    if not itemId then return end
    self.whitelist[itemId] = itemName or true
    self.blacklist[itemId] = nil
    DH:Print("Agregado a whitelist: " .. (itemName or itemId))
end

function DH.Lists:RemoveFromWhitelist(itemId)
    if not itemId then return end
    local name = self.whitelist[itemId]
    self.whitelist[itemId] = nil
    DH:Print("Removido de whitelist: " .. (name or itemId))
end

function DH.Lists:IsWhitelisted(itemId)
    return self.whitelist[itemId] ~= nil
end

function DH.Lists:AddToBlacklist(itemId, itemName)
    if not itemId then return end
    self.blacklist[itemId] = itemName or true
    self.whitelist[itemId] = nil
    DH:Print("Agregado a blacklist: " .. (itemName or itemId))
end

function DH.Lists:RemoveFromBlacklist(itemId)
    if not itemId then return end
    local name = self.blacklist[itemId]
    self.blacklist[itemId] = nil
    DH:Print("Removido de blacklist: " .. (name or itemId))
end

function DH.Lists:IsBlacklisted(itemId)
    return self.blacklist[itemId] ~= nil
end

function DH.Lists:HasWhitelistEntries()
    return next(self.whitelist) ~= nil
end

function DH.Lists:GetWhitelist()
    local list = {}
    for id, name in pairs(self.whitelist) do
        table.insert(list, { id = id, name = name })
    end
    table.sort(list, function(a, b)
        local na = type(a.name) == "string" and a.name or tostring(a.id)
        local nb = type(b.name) == "string" and b.name or tostring(b.id)
        return na < nb
    end)
    return list
end

function DH.Lists:GetBlacklist()
    local list = {}
    for id, name in pairs(self.blacklist) do
        table.insert(list, { id = id, name = name })
    end
    table.sort(list, function(a, b)
        local na = type(a.name) == "string" and a.name or tostring(a.id)
        local nb = type(b.name) == "string" and b.name or tostring(b.id)
        return na < nb
    end)
    return list
end

function DH.Lists:ClearWhitelist()
    wipe(self.whitelist)
    DH:Print("Whitelist limpiada.")
end

function DH.Lists:ClearBlacklist()
    wipe(self.blacklist)
    DH:Print("Blacklist limpiada.")
end
