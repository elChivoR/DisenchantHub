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

local FRAME_WIDTH = 520
local FRAME_HEIGHT = 480
local ROW_HEIGHT = 22

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
    btn:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 11)
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
        local tab = StyledButton(f, name, 80, 20)
        tab:SetPoint("TOPLEFT", 10 + (i - 1) * 85, -32)
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
    self.selectedItems = {}

    -- Header (aligned to row columns)
    local selectAllCb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    selectAllCb:SetSize(20, 20)
    selectAllCb:SetPoint("TOPLEFT", 6, -4)
    selectAllCb:SetScript("OnClick", function(self)
        DH.UI:ToggleSelectAll(self:GetChecked())
    end)
    self.selectAllCb = selectAllCb

    local hItem = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hItem:SetPoint("TOPLEFT", 48, -6)
    hItem:SetText(DH.L:Get("header_item"))
    hItem:SetTextColor(0.7, 0.7, 0.7)

    local hRarity = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hRarity:SetPoint("TOPLEFT", 245, -6)
    hRarity:SetText(DH.L:Get("header_rarity"))
    hRarity:SetTextColor(0.7, 0.7, 0.7)

    local hIlvl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hIlvl:SetPoint("TOPLEFT", 315, -6)
    hIlvl:SetText(DH.L:Get("header_ilvl"))
    hIlvl:SetTextColor(0.7, 0.7, 0.7)

    local hReq = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hReq:SetPoint("TOPLEFT", 350, -6)
    hReq:SetText(DH.L:Get("header_req"))
    hReq:SetTextColor(0.7, 0.7, 0.7)

    local hType = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hType:SetPoint("TOPLEFT", 389, -6)
    hType:SetText(DH.L:Get("header_type"))
    hType:SetTextColor(0.7, 0.7, 0.7)

    local hSelectLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hSelectLabel:SetPoint("LEFT", selectAllCb, "RIGHT", 0, 0)
    hSelectLabel:SetText("")
    hSelectLabel:SetTextColor(0.7, 0.7, 0.7)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "DHItemScroll", f, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -22)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)
    self.itemScroll = scrollFrame

    local MAX_ROWS = 16
    local rows = {}
    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, f)
        row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))

        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetAlpha(0.3)

        row.cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.cb:SetSize(20, 20)
        row.cb:SetPoint("LEFT", 2, 0)
        row.cb:SetScript("OnClick", function(self)
            local data = row.itemData
            if data and data.canDE then
                local key = data.bag .. ":" .. data.slot
                if self:GetChecked() then
                    DH.UI.selectedItems[key] = data
                else
                    DH.UI.selectedItems[key] = nil
                end
                DH.UI:UpdateSelectedCount()
            else
                self:SetChecked(false)
            end
        end)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", 24, 0)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        row.nameText:SetWidth(175)
        row.nameText:SetJustifyH("LEFT")

        row.rarityText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.rarityText:SetPoint("LEFT", 241, 0)
        row.rarityText:SetWidth(70)

        row.ilvlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.ilvlText:SetPoint("LEFT", 311, 0)
        row.ilvlText:SetWidth(35)

        row.reqText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.reqText:SetPoint("LEFT", 348, 0)
        row.reqText:SetWidth(35)

        row.typeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.typeText:SetPoint("LEFT", 385, 0)
        row.typeText:SetWidth(90)

        row:SetScript("OnEnter", function(self)
            if self.itemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.itemLink)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)

        row:RegisterForClicks("RightButtonUp")
        row:SetScript("OnClick", function(self, button)
            if button == "RightButton" and self.itemData then
                DH.UI:ShowItemContextMenu(self)
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
    if not DH.Disenchant:IsProcessing() then
        self.selectedItems = {}
        if self.selectAllCb then self.selectAllCb:SetChecked(false) end
    end
    self:UpdateItemRows()
    self:UpdateSelectedCount()
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

            row.nameText:SetText(item.name)
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

            local key = item.bag .. ":" .. item.slot
            row.cb:SetChecked(self.selectedItems[key] ~= nil)
            row.cb:Enable(not dim and not DH.Disenchant:IsProcessing())

            row:Show()
        else
            row:Hide()
        end
    end

    if self.selectAllCb then
        self.selectAllCb:Enable(not DH.Disenchant:IsProcessing())
    end
end

function DH.UI:ToggleSelectAll(checked)
    self.selectedItems = {}
    if checked and self.items then
        for _, item in ipairs(self.items) do
            if item.canDE then
                local key = item.bag .. ":" .. item.slot
                self.selectedItems[key] = item
            end
        end
    end
    self:UpdateItemRows()
    self:UpdateSelectedCount()
end

function DH.UI:UpdateSelectedCount()
    local count = 0
    for _ in pairs(self.selectedItems) do count = count + 1 end
    local total = self.items and #self.items or 0

    if self.countLabel then
        self.countLabel:SetText(string.format(DH.L:Get("selected_count"), count, total))
    end
end

function DH.UI:GetSelectedItems()
    local items = {}
    for _, item in pairs(self.selectedItems) do
        table.insert(items, item)
    end
    table.sort(items, function(a, b)
        if a.rarity ~= b.rarity then return a.rarity > b.rarity end
        return a.ilvl > b.ilvl
    end)
    return items
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
        { text = DH.L:Get("select_for_de"), notCheckable = true,
            func = function() DH.Disenchant:PrepareSingle(item.bag, item.slot) end,
            disabled = not item.canDE },
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

    -- "DE Seleccion" queues selected items
    local deSelBtn = StyledButton(bar, DH.L:Get("btn_de_selection"), 95, 24)
    deSelBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 6, 0)
    deSelBtn:SetScript("OnClick", function()
        if DH.Disenchant:IsProcessing() then
            DH.Disenchant:Stop(DH.L:Get("stopped_by_user"))
            return
        end
        local selected = DH.UI:GetSelectedItems()
        if #selected == 0 then
            DH:Print(DH.L:Get("no_selected"))
            return
        end
        if DH.Config:Get("confirmDisenchant") then
            DH.UI:ShowPopup({
                text = string.format(DH.L:Get("popup_confirm_de"), #selected),
                button1 = DH.L:Get("popup_yes"),
                button2 = DH.L:Get("popup_no"),
                OnAccept = function()
                    DH.Disenchant:Start(DH.UI:GetSelectedItems())
                end,
            })
        else
            DH.Disenchant:Start(selected)
        end
    end)
    self.deSelBtn = deSelBtn

    -- The actual secure button that performs the disenchant via macro
    local secureDE = DH.Disenchant.secureBtn
    secureDE:SetParent(bar)
    secureDE:SetSize(150, 24)
    secureDE:SetPoint("LEFT", deSelBtn, "RIGHT", 6, 0)

    -- Visual styling (secure buttons can't use UIPanelButtonTemplate, so we style manually)
    local ntex = secureDE:CreateTexture()
    ntex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    ntex:SetTexCoord(0, 0.625, 0, 0.6875)
    ntex:SetAllPoints()
    secureDE:SetNormalTexture(ntex)

    local htex = secureDE:CreateTexture()
    htex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    htex:SetTexCoord(0, 0.625, 0, 0.6875)
    htex:SetAllPoints()
    secureDE:SetHighlightTexture(htex)

    local ptex = secureDE:CreateTexture()
    ptex:SetTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    ptex:SetTexCoord(0, 0.625, 0, 0.6875)
    ptex:SetAllPoints()
    secureDE:SetPushedTexture(ptex)

    local label = secureDE:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetText(DH.L:Get("btn_no_item"))
    secureDE.label = label

    -- PostClick fires after the secure action completes (not protected)
    secureDE:SetScript("PostClick", function()
        DH.Disenchant:OnSecureClick()
    end)

    secureDE:Show()
    self.secureDEBtn = secureDE

    -- Stop button
    local stopBtn = StyledButton(bar, DH.L:Get("btn_stop"), 50, 24)
    stopBtn:SetPoint("LEFT", secureDE, "RIGHT", 6, 0)
    stopBtn:SetScript("OnClick", function()
        DH.Disenchant:Stop(DH.L:Get("stopped_by_user"))
    end)

    local countLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("RIGHT", -4, 0)
    self.countLabel = countLabel

    -- Custom popup anchored to mainFrame
    self:CreatePopup()
end

function DH.UI:UpdateDEButton(item, queueCount)
    if not self.secureDEBtn then return end

    if item and queueCount > 0 then
        local shortName = item.name
        if #shortName > 15 then
            shortName = shortName:sub(1, 14) .. ".."
        end
        self.secureDEBtn.label:SetText(string.format(DH.L:Get("de_label"), shortName, queueCount))
    else
        self.secureDEBtn.label:SetText(DH.L:Get("btn_no_item"))
        if not DH.Disenchant:IsProcessing() then
            self.selectedItems = {}
            if self.selectAllCb then self.selectAllCb:SetChecked(false) end
            self:UpdateItemRows()
            self:UpdateSelectedCount()
        end
    end
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
        DH.Config:Set("maxIlvl", tonumber(self:GetText()) or 999)
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

    local confirmCb = StyledCheckbox(f, DH.L:Get("cfg_confirm_bulk"), function(self)
        DH.Config:Set("confirmDisenchant", self:GetChecked() and true or false)
    end)
    confirmCb:SetPoint("TOPLEFT", 10, y)
    self.cfgConfirm = confirmCb
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
    self.cfgConfirm:SetChecked(cfg:Get("confirmDisenchant"))
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
    hTime:SetPoint("TOPLEFT", 8, -22)
    hTime:SetTextColor(0.8, 0.8, 0.5)
    hTime:SetText(DH.L:Get("log_header_time"))

    local hItem = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hItem:SetPoint("TOPLEFT", 72, -22)
    hItem:SetTextColor(0.8, 0.8, 0.5)
    hItem:SetText(DH.L:Get("log_header_item"))

    local hLoot = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hLoot:SetPoint("TOPLEFT", 259, -22)
    hLoot:SetTextColor(0.8, 0.8, 0.5)
    hLoot:SetText(DH.L:Get("log_header_loot"))

    -- Scroll
    local scrollFrame = CreateFrame("ScrollFrame", "DHLogScroll", f, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -36)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)
    self.logScroll = scrollFrame

    local MAX_LOG_ROWS = 15
    local logRows = {}
    for i = 1, MAX_LOG_ROWS do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(FRAME_WIDTH - 50, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))

        row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.timeText:SetPoint("LEFT", 4, 0)
        row.timeText:SetWidth(60)
        row.timeText:SetTextColor(0.6, 0.6, 0.6)

        row.itemText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.itemText:SetPoint("LEFT", 68, 0)
        row.itemText:SetWidth(180)
        row.itemText:SetJustifyH("LEFT")

        row.lootText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.lootText:SetPoint("LEFT", 255, 0)
        row.lootText:SetWidth(200)
        row.lootText:SetJustifyH("LEFT")

        row.statusText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
