local DH = DisenchantHub
DH.Log = {}

function DH.Log:Init()
    if not DisenchantHubDB.log then
        DisenchantHubDB.log = {}
    end
    self.entries = DisenchantHubDB.log
end

function DH.Log:Add(itemLink, bag, slot, success, errorMsg)
    local entry = {
        time = time(),
        item = itemLink,
        bag = bag,
        slot = slot,
        success = success,
        error = errorMsg,
    }

    table.insert(self.entries, 1, entry)

    local maxEntries = DH.Config:Get("logMaxEntries") or 200
    while #self.entries > maxEntries do
        table.remove(self.entries)
    end

    if DH.UI.logFrame and DH.UI.logFrame:IsShown() then
        DH.UI:RefreshLog()
    end
end

function DH.Log:GetEntries(limit)
    limit = limit or #self.entries
    local result = {}
    for i = 1, math.min(limit, #self.entries) do
        result[i] = self.entries[i]
    end
    return result
end

function DH.Log:Clear()
    wipe(self.entries)
    DH:Print("Log limpiado.")
    if DH.UI.logFrame and DH.UI.logFrame:IsShown() then
        DH.UI:RefreshLog()
    end
end

function DH.Log:GetCount()
    return #self.entries
end

function DH.Log:FormatTime(timestamp)
    return date("%H:%M:%S", timestamp)
end

function DH.Log:GetStats()
    local total = #self.entries
    local success = 0
    local failed = 0
    for _, entry in ipairs(self.entries) do
        if entry.success then
            success = success + 1
        else
            failed = failed + 1
        end
    end
    return total, success, failed
end
