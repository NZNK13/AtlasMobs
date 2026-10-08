local _, AtlasMobs = ...

local provider
local attached = false
local PIN_TEMPLATE = "AtlasMobsPinsTemplate"

local pinMixin = CreateFromMixins(MapCanvasPinMixin)

function pinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
    self:SetScalingLimits(1, 1, 1.2)
end

function pinMixin:OnAcquired(mob, point)
    self.mob = mob
    self:SetPosition(point[1], point[2])
    local size = AtlasMobsDB.markerSize or 22
    self:SetSize(size * 2, size * 1.4)
    self.text:SetText(tostring(mob.marker) .. (mob.elite and "*" or ""))
    local font = self.text:GetFont()
    if font then self.text:SetFont(font, size, "OUTLINE") end
    local difficulty = AtlasMobs:GetDifficulty(mob)
    local color = AtlasMobs.colors[difficulty]
    self.text:SetTextColor(color[1], color[2], color[3], AtlasMobsDB.markerOpacity)
    self:SetAlpha(AtlasMobsDB.markerOpacity)
    self:Show()
end

function pinMixin:OnReleased()
    self.mob = nil
    self:Hide()
end

function pinMixin:OnEnter()
    if not self.mob then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.mob.name)
    GameTooltip:AddLine("NPC ID: " .. self.mob.id, 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function pinMixin:OnLeave() GameTooltip:Hide() end

local function AttachProvider()
    if attached or not WorldMapFrame or not MapCanvasDataProviderMixin or not MapCanvasPinMixin then return end
    attached = true
    provider = CreateFromMixins(MapCanvasDataProviderMixin)
    local pool
    if type(CreateUnsecuredRegionPoolInstance) == "function" then
        pool = CreateUnsecuredRegionPoolInstance(PIN_TEMPLATE)
    else
        pool = CreateFramePool("FRAME")
    end
    pool.parent = WorldMapFrame:GetCanvas()
    pool.createFunc = function()
        local pin = CreateFrame("Frame", nil, WorldMapFrame:GetCanvas())
        pin:SetSize(1, 1)
        pin:EnableMouse(true)
        pin.text = pin:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        pin.text:SetPoint("CENTER")
        return Mixin(pin, pinMixin)
    end
    pool.resetFunc = function(_, pin)
        pin:Hide()
        pin:ClearAllPoints()
        pin:OnReleased()
        pin.pinTemplate = nil
        pin.owningMap = nil
    end
    pool.creationFunc = pool.createFunc
    pool.resetterFunc = pool.resetFunc
    WorldMapFrame.pinPools[PIN_TEMPLATE] = pool

    function provider:RemoveAllData()
        self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE)
    end

    function provider:RefreshAllData()
        self:RemoveAllData()
        local map = self:GetMap()
        local zone = AtlasMobs:GetZone(map:GetMapID())
        if not zone then return end
        for _, mob in ipairs(zone.mobs) do
            if AtlasMobs:IsMobEnabled(mob.id) and AtlasMobs:MobMatchesFilters(mob) then
                for _, point in ipairs(mob.points) do map:AcquirePin(PIN_TEMPLATE, mob, point) end
            end
        end
    end

    WorldMapFrame:AddDataProvider(provider)
end

function AtlasMobs:RefreshPins()
    if provider and type(provider.RefreshAllData) == "function" then pcall(provider.RefreshAllData, provider) end
end

table.insert(AtlasMobs.callbacks, AttachProvider)

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
    if name == "Blizzard_WorldMap" then AttachProvider(); AtlasMobs:RefreshPins() end
end)
