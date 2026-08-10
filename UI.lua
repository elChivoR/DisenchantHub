local DH = DisenchantHub
DH.UI = {}

local RARITY_COLORS = {
    [0] = { 0.62, 0.62, 0.62 },
    [1] = { 1, 1, 1 },
    [2] = { 0.12, 1, 0 },
    [3] = { 0, 0.44, 0.87 },
    [4] = { 0.64, 0.21, 0.93 },
    [5] = { 1, 0.5, 0 },
}

local FRAME_WIDTH = 570
local FRAME_HEIGHT = 520
local ROW_HEIGHT = 24

-- ============================================================
-- Utility helpers
-- ============================================================

local function CreateBackdrop(frame, r, g, b, a)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(r or 0.05, g or 0.05, b or 0.08, a or 0.92)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
end

local function StyledButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 100, height or 22)
    btn:SetText(text)
    btn:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 12)
    return btn
end

local function StyledCheckbox(parent, label, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    text:SetText(label)
    cb.label = text
    if onClick then cb:SetScript("OnClick", onClick) end
    return cb
end

-- ============================================================
-- Main frame
-- ============================================================

function DH.UI:Init()
    self:CreateMainFrame()
    self:CreateItemList()
    self:CreateFilterPanel()
    self:CreateBottomBar()
    self:CreateLogFrame()
    self:CreateConfigFrame()
    self:CreateListManager()
end

function DH.UI:CreateMainFrame()
    local f = CreateFrame("Frame", "DHMainFrame", UIParent)
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")
    CreateBackdrop(f)
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("|cff8800ffDisenchantHub|r")

    local enchLevelLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    enchLevelLabel:SetPoint("TOPRIGHT", -30, -13)
    self.enchLevelLabel = enchLevelLabel

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)

    -- Tabs
    local tabs = {}
    local L = DH.L
    local tabNames = { L:Get("tab_items"), L:Get("tab_lists"), L:Get("tab_config"), L:Get("tab_log") }
    for i, name in ipairs(tabNames) do
        local tab = StyledButton(f, name, 90, 22)
        tab:SetPoint("TOPLEFT", 10 + (i - 1) * 95, -32)
        tab.index = i
        tab:SetScript("OnClick", function() DH.UI:SelectTab(i) end)
        tabs[i] = tab
    end
    self.tabs = tabs

    self.mainFrame = f

    -- Content container
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", 10, -56)
    content:SetPoint("BOTTOMRIGHT", -10, 40)
    self.contentFrame = content
end

function DH.UI:SelectTab(index)
    for i, tab in ipairs(self.tabs) do
        if i == index then
            tab:SetAlpha(1)
        else
            tab:SetAlpha(0.6)
        end
    end

    if self.itemListFrame then self.itemListFrame:Hide() end
    if self.listManagerFrame then self.listManagerFrame:Hide() end
    if self.configFrame then self.configFrame:Hide() end
    if self.logFrame then self.logFrame:Hide() end

    if index == 1 then
        self.itemListFrame:Show()
        self:RefreshItems()
    elseif index == 2 then
        self.listManagerFrame:Show()
        self:RefreshLists()
    elseif index == 3 then
        self.configFrame:Show()
        self:RefreshConfig()
    elseif index == 4 then
        self.logFrame:Show()
        self:RefreshLog()
    end

    self.currentTab = index
end

-- ============================================================
-- Item list (tab 1)
-- ============================================================

function DH.UI:CreateItemList()
    local f = CreateFrame("Frame", nil, self.contentFrame)
    f:SetAllPoints()
    CreateBackdrop(f, 0.02, 0.02, 0.04, 0.6)
    f:Hide()
    self.itemListFrame = f
    -- Header columns
    local COLUMNS = {
        { key = "name",   label = "header_item",   width = 245 },
        { key = "rarity", label = "header_rarity",  width = 80  },
        { key = "ilvl",   label = "header_ilvl",    width = 40  },
        { key = "req",    label = "header_req",     width = 40  },
        { key = "type",   label = "header_type",    width = 75  },
    }
    self.columns = COLUMNS

    -- Invisible spacer matching the icon in rows
    local hSpacer = CreateFrame("Frame", nil, f)
    hSpacer:SetSize(20, 1)
    hSpacer:SetPoint("TOPLEFT", 6, -10)

    local prevHeader = hSpacer
    for _, col in ipairs(COLUMNS) do
        local h = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetPoint("LEFT", prevHeader, "RIGHT", 4, 0)
        h:SetWidth(col.width)
        h:SetFont("Fonts\\FRIZQT__.TTF", 11)
        h:SetText(DH.L:Get(col.label))
        h:SetTextColor(0.7, 0.7, 0.7)
        h:SetJustifyH("LEFT")
        col.header = h
        prevHeader = h
    end

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "DHItemScroll", f, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -28)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)
    self.itemScroll = scrollFrame

    local MAX_ROWS = 16
    local rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", "DHItemRow"..i, f, "SecureActionButtonTemplate")
        row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        row:SetAttribute("type1", "macro")
        row:SetAttribute("macrotext1", "")

        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetAlpha(0.3)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("LEFT", 4, 0)

        local prevCol = row.icon
        for _, col in ipairs(self.columns) do
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetFont("Fonts\\FRIZQT__.TTF", 11)
            fs:SetPoint("LEFT", prevCol, "RIGHT", 4, 0)
            fs:SetWidth(col.width)
            fs:SetJustifyH("LEFT")
            row[col.key .. "Text"] = fs
            prevCol = fs
        end

        row:SetScript("OnEnter", function(self)
            if self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("PostClick", function(self, button)
            if button == "RightButton" and self.itemData then
                DH.UI:ShowItemContextMenu(self)
            elseif button == "LeftButton" and self.itemData and self.itemData.canDE then
                DH.Disenchant:OnItemClick(self.itemData)
            end
        end)

        rows[i] = row
    end
    self.itemRows = rows
    self.maxRows = MAX_ROWS

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function()
            DH.UI:UpdateItemRows()
        end)
    end)
end

function DH.UI:RefreshItems()
    self.items = DH.Filter:GetDisenchantableItems()
    self:UpdateItemRows()
end

function DH.UI:UpdateItemRows()
    if not self.items then return end

    local offset = FauxScrollFrame_GetOffset(self.itemScroll)
    local total = #self.items

    FauxScrollFrame_Update(self.itemScroll, total, self.maxRows, ROW_HEIGHT)

    for i = 1, self.maxRows do
        local row = self.itemRows[i]
        local dataIndex = offset + i

        if dataIndex <= total then
            local item = self.items[dataIndex]
            local color = RARITY_COLORS[item.rarity] or RARITY_COLORS[1]

            local texture = select(10, GetItemInfo(item.link))
            row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

            local dim = not item.canDE
            local alpha = dim and 0.4 or 1.0

            local displayName = item.name
            if #displayName > 26 then
                displayName = displayName:sub(1, 24) .. "..."
            end
            row.nameText:SetText(displayName)
            row.nameText:SetTextColor(color[1], color[2], color[3], alpha)

            row.rarityText:SetText(DH.L:GetRarityLabel(item.rarity))
            row.rarityText:SetTextColor(color[1], color[2], color[3], alpha)

            row.ilvlText:SetText(item.ilvl)
            row.ilvlText:SetTextColor(1, 1, 1, alpha)

            row.reqText:SetText(item.reqSkill or "")
            if dim then
                row.reqText:SetTextColor(1, 0.3, 0.3)
            else
                row.reqText:SetTextColor(0.3, 1, 0.3)
            end

            row.typeText:SetText(item.itemType)
            row.typeText:SetTextColor(0.7, 0.7, 0.7, alpha)

            row.icon:SetAlpha(alpha)

            row.itemLink = item.link
            row.itemData = item

            if item.canDE then
                row:SetAttribute("macrotext1", DH.Disenchant:GetMacroText(item.bag, item.slot))
            else
                row:SetAttribute("macrotext1", "")
            end

            row:Show()
        else
            row:SetAttribute("macrotext1", "")
            row:Hide()
        end
    end
end

function DH.UI:ShowItemContextMenu(row)
    local item = row.itemData
    if not item or not item.itemId then return end

    if not self.contextMenu then
        self.contextMenu = CreateFrame("Frame", "DHContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    CloseDropDownMenus()

    local menu = {
        { text = item.name, isTitle = true, notCheckable = true },
        { text = DH.L:Get("add_whitelist"), notCheckable = true,
            func = function()
                DH.Lists:AddToWhitelist(item.itemId, item.name)
                DH.UI:RefreshItems()
            end },
        { text = DH.L:Get("add_blacklist"), notCheckable = true,
            func = function()
                DH.Lists:AddToBlacklist(item.itemId, item.name)
                DH.UI:RefreshItems()
            end },
    }

    EasyMenu(menu, self.contextMenu, "cursor", 0, 0, "MENU")
end

-- ============================================================
-- Filter panel (inside item tab)
-- ============================================================

function DH.UI:CreateFilterPanel()
end

-- ============================================================
-- Bottom bar with SecureActionButton
-- ============================================================

function DH.UI:CreateBottomBar()
    local bar = CreateFrame("Frame", nil, self.mainFrame)
    bar:SetPoint("BOTTOMLEFT", 10, 8)
    bar:SetPoint("BOTTOMRIGHT", -10, 8)
    bar:SetHeight(28)
    self.bottomBar = bar

    local refreshBtn = StyledButton(bar, DH.L:Get("btn_refresh"), 70, 24)
    refreshBtn:SetPoint("LEFT", 0, 0)
    refreshBtn:SetScript("OnClick", function() DH.UI:RefreshItems() end)

    -- Custom popup anchored to mainFrame
    self:CreatePopup()
end


-- ============================================================
-- Custom popup (anchored to mainFrame)
-- ============================================================

function DH.UI:CreatePopup()
    local popup = CreateFrame("Frame", "DHPopup", self.mainFrame)
    popup:SetSize(340, 140)
    popup:SetPoint("CENTER", self.mainFrame, "CENTER", 0, 0)
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(self.mainFrame:GetFrameLevel() + 50)
    popup:EnableKeyboard(true)
    popup:Hide()

    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })

    local text = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOP", 0, -18)
    text:SetPoint("LEFT", 16, 0)
    text:SetPoint("RIGHT", -16, 0)
    text:SetJustifyH("CENTER")
    text:SetWordWrap(true)
    popup.text = text

    local btn1 = StyledButton(popup, "", 90, 24)
    btn1:SetPoint("BOTTOM", popup, "BOTTOM", -55, 12)
    popup.btn1 = btn1

    local btn2 = StyledButton(popup, "", 90, 24)
    btn2:SetPoint("BOTTOM", popup, "BOTTOM", 55, 12)
    btn2:Hide()
    popup.btn2 = btn2

    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)

    self.popup = popup
end

function DH.UI:ShowPopup(config)
    local p = self.popup
    p.text:SetText(config.text or "")

    local textHeight = p.text:GetStringHeight() or 30
    p:SetHeight(textHeight + 70)

    p.btn1:SetText(config.button1 or "OK")
    p.btn1:SetScript("OnClick", function()
        p:Hide()
        if config.OnAccept then config.OnAccept() end
    end)

    if config.button2 then
        p.btn2:SetText(config.button2)
        p.btn2:SetScript("OnClick", function()
            p:Hide()
            if config.OnCancel then config.OnCancel() end
        end)
        p.btn2:Show()
        p.btn1:SetPoint("BOTTOM", p, "BOTTOM", -55, 12)
    else
        p.btn2:Hide()
        p.btn1:SetPoint("BOTTOM", p, "BOTTOM", 0, 12)
    end

    p:Show()
end

-- ============================================================
-- Config frame (tab 3)
-- ============================================================

function DH.UI:CreateConfigFrame()
    local f = CreateFrame("Frame", nil, self.contentFrame)
    f:SetAllPoints()
    CreateBackdrop(f, 0.02, 0.02, 0.04, 0.6)
    f:Hide()
    self.configFrame = f

    local y = -10

    -- Section: Filters
    local filterTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterTitle:SetPoint("TOPLEFT", 10, y)
    filterTitle:SetText(DH.L:Get("cfg_filters"))
    y = y - 22

    -- Min Rarity
    local minRarLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minRarLabel:SetPoint("TOPLEFT", 10, y)
    minRarLabel:SetText(DH.L:Get("cfg_min_rarity"))
    local minRarVal = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minRarVal:SetPoint("TOPLEFT", 200, y)
    self.cfgMinRarVal = minRarVal

    local minRarDown = StyledButton(f, "<", 24, 20)
    minRarDown:SetPoint("TOPLEFT", 280, y + 2)
    local minRarUp = StyledButton(f, ">", 24, 20)
    minRarUp:SetPoint("LEFT", minRarDown, "RIGHT", 2, 0)
    minRarDown:SetScript("OnClick", function()
        local cur = DH.Config:Get("minRarity")
        if cur > 0 then DH.Config:Set("minRarity", cur - 1); self:RefreshConfig() end
    end)
    minRarUp:SetScript("OnClick", function()
        local cur = DH.Config:Get("minRarity")
        if cur < 5 then DH.Config:Set("minRarity", cur + 1); self:RefreshConfig() end
    end)
    y = y - 24

    -- Max Rarity
    local maxRarLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxRarLabel:SetPoint("TOPLEFT", 10, y)
    maxRarLabel:SetText(DH.L:Get("cfg_max_rarity"))
    local maxRarVal = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxRarVal:SetPoint("TOPLEFT", 200, y)
    self.cfgMaxRarVal = maxRarVal

    local maxRarDown = StyledButton(f, "<", 24, 20)
    maxRarDown:SetPoint("TOPLEFT", 280, y + 2)
    local maxRarUp = StyledButton(f, ">", 24, 20)
    maxRarUp:SetPoint("LEFT", maxRarDown, "RIGHT", 2, 0)
    maxRarDown:SetScript("OnClick", function()
        local cur = DH.Config:Get("maxRarity")
        if cur > 0 then DH.Config:Set("maxRarity", cur - 1); self:RefreshConfig() end
    end)
    maxRarUp:SetScript("OnClick", function()
        local cur = DH.Config:Get("maxRarity")
        if cur < 5 then DH.Config:Set("maxRarity", cur + 1); self:RefreshConfig() end
    end)
    y = y - 24

    -- Min ilvl
    local minIlvlLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minIlvlLabel:SetPoint("TOPLEFT", 10, y)
    minIlvlLabel:SetText(DH.L:Get("cfg_min_ilvl"))
    local minIlvlBox = CreateFrame("EditBox", "DHMinIlvlBox", f, "InputBoxTemplate")
    minIlvlBox:SetPoint("TOPLEFT", 200, y + 4)
    minIlvlBox:SetSize(60, 20)
    minIlvlBox:SetAutoFocus(false)
    minIlvlBox:SetNumeric(true)
    minIlvlBox:SetScript("OnEnterPressed", function(self)
        DH.Config:Set("minIlvl", tonumber(self:GetText()) or 0)
        self:ClearFocus()
    end)
    minIlvlBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.cfgMinIlvl = minIlvlBox
    y = y - 26

    -- Max ilvl
    local maxIlvlLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxIlvlLabel:SetPoint("TOPLEFT", 10, y)
    maxIlvlLabel:SetText(DH.L:Get("cfg_max_ilvl"))
    local maxIlvlBox = CreateFrame("EditBox", "DHMaxIlvlBox", f, "InputBoxTemplate")
    maxIlvlBox:SetPoint("TOPLEFT", 200, y + 4)
    maxIlvlBox:SetSize(60, 20)
    maxIlvlBox:SetAutoFocus(false)
    maxIlvlBox:SetNumeric(true)
    maxIlvlBox:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 300
        if val > 300 then val = 300 end
        DH.Config:Set("maxIlvl", val)
        self:SetText(tostring(val))
        self:ClearFocus()
    end)
    maxIlvlBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.cfgMaxIlvl = maxIlvlBox
    y = y - 30

    -- Section: Opciones
    local optTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optTitle:SetPoint("TOPLEFT", 10, y)
    optTitle:SetText(DH.L:Get("cfg_options"))
    y = y - 22

    local autoLootCb = StyledCheckbox(f, DH.L:Get("cfg_auto_loot"), function(self)
        DH.Config:Set("autoLoot", self:GetChecked() and true or false)
    end)
    autoLootCb:SetPoint("TOPLEFT", 10, y)
    self.cfgAutoLoot = autoLootCb
    y = y - 24

    local soundCb = StyledCheckbox(f, DH.L:Get("cfg_sound"), function(self)
        DH.Config:Set("soundEnabled", self:GetChecked() and true or false)
    end)
    soundCb:SetPoint("TOPLEFT", 10, y)
    self.cfgSound = soundCb
    y = y - 30

    -- Section: Hotkey
    local hkTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hkTitle:SetPoint("TOPLEFT", 10, y)
    hkTitle:SetText(DH.L:Get("cfg_hotkey_section"))
    y = y - 22

    local hkEnable = StyledCheckbox(f, DH.L:Get("cfg_hotkey_enabled"), function(self)
        DH.Config:Set("hotkeyEnabled", self:GetChecked() and true or false)
    end)
    hkEnable:SetPoint("TOPLEFT", 10, y)
    self.cfgHkEnabled = hkEnable
    y = y - 24

    local hkLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hkLabel:SetPoint("TOPLEFT", 10, y)
    hkLabel:SetText(DH.L:Get("cfg_hotkey_current"))
    local hkVal = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hkVal:SetPoint("TOPLEFT", 100, y)
    self.cfgHkVal = hkVal

    local hkSetBtn = StyledButton(f, DH.L:Get("cfg_hotkey_change"), 70, 20)
    hkSetBtn:SetPoint("TOPLEFT", 200, y + 2)
    hkSetBtn:SetScript("OnClick", function()
        DH:Print(DH.L:Get("cfg_hotkey_capture"))
        self:CaptureHotkey()
    end)
    y = y - 30

    -- Section: Language
    local langTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langTitle:SetPoint("TOPLEFT", 10, y)
    langTitle:SetText(DH.L:Get("cfg_language"))
    y = y - 22

    local langLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langLabel:SetPoint("TOPLEFT", 10, y)
    langLabel:SetText(DH.L:Get("cfg_lang_label"))

    local langVal = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    langVal:SetPoint("TOPLEFT", 100, y)
    self.cfgLangVal = langVal

    local langPrev = StyledButton(f, "<", 24, 20)
    langPrev:SetPoint("TOPLEFT", 220, y + 2)
    local langNext = StyledButton(f, ">", 24, 20)
    langNext:SetPoint("LEFT", langPrev, "RIGHT", 2, 0)

    local supported = DH.L:GetSupported()
    local function cycleLang(dir)
        local cur = DH.L:GetCurrent()
        local idx = 1
        for i, loc in ipairs(supported) do
            if loc == cur then idx = i; break end
        end
        idx = idx + dir
        if idx < 1 then idx = #supported end
        if idx > #supported then idx = 1 end
        DH.L:SetLocale(supported[idx])
        DH.UI:RefreshConfig()
        DH:Print(DH.L:Get("cfg_lang_reload"))
    end

    langPrev:SetScript("OnClick", function() cycleLang(-1) end)
    langNext:SetScript("OnClick", function() cycleLang(1) end)
    y = y - 30

    -- Reset
    local resetBtn = StyledButton(f, DH.L:Get("cfg_reset_btn"), 100, 24)
    resetBtn:SetPoint("TOPLEFT", 10, y)
    resetBtn:SetScript("OnClick", function()
        DH.Config:Reset()
        DH.L:Init()
        DH.UI:RefreshConfig()
        DH:Print(DH.L:Get("cfg_reset_done"))
    end)
end

function DH.UI:RefreshConfig()
    local cfg = DH.Config
    local minR = cfg:Get("minRarity")
    local maxR = cfg:Get("maxRarity")
    local rc1 = RARITY_COLORS[minR] or RARITY_COLORS[1]
    local rc2 = RARITY_COLORS[maxR] or RARITY_COLORS[1]

    self.cfgMinRarVal:SetText(DH.L:GetRarityLabel(minR))
    self.cfgMinRarVal:SetTextColor(rc1[1], rc1[2], rc1[3])
    self.cfgMaxRarVal:SetText(DH.L:GetRarityLabel(maxR))
    self.cfgMaxRarVal:SetTextColor(rc2[1], rc2[2], rc2[3])
    self.cfgMinIlvl:SetText(tostring(cfg:Get("minIlvl")))
    self.cfgMaxIlvl:SetText(tostring(cfg:Get("maxIlvl")))
    self.cfgAutoLoot:SetChecked(cfg:Get("autoLoot"))
    self.cfgSound:SetChecked(cfg:Get("soundEnabled"))
    self.cfgHkEnabled:SetChecked(cfg:Get("hotkeyEnabled"))
    self.cfgHkVal:SetText(cfg:Get("hotkey") or "None")
    if self.cfgLangVal then
        self.cfgLangVal:SetText(DH.L:Get("lang_" .. DH.L:GetCurrent()))
    end
end

function DH.UI:CaptureHotkey()
    if not self.hkCapture then
        self.hkCapture = CreateFrame("Frame", nil, UIParent)
        self.hkCapture:EnableKeyboard(true)
        self.hkCapture:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                DH:Print(DH.L:Get("cfg_hotkey_cancelled"))
            else
                DH.Config:Set("hotkey", key)
                DH:Print(string.format(DH.L:Get("cfg_hotkey_assigned"), key))
                DH.UI:RefreshConfig()
            end
            self:Hide()
        end)
    end
    self.hkCapture:Show()
    self.hkCapture:SetPropagateKeyboardInput(false)
end

-- ============================================================
-- Log frame (tab 4)
-- ============================================================

function DH.UI:CreateLogFrame()
    local f = CreateFrame("Frame", nil, self.contentFrame)
    f:SetAllPoints()
    CreateBackdrop(f, 0.02, 0.02, 0.04, 0.6)
    f:Hide()
    self.logFrame = f

    -- Stats header
    local statsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statsLabel:SetPoint("TOPLEFT", 8, -6)
    self.logStatsLabel = statsLabel

    local clearBtn = StyledButton(f, DH.L:Get("btn_clear"), 70, 20)
    clearBtn:SetPoint("TOPRIGHT", -8, -4)
    clearBtn:SetScript("OnClick", function() DH.Log:Clear() end)

    -- Column headers
    local hTime = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hTime:SetFont("Fonts\\FRIZQT__.TTF", 11)
    hTime:SetPoint("TOPLEFT", 8, -24)
    hTime:SetTextColor(0.8, 0.8, 0.5)
    hTime:SetText(DH.L:Get("log_header_time"))

    local hItem = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hItem:SetFont("Fonts\\FRIZQT__.TTF", 11)
    hItem:SetPoint("TOPLEFT", 72, -24)
    hItem:SetTextColor(0.8, 0.8, 0.5)
    hItem:SetText(DH.L:Get("log_header_item"))

    local hLoot = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hLoot:SetFont("Fonts\\FRIZQT__.TTF", 11)
    hLoot:SetPoint("TOPLEFT", 259, -24)
    hLoot:SetTextColor(0.8, 0.8, 0.5)
    hLoot:SetText(DH.L:Get("log_header_loot"))

    -- Scroll
    local scrollFrame = CreateFrame("ScrollFrame", "DHLogScroll", f, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)
    self.logScroll = scrollFrame

    local MAX_LOG_ROWS = 15
    local logRows = {}
    for i = 1, MAX_LOG_ROWS do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))

        row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.timeText:SetFont("Fonts\\FRIZQT__.TTF", 11)
        row.timeText:SetPoint("LEFT", 4, 0)
        row.timeText:SetWidth(60)
        row.timeText:SetTextColor(0.6, 0.6, 0.6)

        row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.itemText:SetFont("Fonts\\FRIZQT__.TTF", 11)
        row.itemText:SetPoint("LEFT", 68, 0)
        row.itemText:SetWidth(180)
        row.itemText:SetJustifyH("LEFT")

        row.lootText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.lootText:SetFont("Fonts\\FRIZQT__.TTF", 11)
        row.lootText:SetPoint("LEFT", 255, 0)
        row.lootText:SetWidth(220)
        row.lootText:SetJustifyH("LEFT")

        row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.statusText:SetFont("Fonts\\FRIZQT__.TTF", 11)
        row.statusText:SetPoint("RIGHT", -4, 0)

        logRows[i] = row
    end
    self.logRows = logRows
    self.maxLogRows = MAX_LOG_ROWS

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function()
            DH.UI:UpdateLogRows()
        end)
    end)
end

function DH.UI:RefreshLog()
    local total, success, failed = DH.Log:GetStats()
    self.logStatsLabel:SetText(string.format(DH.L:Get("log_stats"), total, success, failed))
    self:UpdateLogRows()
end

function DH.UI:UpdateLogRows()
    local entries = DH.Log:GetEntries()
    local offset = FauxScrollFrame_GetOffset(self.logScroll)
    local total = #entries

    FauxScrollFrame_Update(self.logScroll, total, self.maxLogRows, ROW_HEIGHT)

    for i = 1, self.maxLogRows do
        local row = self.logRows[i]
        local dataIndex = offset + i

        if dataIndex <= total then
            local entry = entries[dataIndex]
            row.timeText:SetText(DH.Log:FormatTime(entry.time))
            row.itemText:SetText(entry.item or "?")

            if entry.loot and #entry.loot > 0 then
                local parts = {}
                for _, l in ipairs(entry.loot) do
                    local display = l.link or l.name or "?"
                    if l.qty and l.qty > 1 then
                        display = display .. " x" .. l.qty
                    end
                    table.insert(parts, display)
                end
                row.lootText:SetText(table.concat(parts, ", "))
            else
                row.lootText:SetText("")
            end

            if entry.success then
                row.statusText:SetText("|cff00ff00OK|r")
            else
                row.statusText:SetText("|cffff4444" .. (entry.error or "Fail") .. "|r")
            end
            row:Show()
        else
            row:Hide()
        end
    end
end

function DH.UI:ShowLog()
    self:SelectTab(4)
end

-- ============================================================
-- List manager (tab 2)
-- ============================================================

function DH.UI:CreateListManager()
    local f = CreateFrame("Frame", nil, self.contentFrame)
    f:SetAllPoints()
    CreateBackdrop(f, 0.02, 0.02, 0.04, 0.6)
    f:Hide()
    self.listManagerFrame = f

    -- Whitelist section
    local wlTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wlTitle:SetPoint("TOPLEFT", 10, -8)
    wlTitle:SetText(DH.L:Get("whitelist_title"))

    local wlClear = StyledButton(f, DH.L:Get("btn_clean"), 60, 18)
    wlClear:SetPoint("TOPLEFT", 120, -6)
    wlClear:SetScript("OnClick", function()
        DH.Lists:ClearWhitelist()
        DH.UI:RefreshLists()
    end)

    local wlScroll = CreateFrame("ScrollFrame", "DHWLScroll", f, "FauxScrollFrameTemplate")
    wlScroll:SetPoint("TOPLEFT", 8, -28)
    wlScroll:SetSize(FRAME_WIDTH / 2 - 30, 150)
    self.wlScroll = wlScroll

    local wlRows = {}
    for i = 1, 6 do
        local row = CreateFrame("Button", nil, f)
        row:SetSize(FRAME_WIDTH / 2 - 40, 20)
        row:SetPoint("TOPLEFT", wlScroll, "TOPLEFT", 0, -((i - 1) * 20))

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", 4, 0)
        row.nameText:SetWidth(160)
        row.nameText:SetJustifyH("LEFT")

        local removeBtn = StyledButton(row, "X", 20, 18)
        removeBtn:SetPoint("RIGHT", -2, 0)
        removeBtn:SetScript("OnClick", function()
            if row.itemId then
                DH.Lists:RemoveFromWhitelist(row.itemId)
                DH.UI:RefreshLists()
            end
        end)
        row.removeBtn = removeBtn
        wlRows[i] = row
    end
    self.wlRows = wlRows

    wlScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 20, function()
            DH.UI:UpdateWLRows()
        end)
    end)

    -- Blacklist section
    local blTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    blTitle:SetPoint("TOPLEFT", 10, -190)
    blTitle:SetText(DH.L:Get("blacklist_title"))

    local blClear = StyledButton(f, DH.L:Get("btn_clean"), 60, 18)
    blClear:SetPoint("TOPLEFT", 120, -188)
    blClear:SetScript("OnClick", function()
        DH.Lists:ClearBlacklist()
        DH.UI:RefreshLists()
    end)

    local blScroll = CreateFrame("ScrollFrame", "DHBLScroll", f, "FauxScrollFrameTemplate")
    blScroll:SetPoint("TOPLEFT", 8, -210)
    blScroll:SetSize(FRAME_WIDTH / 2 - 30, 150)
    self.blScroll = blScroll

    local blRows = {}
    for i = 1, 6 do
        local row = CreateFrame("Button", nil, f)
        row:SetSize(FRAME_WIDTH / 2 - 40, 20)
        row:SetPoint("TOPLEFT", blScroll, "TOPLEFT", 0, -((i - 1) * 20))

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", 4, 0)
        row.nameText:SetWidth(160)
        row.nameText:SetJustifyH("LEFT")

        local removeBtn = StyledButton(row, "X", 20, 18)
        removeBtn:SetPoint("RIGHT", -2, 0)
        removeBtn:SetScript("OnClick", function()
            if row.itemId then
                DH.Lists:RemoveFromBlacklist(row.itemId)
                DH.UI:RefreshLists()
            end
        end)
        row.removeBtn = removeBtn
        blRows[i] = row
    end
    self.blRows = blRows

    blScroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 20, function()
            DH.UI:UpdateBLRows()
        end)
    end)

    -- Hint
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", 10, 8)
    hint:SetText(DH.L:Get("lists_tip"))
end

function DH.UI:RefreshLists()
    self:UpdateWLRows()
    self:UpdateBLRows()
end

function DH.UI:UpdateWLRows()
    local list = DH.Lists:GetWhitelist()
    local offset = FauxScrollFrame_GetOffset(self.wlScroll)

    FauxScrollFrame_Update(self.wlScroll, #list, 6, 20)

    for i = 1, 6 do
        local row = self.wlRows[i]
        local idx = offset + i
        if idx <= #list then
            local entry = list[idx]
            row.nameText:SetText(type(entry.name) == "string" and entry.name or ("ID: " .. entry.id))
            row.itemId = entry.id
            row:Show()
        else
            row:Hide()
        end
    end
end

function DH.UI:UpdateBLRows()
    local list = DH.Lists:GetBlacklist()
    local offset = FauxScrollFrame_GetOffset(self.blScroll)

    FauxScrollFrame_Update(self.blScroll, #list, 6, 20)

    for i = 1, 6 do
        local row = self.blRows[i]
        local idx = offset + i
        if idx <= #list then
            local entry = list[idx]
            row.nameText:SetText(type(entry.name) == "string" and entry.name or ("ID: " .. entry.id))
            row.itemId = entry.id
            row:Show()
        else
            row:Hide()
        end
    end
end

-- ============================================================
-- Public API
-- ============================================================

function DH.UI:UpdateEnchantingLevel()
    local hasEnch, rank, maxRank = DH.Disenchant:GetEnchantingInfo()
    if hasEnch then
        self.enchLevelLabel:SetText(string.format(DH.L:Get("enchanting_level"), rank, maxRank))
    else
        self.enchLevelLabel:SetText(DH.L:Get("no_enchanting"))
    end
    return hasEnch
end

function DH.UI:Toggle()
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
    else
        self.mainFrame:Show()
        local hasEnch = self:UpdateEnchantingLevel()
        if not hasEnch then
            DH.UI:ShowPopup({
                text = DH.L:Get("popup_no_enchanting"),
                button1 = DH.L:Get("popup_ok"),
            })
        end
        self:SelectTab(self.currentTab or 1)
    end
end

function DH.UI:ShowConfig()
    self.mainFrame:Show()
    self:SelectTab(3)
end

function DH.UI:Show()
    self.mainFrame:Show()
    self:SelectTab(1)
end
