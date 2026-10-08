local _, AtlasMobs = ...

local function UpdatePosition(button)
    local angle = math.rad(AtlasMobsDB.minimapAngle or 225)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

local function CreateMinimapButton()
    if AtlasMobs.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "AtlasMobsMinimapButton", Minimap)
    AtlasMobs.minimapButton = button
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp")

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(24, 24)
    background:SetPoint("CENTER")
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button:SetScript("OnClick", function() AtlasMobs:Toggle() end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("AtlasMobs")
        GameTooltip:AddLine("Left-click to open.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        local x, y = GetCursorPosition()
        x, y = x / scale - mx, y / scale - my
        AtlasMobsDB.minimapAngle = math.deg(math.atan2(y, x))
        UpdatePosition(self)
    end) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    UpdatePosition(button)
end

table.insert(AtlasMobs.callbacks, CreateMinimapButton)
