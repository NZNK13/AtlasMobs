local addonName, AtlasMobs = ...

_G.AtlasMobs = AtlasMobs
AtlasMobs.zones = AtlasMobs.zones or {}
AtlasMobs.callbacks = AtlasMobs.callbacks or {}

local defaults = {
    playerLevel = 15,
    markerSize = 22,
    markerOpacity = 0.90,
    uiScale = 1.00,
    dockMapLeft = false,
    thresholds = { gray = -6, green = -3, yellow = 2, orange = 4 },
    enabledMobs = {},
    filters = { mobType = "All", reaction = "All", relativeLevel = "All", rank = "All", enabledOnly = false },
    window = { point = "CENTER", relativePoint = "CENTER", x = 250, y = 0 },
    minimapAngle = 225,
}

AtlasMobs.colors = {
    gray = { 0.55, 0.55, 0.55 },
    green = { 0.20, 1.00, 0.20 },
    yellow = { 1.00, 0.85, 0.10 },
    orange = { 1.00, 0.50, 0.05 },
    red = { 1.00, 0.15, 0.15 },
}

local function CopyDefaults(source, target)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function AtlasMobs:RegisterZone(zone)
    if type(zone) ~= "table" or type(zone.mapID) ~= "number" or type(zone.mobs) ~= "table" then return end
    table.sort(zone.mobs, function(a, b) return (a.marker or 0) < (b.marker or 0) end)
    self.zones[zone.mapID] = zone
end

function AtlasMobs:GetZone(mapID)
    return self.zones[mapID]
end

function AtlasMobs:GetCurrentMapID()
    if WorldMapFrame and type(WorldMapFrame.GetMapID) == "function" then
        local ok, mapID = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
        if ok and mapID then return mapID end
    end
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and mapID then return mapID end
    end
end

function AtlasMobs:IsMobEnabled(id)
    return AtlasMobsDB.enabledMobs[tostring(id)] ~= false
end

function AtlasMobs:SetMobEnabled(id, enabled)
    AtlasMobsDB.enabledMobs[tostring(id)] = enabled and true or false
    self:RefreshAll()
end

function AtlasMobs:GetAverageLevel(mob)
    return ((mob.minLevel or 0) + (mob.maxLevel or mob.minLevel or 0)) / 2
end

function AtlasMobs:GetDifficulty(mob)
    local delta = self:GetAverageLevel(mob) - (tonumber(AtlasMobsDB.playerLevel) or 1)
    local t = AtlasMobsDB.thresholds
    if delta <= t.gray then return "gray", delta end
    if delta <= t.green then return "green", delta end
    if delta <= t.yellow then return "yellow", delta end
    if delta <= t.orange then return "orange", delta end
    return "red", delta
end

function AtlasMobs:MobMatchesFilters(mob)
    local filters = AtlasMobsDB.filters
    if filters.enabledOnly and not self:IsMobEnabled(mob.id) then return false end
    if filters.mobType ~= "All" and mob.mobType ~= filters.mobType then return false end
    if filters.reaction ~= "All" and mob.reaction ~= string.lower(filters.reaction) then return false end
    if filters.rank == "Elite" and not mob.elite then return false end
    if filters.rank == "Normal" and mob.elite then return false end
    if filters.relativeLevel ~= "All" then
        local _, delta = self:GetDifficulty(mob)
        if filters.relativeLevel == "Below" and delta >= -2 then return false end
        if filters.relativeLevel == "Near" and (delta < -2 or delta > 2) then return false end
        if filters.relativeLevel == "Above" and delta <= 2 then return false end
    end
    return true
end

function AtlasMobs:RefreshAll()
    if type(self.RefreshUI) == "function" then self:RefreshUI() end
    if type(self.RefreshPins) == "function" then self:RefreshPins() end
end

function AtlasMobs:SetStatus(text)
    if self.ui and self.ui.status then
        self.ui.status:SetText(text or "")
    end
end

function AtlasMobs:CopyText(text)
    text = tostring(text or "")
    if type(CopyToClipboard) == "function" then
        local ok = pcall(CopyToClipboard, text)
        if ok then
            self:SetStatus("Copied: " .. text)
            return
        end
    end
    if type(self.ShowCopyBox) == "function" then self:ShowCopyBox(text) end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, loadedName)
    if loadedName ~= addonName then return end
    AtlasMobsDB = type(AtlasMobsDB) == "table" and AtlasMobsDB or {}
    CopyDefaults(defaults, AtlasMobsDB)
    AtlasMobs.db = AtlasMobsDB
    for _, callback in ipairs(AtlasMobs.callbacks) do pcall(callback) end
end)
