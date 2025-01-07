-- ExploreWithTomTom.lua

-- Import the waypoint data
function LoadWaypointData()
    local locale = GetLocale() -- Get the user's locale (e.g., "enUS", "frFR")

    if Localization and Localization[locale] then
        return Localization[locale] -- Load localization for the current locale
    else
        print("|cFFFF0000Localization for " .. locale .. " not found. Falling back to enUS.|r")
        return Localization["enUS"] -- Fallback to enUS
    end
end

-- Load the waypoint data
WaypointData = LoadWaypointData()

local activeWaypoints = {}
local queuedZone = nil
local currentZone = nil
local currentProxy = nil

-- Function to check if a zone is already discovered
function IsZoneDiscovered(achievementID, zoneName)
        -- Special handling for Isle of Quel'Danas
        if achievementID == 868 then
            -- First, check if the achievement is completed (account-wide)
            local _, _, achievementCompleted = GetAchievementInfo(achievementID)
            if achievementCompleted then
                return true
            end
            
            -- If not completed, check if the current character has explored the zone
            local isleQuelDanasMapID = 122  -- Map ID for Isle of Quel'Danas
            local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(isleQuelDanasMapID)
            return exploredMapTextures ~= nil and #exploredMapTextures > 0
        end

        -- Existing logic for other zones
        local numCriteria = GetAchievementNumCriteria(achievementID)
        local trimmedZoneName = strtrim(zoneName):lower()

        for i = 1, numCriteria do
            local criteriaString, _, completed = GetAchievementCriteriaInfo(achievementID, i)
            if strtrim(criteriaString):lower() == trimmedZoneName then
                return completed
            end
        end

        -- Additionally, check if the entire achievement is completed
        local _, _, achievementCompleted = GetAchievementInfo(achievementID)
        return achievementCompleted
end

-- Function to remove waypoints when leaving a zone
function RemoveAllWaypoints()
    for desc, uid in pairs(activeWaypoints) do
        TomTom:RemoveWaypoint(uid)
    end
    activeWaypoints = {}  -- Clear the active waypoints table
end

-- Function to add waypoints for a specific zone and return whether any were added
function AddWaypointsForZone(continentName, zoneName)
    -- Clear existing waypoints to avoid duplication
    RemoveAllWaypoints()

    -- Access waypoint data for the specified continent and zone
    local continentInfo = WaypointData[continentName]
    if not continentInfo then
        print("|cFFFF0000Continent not found: " .. (continentName or "unknown") .. "|r")
        return false
    end

    local zoneInfo = continentInfo[zoneName]
    if not zoneInfo then
        print("|cFFFF0000Zone not found: " .. (zoneName or "unknown") .. "|r")
        return false
    end

    -- Validate the player's current map position
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        print("|cFFFF0000Failed to retrieve player's current map ID.|r")
        return false
    end

    local waypointsAdded = false

    -- Iterate through waypoints for the zone
    for _, waypoint in ipairs(zoneInfo.waypoints) do
        local x, y, description = unpack(waypoint)
        local normalizedX = tonumber(x) / 100
        local normalizedY = tonumber(y) / 100

        -- Skip waypoints that are already discovered
        if not IsZoneDiscovered(zoneInfo.achievementID, description) then
            local uid = TomTom:AddWaypoint(mapID, normalizedX, normalizedY, { title = description })
            if uid then
                activeWaypoints[description] = uid
                waypointsAdded = true

                -- Monitor discovery status for the waypoint
                local ticker = C_Timer.NewTicker(0.1, function(self)
                    if IsZoneDiscovered(zoneInfo.achievementID, description) then
                        -- Remove the waypoint if discovered
                        TomTom:RemoveWaypoint(uid)
                        activeWaypoints[description] = nil
                        self:Cancel() -- Stop monitoring
                        --print("|cFF00FF00Waypoint discovered and removed: " .. description .. "|r")
                    end
                end)
            else
                --print("|cFFFF0000Failed to add waypoint: " .. description .. "|r")
            end
        else
            --print("|cFF00FF00Waypoint already discovered: " .. description .. "|r")
        end
    end

    if waypointsAdded then
        --print("|cFF00FF00Waypoints added for zone: " .. zoneName .. "|r")
        currentZone = zoneName -- Update current zone tracking
        return true
    else
        print("|cFFFF0000No undiscovered waypoints found in " .. zoneName .. "|r")
        return false
    end
end

function GetContinentMapID(continentName)
    local continentMapIDs = {
        -- EN
        ["Eastern Kingdoms"] = 13,
        ["Outland"] = 101,
        ["Cataclysm"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Draenor"] = 572,
        ["Battle for Azeroth"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Kalimdor"] = 12,
        ["Northrend"] = 113,
        ["Pandaria"] = 424,
        ["Broken Isles"] = 619,
    
        -- FR
        ["Royaumes de l’Est"] = 13,
        ["Outreterre"] = 101,
        ["Cataclysme"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Draenor"] = 572,
        ["Bataille pour Azeroth"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Kalimdor"] = 12,
        ["Norfendre"] = 113,
        ["Pandarie"] = 424,
        ["îles Brisées"] = 619,
    
        -- RU
        ["Восточные королевства"] = 13,
        ["Запределье"] = 101,
        ["Катаклизм"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Дренор"] = 572,
        ["Битва за Азерот"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Калимдор"] = 12,
        ["Нордскол"] = 113,
        ["Пандария"] = 424,
        ["Расколотые острова"] = 619,
    
        -- DE
        ["Östlichen Königreiche"] = 13,
        ["Scherbenwelt"] = 101,
        ["Kataklysmus"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Draenor"] = 572,
        ["Schlacht um Azeroth"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Kalimdor"] = 12,
        ["Nordends"] = 113,
        ["Pandaria"] = 424,
        ["Verheerten Inseln"] = 619,
    
        -- ES (EU)
        ["Reinos del Este"] = 13,
        ["Terrallende"] = 101,
        ["Cataclismo"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Draenor"] = 572,
        ["Batalla por Azeroth"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Kalimdor"] = 12,
        ["Rasganorte"] = 113,
        ["Pandaria"] = 424,
        ["Islas Quebradas"] = 619,
    
        -- IT
        ["Regni Orientali"] = 13,
        ["Terre Esterne"] = 101,
        ["Cataclisma"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Draenor"] = 572,
        ["Battaglia per Azeroth"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Kalimdor"] = 12,
        ["Nordania"] = 113,
        ["Pandaria"] = 424,
        ["Isole Disperse"] = 619,
    
        -- PT
        ["Reinos do Leste"] = 13,
        ["Terralém"] = 101,
        ["Cataclismo"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["Draenor"] = 572,
        ["Batalha por Azeroth"] = {875, 876}, -- Zandalar and Kul Tiras
        ["Kalimdor"] = 12,
        ["Nortúndria"] = 113,
        ["Pandária"] = 424,
        ["Ilhas Partidas"] = 619,
    
        -- KO
        ["동부 왕국"] = 13,
        ["아웃랜드"] = 101,
        ["대격변"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["드레노어"] = 572,
        ["격전의 아제로스"] = {875, 876}, -- Zandalar and Kul Tiras
        ["칼림도어"] = 12,
        ["노스렌드"] = 113,
        ["판다리아"] = 424,
        ["부서진 섬"] = 619,
    
        -- ZH-CN
        ["东部王国"] = 13,
        ["外域"] = 101,
        ["大灾变"] = {198,249,207,241,203}, -- Hyjal, Uldum, Deepholm, Twillight Highlands, Vashj'ir
        ["德拉诺"] = 572,
        ["艾泽拉斯之战"] = {875, 876}, -- Zandalar and Kul Tiras
        ["卡利姆多"] = 12,
        ["诺森德"] = 113,
        ["潘达利亚"] = 424,
        ["破碎群岛"] = 619,
    }
    
    
    local mapID = continentMapIDs[continentName]
    return mapID
    
end

function LocalizeContinent(continentKey)
    local locale = GetLocale()
    if Localization 
       and Localization[locale] 
       and Localization[locale]["Continents"]
       and Localization[locale]["Continents"][continentKey] then

        return Localization[locale]["Continents"][continentKey]
    end
    -- Fallback to English key if no translation
    return continentKey
end

-- Helper table for zone-specific overrides
local zoneOverrides = {
    ["Dalaran"] = { continent = "Northrend" },
    ["Stormshield"] = { continent = "Draenor" },
    ["Ashran"] = { continent = "Draenor" },
    ["Deathknell"] = { continent = "Eastern Kingdoms", zone = "Tirisfal Glades" },
    ["Coldridge Valley"] = { continent = "Eastern Kingdoms", zone = "Dun Morogh" },
    ["New Tinkertown"] = { continent = "Eastern Kingdoms", zone = "Dun Morogh" },
    ["Vashj'ir"] = { continent = "Eastern Kingdoms" },
    ["Abyssal Depths"] = { continent = "Eastern Kingdoms" },
    ["Shimmering Expanse"] = { continent = "Eastern Kingdoms" },
    ["Kelp'thar Forest"] = { continent = "Eastern Kingdoms" },
    ["Tiragarde Sound"] = { continent = "Kul Tiras" },
    ["Drustvar"] = { continent = "Kul Tiras" },
    ["Stormsong Valley"] = { continent = "Kul Tiras" },
}

-- Refactored HandleZoneSelection function
function HandleZoneSelection(continentName, zoneName)
    -- Clear all waypoints to start fresh
    TomTom:ClearAllWaypoints()

    -- Clear any existing proxy waypoint
    if currentProxy then
        TomTom:RemoveWaypoint(currentProxy)
        currentProxy = nil
    end

    -- Get the current map ID and parent map ID
    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = C_Map.GetMapInfo(mapID)
    local parentMapInfo = mapInfo and C_Map.GetMapInfo(mapInfo.parentMapID)
    local currentContinent = parentMapInfo and parentMapInfo.name or "Unknown"

    -- Access zone-specific overrides from Localization
    local locale = GetLocale() or "enUS" -- Use "enUS" as fallback
    local zoneOverrides = Localization[locale] and Localization[locale]["ZoneOverrides"]

    if not zoneOverrides then
        print("|cFFFF0000Error: ZoneOverrides not found in Localization for locale: " .. locale .. "|r")
        return
    end

    local zoneOverride = zoneOverrides[GetZoneText()]
    if zoneOverride then
        --Debug print("|cFFFFA500Applying override: " .. GetZoneText() .. " -> Continent: " .. (zoneOverride.continent or "nil") .. ", Zone: " .. (zoneOverride.zone or "nil") .. "|r")
        currentContinent = zoneOverride.continent or currentContinent
        zoneName = zoneOverride.zone or zoneName
    else
        --Debug print("|cFFFF0000No override found for: " .. GetZoneText() .. "|r")
    end

    -- Check if the current continent matches the selected continent
    if currentContinent ~= continentName then
        print("|cFF00FF00You are currently on " .. currentContinent .. ". Please go to " .. continentName .. " and try again.|r")
        return
    end

    -- Handle zone selection
    local newZone = GetZoneText()
    if newZone == zoneName then
        AddWaypointsForZone(continentName, zoneName)
    else
        local proxyUid = AddProxyWaypoint(continentName, zoneName)
        queuedZone = zoneName
        selectedContinent = continentName
        currentProxy = proxyUid
    end
end

-- Function to add a proxy waypoint on the world map near the zone
function AddProxyWaypoint(continentName, zoneName)
    -- Ensure WaypointData is used consistently
    local continentInfo = WaypointData[continentName]
    if not continentInfo then
        print("|cFFFF0000Continent not found in WaypointData: " .. (continentName or "unknown") .. "|r")
        return
    end

    local zoneInfo = continentInfo[zoneName]
    if not zoneInfo then
        print("|cFFFF0000Zone not found in WaypointData: " .. (zoneName or "unknown") .. " for continent: " .. continentName .. "|r")
        return
    end

    local proxyLocation = zoneInfo.proxyLocation
    if not proxyLocation then
        print("|cFFFF0000Proxy location not defined for zone: " .. zoneName .. "|r")
        return
    end

    local continentMapID = GetContinentMapID(continentName)
    if not continentMapID then
        print("|cFFFF0000Continent Map ID not found for: " .. continentName .. "|r")
        return
    end

    -- Clear existing proxy waypoint if present
    if currentProxy and activeWaypoints[zoneName] then
        TomTom:RemoveWaypoint(currentProxy)
        activeWaypoints[zoneName] = nil
        currentProxy = nil
    end

    -- Add the proxy waypoint
    local x, y, desc = unpack(proxyLocation)
    x = tonumber(x) / 100 -- Convert to decimal
    y = tonumber(y) / 100 -- Convert to decimal

    if x and y then
        local uid = TomTom:AddWaypoint(continentMapID, x, y, { title = "Head to " .. zoneName })
        if uid then
            activeWaypoints[zoneName] = uid
            currentProxy = uid
            print("|cFF00FF00Proxy waypoint added for zone: " .. zoneName .. " at (" .. x * 100 .. ", " .. y * 100 .. ").|r")
            return uid
        else
            print("|cFFFF0000Failed to add proxy waypoint for zone: " .. zoneName .. "|r")
        end
    else
        print("|cFFFF0000Invalid proxy location for zone: " .. zoneName .. "|r")
    end
end

local removeWaypointsTimer = nil

function OnZoneChange(event)
    local newZone = GetZoneText()

    -- Debug message to confirm zone detection
    --print("|cFFFFA500Entering zone: " .. newZone .. "|r")

    -- If the new zone matches the queued zone, add waypoints
    if queuedZone and queuedZone == newZone then
        local waypointsAdded = AddWaypointsForZone(selectedContinent, newZone)
        queuedZone = nil

        -- Remove proxy waypoint if it exists
        if currentProxy then
            TomTom:RemoveWaypoint(currentProxy)
            currentProxy = nil
        end

        if waypointsAdded then
            TomTom:SetClosestWaypoint(true)
        end
    else
        --print("|cFFFF0000No matching zone found for waypoints.|r")
    end

    currentZone = newZone
end

-- Function to remove only zone waypoints
function RemoveZoneWaypoints()
    for desc, uid in pairs(activeWaypoints) do
        if desc ~= "proxy" then  -- Keep the proxy waypoint
            TomTom:RemoveWaypoint(uid)
            activeWaypoints[desc] = nil
        end
    end
end

-- Event Registration for Login Delay
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(2, function()
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("ZONE_CHANGED")
        frame:RegisterEvent("ZONE_CHANGED_INDOORS")
        frame:RegisterEvent("CRITERIA_UPDATE")
        frame:SetScript("OnEvent", OnZoneChange)

        -- Set initial current zone
        currentZone = GetZoneText()
    end)
end)