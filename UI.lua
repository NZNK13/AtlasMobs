local addonName, AtlasMobs = ...

local function AddText(parent, text, size, anchor, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", size and "GameFontNormal" or "GameFontHighlightSmall")
    fs:SetPoint(anchor or "TOPLEFT", x or 0, y or 0)
    fs:SetText(text or "")
    if size then
        local font = fs:GetFont()
        if font then fs:SetFont(font, size, "") end
    end
    return fs
end

local function MakeEdit(parent, width, numeric)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, 22)
    edit:SetAutoFocus(false)
    if numeric then edit:SetNumeric(true) end
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return edit
end

local function MakeDropdown(parent, label, values, dbKey, x, y, width)
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    AddText(parent, label, nil, "TOPLEFT", x, y)
    local button = CreateFrame("Button", nil, parent, template)
    button:SetSize(width or 80, 20)
    button:SetPoint("TOPLEFT", x, y - 13)
    if button.SetBackdrop then
        button:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=10, insets={left=2,right=2,top=2,bottom=2} })
        button:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
        button:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
    end
    button.valueText = AddText(button, "", nil, "LEFT", 6, 0)
    button.arrowText = AddText(button, "v", nil, "RIGHT", -6, 0)
    button.arrowText:SetTextColor(1, 0.82, 0)
    local menu = CreateFrame("Frame", nil, parent, template)
    menu:SetSize(width or 80, #values * 20 + 8)
    menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -1)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(parent:GetFrameLevel() + 30)
    if menu.SetBackdrop then
        menu:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=12, insets={left=3,right=3,top=3,bottom=3} })
    end
    menu:Hide()
    parent.dropdownMenus = parent.dropdownMenus or {}
    table.insert(parent.dropdownMenus, menu)

    function button:Refresh()
        self.valueText:SetText(tostring(AtlasMobsDB.filters[dbKey] or values[1]))
    end
    button:SetScript("OnClick", function()
        for _, other in ipairs(parent.dropdownMenus) do if other ~= menu then other:Hide() end end
        if menu:IsShown() then menu:Hide() else menu:Show() end
    end)
    button:SetScript("OnEnter", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(1, 0.82, 0, 1) end end)
    button:SetScript("OnLeave", function(self) if self.SetBackdropBorderColor then self:SetBackdropBorderColor(0.55, 0.45, 0.25, 1) end end)
    for index, value in ipairs(values) do
        local option = CreateFrame("Button", nil, menu)
        option:SetSize((width or 80) - 8, 20)
        option:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 20)
        option.text = AddText(option, value, nil, "LEFT", 4, 0)
        option:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        option:SetScript("OnClick", function()
            AtlasMobsDB.filters[dbKey] = value
            button:Refresh()
            menu:Hide()
            AtlasMobs:RefreshAll()
        end)
    end
    return button
end

local function MakeSlider(parent, label, minValue, maxValue, step, x, y, width, getter, setter, format)
    local title = AddText(parent, label, nil, "TOPLEFT", x, y)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 14)
    slider:SetSize(width, 16)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    if type(slider.SetObeyStepOnDrag) == "function" then slider:SetObeyStepOnDrag(true) end
    slider.valueText = AddText(parent, "", nil, "TOPLEFT", x + width + 7, y - 15)
    slider:SetValue(getter())
    slider.valueText:SetText(string.format(format, getter()))
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        setter(value)
        self.valueText:SetText(string.format(format, value))
        AtlasMobs:RefreshAll()
    end)
    return slider, title
end

local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(390, 22)
    if index % 2 == 0 then
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(1, 1, 1, 0.035)
    end

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(20, 20)
    row.check:SetPoint("LEFT", 0, 0)
    row.marker = AddText(row, "", nil, "LEFT", 25, 0)

    row.idButton = CreateFrame("Button", nil, row)
    row.idButton:SetSize(60, 20)
    row.idButton:SetPoint("LEFT", 50, 0)
    row.idText = AddText(row.idButton, "", nil, "LEFT", 0, 0)
    row.idText:SetTextColor(0.35, 0.75, 1)

    row.nameButton = CreateFrame("Button", nil, row)
    row.nameButton:SetSize(150, 20)
    row.nameButton:SetPoint("LEFT", 103, 0)
    row.nameText = AddText(row.nameButton, "", nil, "LEFT", 0, 0)
    row.nameText:SetWidth(150)
    row.nameText:SetWordWrap(false)
    row.nameText:SetJustifyH("LEFT")

    row.levels = AddText(row, "", nil, "LEFT", 253, 0)
    row.mobType = AddText(row, "", nil, "LEFT", 295, 0)
    row.skin = AddText(row, "—", nil, "LEFT", 370, 0)

    row:SetScript("OnEnter", function(self)
        if not self.mob then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.mob.name)
        GameTooltip:AddLine("Click ID or name to copy.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

local function CreateUI()
    if AtlasMobs.ui then return end
    local template = BackdropTemplateMixin and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", "AtlasMobsMainFrame", UIParent, template)
    AtlasMobs.ui = frame
    frame:SetSize(445, 775)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not AtlasMobsDB.dockMapLeft then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if AtlasMobsDB.dockMapLeft then return end
        local point, _, relativePoint, x, y = self:GetPoint(1)
        AtlasMobsDB.window.point, AtlasMobsDB.window.relativePoint = point, relativePoint
        AtlasMobsDB.window.x, AtlasMobsDB.window.y = x, y
    end)
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=20, insets={left=5,right=5,top=5,bottom=5} })
    end
    local p = AtlasMobsDB.window
    frame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or 0)
    frame:SetScale(AtlasMobsDB.uiScale)
    frame:Hide()

    local title = AddText(frame, "AtlasMobs", 16, "TOPLEFT", 16, -13)
    title:SetTextColor(1, 0.82, 0)
    local version
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        local ok, value = pcall(C_AddOns.GetAddOnMetadata, addonName, "Version")
        if ok then version = value end
    end
    frame.versionText = AddText(frame, version and ("v" .. version) or "", nil, "TOPLEFT", 116, -16)
    frame.versionText:SetTextColor(0.65, 0.65, 0.65)
    frame.zoneText = AddText(frame, "", nil, "TOPLEFT", 162, -16)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    AddText(frame, "Player level", nil, "TOPLEFT", 16, -35)
    frame.levelEdit = MakeEdit(frame, 28, true)
    frame.levelEdit:SetPoint("TOPLEFT", 16, -47)
    frame.levelEdit:SetMaxLetters(2)
    frame.levelEdit:SetText(AtlasMobsDB.playerLevel)
    frame.levelEdit:SetScript("OnEnterPressed", function(self)
        local value = math.max(1, math.min(80, tonumber(self:GetText()) or AtlasMobsDB.playerLevel))
        AtlasMobsDB.playerLevel = value
        self:SetText(value)
        self:ClearFocus()
        AtlasMobs:RefreshAll()
    end)

    AddText(frame, "Marker size", nil, "TOPLEFT", 90, -35)
    frame.markerSizeEdit = MakeEdit(frame, 28, true)
    frame.markerSizeEdit:SetPoint("TOPLEFT", 90, -47)
    frame.markerSizeEdit:SetMaxLetters(2)
    frame.markerSizeEdit:SetText(AtlasMobsDB.markerSize)
    frame.markerSizeEdit:SetScript("OnEnterPressed", function(self)
        local value = math.floor(tonumber(self:GetText()) or AtlasMobsDB.markerSize)
        value = math.max(8, math.min(48, value))
        AtlasMobsDB.markerSize = value
        self:SetText(value)
        self:ClearFocus()
        AtlasMobs:RefreshPins()
        AtlasMobs:SetStatus("Marker size updated.")
    end)

    AddText(frame, "Opacity", nil, "TOPLEFT", 180, -35)
    frame.opacityEdit = MakeEdit(frame, 42, false)
    frame.opacityEdit:SetPoint("TOPLEFT", 180, -47)
    frame.opacityEdit:SetMaxLetters(4)
    frame.opacityEdit:SetText(string.format("%.2f", AtlasMobsDB.markerOpacity))
    frame.opacityEdit:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or AtlasMobsDB.markerOpacity
        value = math.max(0.10, math.min(1.00, value))
        AtlasMobsDB.markerOpacity = value
        self:SetText(string.format("%.2f", value))
        self:ClearFocus()
        AtlasMobs:RefreshPins()
        AtlasMobs:SetStatus("Opacity updated.")
    end)

    AddText(frame, "Window scale", nil, "TOPLEFT", 260, -35)
    frame.scaleEdit = MakeEdit(frame, 45, false)
    frame.scaleEdit:SetPoint("TOPLEFT", 260, -47)
    frame.scaleEdit:SetText(string.format("%.2f", AtlasMobsDB.uiScale))
    frame.scaleEdit:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or AtlasMobsDB.uiScale
        value = math.max(0.50, math.min(1.50, value))
        AtlasMobsDB.uiScale = value
        self:SetText(string.format("%.2f", value))
        self:ClearFocus()
        frame:SetScale(value)
        if type(AtlasMobs.ApplyPanelDock) == "function" then AtlasMobs:ApplyPanelDock() end
        AtlasMobs:SetStatus("Window scale updated.")
    end)

    frame.dockMapCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.dockMapCheck:SetSize(20, 20)
    frame.dockMapCheck:SetPoint("TOPLEFT", 342, -46)
    frame.dockMapCheck:SetChecked(AtlasMobsDB.dockMapLeft)
    AddText(frame.dockMapCheck, "Dock map left", nil, "LEFT", 20, 0)
    frame.dockMapCheck:SetScript("OnClick", function(self)
        AtlasMobsDB.dockMapLeft = self:GetChecked() and true or false
        if type(AtlasMobs.ApplyMapDock) == "function" then AtlasMobs:ApplyMapDock() end
        if type(AtlasMobs.ApplyPanelDock) == "function" then AtlasMobs:ApplyPanelDock() end
    end)

    frame.filterButtons = {
        MakeDropdown(frame, "Type", {"All","Humanoid","Beast","Undead","Demon","Elemental"}, "mobType", 16, -79, 80),
        MakeDropdown(frame, "Reaction", {"All","Hostile","Neutral"}, "reaction", 100, -79, 80),
        MakeDropdown(frame, "Level", {"All","Below","Near","Above"}, "relativeLevel", 184, -79, 70),
        MakeDropdown(frame, "Rank", {"All","Normal","Elite"}, "rank", 258, -79, 64),
    }
    for _, button in ipairs(frame.filterButtons) do button:Refresh() end

    frame.enabledOnlyCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.enabledOnlyCheck:SetSize(20, 20)
    frame.enabledOnlyCheck:SetPoint("TOPLEFT", 330, -92)
    frame.enabledOnlyCheck:SetChecked(AtlasMobsDB.filters.enabledOnly)
    AddText(frame.enabledOnlyCheck, "Enabled only", nil, "LEFT", 20, 0)
    frame.enabledOnlyCheck:SetScript("OnClick", function(self)
        AtlasMobsDB.filters.enabledOnly = self:GetChecked() and true or false
        AtlasMobs:RefreshAll()
    end)

    frame.toggleAllButton = CreateFrame("Button", nil, frame, template)
    frame.toggleAllButton:SetSize(94, 20)
    frame.toggleAllButton:SetPoint("TOPLEFT", 330, -116)
    if frame.toggleAllButton.SetBackdrop then
        frame.toggleAllButton:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=10, insets={left=2,right=2,top=2,bottom=2} })
        frame.toggleAllButton:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
        frame.toggleAllButton:SetBackdropBorderColor(0.55, 0.45, 0.25, 1)
    end
    frame.toggleAllButton.text = AddText(frame.toggleAllButton, "Select all", nil, "CENTER", 0, 0)
    frame.toggleAllButton:SetScript("OnClick", function()
        local zone = AtlasMobs:GetZone(AtlasMobs:GetCurrentMapID())
        if not zone then return end
        local allEnabled = true
        for _, mob in ipairs(zone.mobs) do
            if not AtlasMobs:IsMobEnabled(mob.id) then allEnabled = false; break end
        end
        for _, mob in ipairs(zone.mobs) do
            AtlasMobsDB.enabledMobs[tostring(mob.id)] = not allEnabled
        end
        AtlasMobs:RefreshAll()
    end)

    AddText(frame, "Color limits", nil, "TOPLEFT", 16, -151)
    frame.thresholdEdits = {}
    local thresholdDefs = {{"Gray", "gray"}, {"Green", "green"}, {"Yellow", "yellow"}, {"Orange", "orange"}}
    for index, def in ipairs(thresholdDefs) do
        local x = ({90, 158, 236, 316})[index]
        AddText(frame, def[1], nil, "TOPLEFT", x, -151)
        local edit = MakeEdit(frame, 28, false)
        local editX = ({120, 198, 278, 360})[index]
        edit:SetPoint("TOPLEFT", editX, -146)
        edit:SetMaxLetters(2)
        edit:SetText(AtlasMobsDB.thresholds[def[2]])
        frame.thresholdEdits[def[2]] = edit
        edit:SetScript("OnEnterPressed", function(self)
            local values = {}
            for key, box in pairs(frame.thresholdEdits) do values[key] = tonumber(box:GetText()) end
            if values.gray and values.green and values.yellow and values.orange and values.gray <= values.green and values.green <= values.yellow and values.yellow <= values.orange then
                for key, value in pairs(values) do AtlasMobsDB.thresholds[key] = value end
                AtlasMobs:SetStatus("Color limits updated.")
                AtlasMobs:RefreshAll()
            else
                AtlasMobs:SetStatus("Limits must increase from Gray to Orange.")
                for key, box in pairs(frame.thresholdEdits) do box:SetText(AtlasMobsDB.thresholds[key]) end
            end
            self:ClearFocus()
        end)
    end

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 16, -183)
    header:SetSize(390, 20)
    local headers = {{"Show",0},{"#",28},{"NPC ID",50},{"Name",103},{"Levels",253},{"Type",295},{"Skin",370}}
    for _, item in ipairs(headers) do
        local fs = AddText(header, item[1], nil, "LEFT", item[2], 0)
        fs:SetTextColor(1, 0.82, 0)
    end

    local scroll = CreateFrame("ScrollFrame", "AtlasMobsScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -205)
    scroll:SetPoint("BOTTOMRIGHT", -44, 36)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(390, 1)
    scroll:SetScrollChild(content)
    frame.scrollContent = content
    frame.rows = {}

    frame.status = AddText(frame, "", nil, "BOTTOMLEFT", 16, 16)
    frame.status:SetTextColor(0.7, 0.7, 0.7)

    local copyPanel = CreateFrame("Frame", nil, frame, template)
    copyPanel:SetSize(300, 80)
    copyPanel:SetPoint("CENTER")
    copyPanel:SetFrameLevel(frame:GetFrameLevel() + 20)
    if copyPanel.SetBackdrop then copyPanel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=18}) end
    AddText(copyPanel, "Press Ctrl+C", nil, "TOPLEFT", 14, -12)
    copyPanel.edit = MakeEdit(copyPanel, 250, false)
    copyPanel.edit:SetPoint("TOPLEFT", 14, -35)
    copyPanel.edit:SetScript("OnEscapePressed", function(self) self:GetParent():Hide() end)
    copyPanel:Hide()
    frame.copyPanel = copyPanel
    frame:HookScript("OnHide", function(self)
        for _, menu in ipairs(self.dropdownMenus or {}) do menu:Hide() end
    end)
end

function AtlasMobs:ShowCopyBox(text)
    if not self.ui then return end
    local panel = self.ui.copyPanel
    panel:Show()
    panel.edit:SetText(text)
    panel.edit:SetFocus()
    panel.edit:HighlightText()
    self:SetStatus("Clipboard API unavailable; press Ctrl+C.")
end

function AtlasMobs:RefreshUI()
    local frame = self.ui
    if not frame or not frame.rows then return end
    local mapID = self:GetCurrentMapID()
    local zone = self:GetZone(mapID)
    frame.zoneText:SetText(zone and zone.name or "Zone not supported")
    if frame.toggleAllButton then
        local allEnabled = zone and #zone.mobs > 0
        if zone then
            for _, mob in ipairs(zone.mobs) do
                if not self:IsMobEnabled(mob.id) then allEnabled = false; break end
            end
        end
        frame.toggleAllButton.text:SetText(allEnabled and "Clear all" or "Select all")
    end

    local visible = {}
    if zone then
        for _, mob in ipairs(zone.mobs) do
            if self:MobMatchesFilters(mob) then table.insert(visible, mob) end
        end
    end
    for index, mob in ipairs(visible) do
        local row = frame.rows[index]
        if not row then
            row = CreateRow(frame.scrollContent, index)
            frame.rows[index] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * 22)
        row.mob = mob
        row.check:SetChecked(self:IsMobEnabled(mob.id))
        row.check:SetScript("OnClick", function(button) AtlasMobs:SetMobEnabled(mob.id, button:GetChecked()) end)
        row.marker:SetText(tostring(mob.marker) .. (mob.elite and "*" or ""))
        local difficulty = self:GetDifficulty(mob)
        local color = self.colors[difficulty]
        row.marker:SetTextColor(color[1], color[2], color[3])
        row.idText:SetText(mob.id)
        row.idButton:SetScript("OnClick", function() AtlasMobs:CopyText(mob.id) end)
        local displayName = mob.name
        if #displayName > 25 then displayName = string.sub(displayName, 1, 22) .. "..." end
        row.nameText:SetText(displayName)
        row.nameText:SetTextColor(mob.reaction == "hostile" and 1 or 1, mob.reaction == "hostile" and 0.18 or 0.82, mob.reaction == "hostile" and 0.18 or 0)
        row.nameButton:SetScript("OnClick", function() AtlasMobs:CopyText(mob.name) end)
        row.levels:SetText(mob.minLevel == mob.maxLevel and mob.minLevel or (mob.minLevel .. "-" .. mob.maxLevel))
        row.mobType:SetText(mob.mobType)
        row.skin:SetText("—")
        row:Show()
    end
    for index = #visible + 1, #frame.rows do frame.rows[index]:Hide() end
    frame.scrollContent:SetHeight(math.max(1, #visible * 22))
    self:SetStatus(zone and (#visible .. " mobs shown") or "Open a supported zone on the map.")
end

function AtlasMobs:Toggle()
    if not self.ui then return end
    if self.ui:IsShown() then self.ui:Hide() else self.ui:Show(); self:RefreshAll() end
end

function AtlasMobs:ApplyPanelDock()
    local frame = self.ui
    if not frame or not AtlasMobsDB then return end
    frame:ClearAllPoints()
    if AtlasMobsDB.dockMapLeft then
        local scale = frame:GetScale() or 1
        local availableHeight = math.max(300, (UIParent:GetHeight() - 16) / scale)
        frame:SetSize(445, availableHeight)
        frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -8, -8)
    else
        frame:SetSize(445, 775)
        local p = AtlasMobsDB.window
        frame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or 0)
    end
end

local mapHooked = false
local originalMapPoints
local originalMapTopOffset
local mapDockApplied = false

local function CaptureMapPosition()
    if originalMapPoints or not WorldMapFrame then return end
    originalMapPoints = {}
    for index = 1, WorldMapFrame:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = WorldMapFrame:GetPoint(index)
        table.insert(originalMapPoints, { point, relativeTo, relativePoint, x, y })
    end
    if WorldMapFrame:GetTop() and UIParent:GetTop() then
        originalMapTopOffset = WorldMapFrame:GetTop() - UIParent:GetTop()
    end
end

function AtlasMobs:ApplyMapDock()
    if not WorldMapFrame or not AtlasMobsDB then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        self.pendingMapDock = true
        self:SetStatus("Map position will update after combat.")
        return
    end
    local shouldDock = AtlasMobsDB.dockMapLeft and WorldMapFrame.isMaximized == true
    if not shouldDock and not mapDockApplied then return end
    if shouldDock then CaptureMapPosition() end
    if shouldDock and (not originalMapPoints or #originalMapPoints == 0) then return end
    local ok = pcall(function()
        if shouldDock then
            WorldMapFrame:ClearAllPoints()
            WorldMapFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, originalMapTopOffset or 0)
            mapDockApplied = true
        elseif mapDockApplied and originalMapPoints and #originalMapPoints > 0 then
            WorldMapFrame:ClearAllPoints()
            for _, point in ipairs(originalMapPoints) do
                WorldMapFrame:SetPoint(point[1], point[2], point[3], point[4], point[5])
            end
            mapDockApplied = false
            originalMapPoints = nil
            originalMapTopOffset = nil
        end
    end)
    if not ok then
        pcall(function()
            if originalMapPoints and #originalMapPoints > 0 then
                WorldMapFrame:ClearAllPoints()
                for _, point in ipairs(originalMapPoints) do
                    WorldMapFrame:SetPoint(point[1], point[2], point[3], point[4], point[5])
                end
            end
        end)
        mapDockApplied = false
        self:SetStatus("Could not move the world map.")
    end
end

local function HookWorldMap()
    if mapHooked or not WorldMapFrame then return end
    mapHooked = true
    WorldMapFrame:HookScript("OnShow", function()
        if AtlasMobs.ui then AtlasMobs.ui.openedByMap = true; AtlasMobs.ui:Show(); AtlasMobs:RefreshAll() end
        AtlasMobs:ApplyPanelDock()
        if C_Timer and type(C_Timer.After) == "function" then
            C_Timer.After(0, function() AtlasMobs:ApplyMapDock() end)
        else
            AtlasMobs:ApplyMapDock()
        end
    end)
    WorldMapFrame:HookScript("OnHide", function()
        if AtlasMobs.ui and AtlasMobs.ui.openedByMap then AtlasMobs.ui.openedByMap = nil; AtlasMobs.ui:Hide() end
    end)
    WorldMapFrame:HookScript("OnSizeChanged", function()
        if AtlasMobsDB and AtlasMobsDB.dockMapLeft and C_Timer and type(C_Timer.After) == "function" then
            C_Timer.After(0, function() AtlasMobs:ApplyMapDock() end)
        end
    end)
    if WorldMapFrame:IsShown() and AtlasMobs.ui then
        AtlasMobs.ui.openedByMap = true
        AtlasMobs.ui:Show()
        AtlasMobs:RefreshAll()
        AtlasMobs:ApplyMapDock()
    end
end

table.insert(AtlasMobs.callbacks, function()
    CreateUI()
    AtlasMobs:ApplyPanelDock()
    HookWorldMap()
end)

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:RegisterEvent("DISPLAY_SIZE_CHANGED")
loader:SetScript("OnEvent", function(_, event, name)
    if name == "Blizzard_WorldMap" then HookWorldMap() end
    if event == "PLAYER_REGEN_ENABLED" and AtlasMobs.pendingMapDock then
        AtlasMobs.pendingMapDock = nil
        AtlasMobs:ApplyMapDock()
    end
    if event == "DISPLAY_SIZE_CHANGED" then AtlasMobs:ApplyPanelDock() end
end)
