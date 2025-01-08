-- ExploreWithTomTom.lua

--------------------------
-- IMPORT & INITIALIZATION
--------------------------

-- Function to load waypoint data based on the user's locale
function LoadWaypointData()
    local locale = GetLocale() -- Retrieves the user's locale (e.g., "enUS", "frFR")

    if Localization and Localization[locale] then
        return Localization[locale] -- Returns localization data for the current locale
    else
        print("|cFFFF0000Localization for " .. locale .. " not found. Falling back to enUS.|r")
        return Localization["enUS"] -- Fallback to English localization
    end
end

-- Load the waypoint data into the global WaypointData table
WaypointData = LoadWaypointData()

-- Initialize variables to manage waypoints and zone states
local activeWaypoints = {} -- Table to keep track of active waypoints
local queuedZone = nil      -- Zone queued for waypoint addition
local currentZone = nil     -- Currently active zone
local currentProxy = nil    -- Current proxy waypoint UID

--------------------------
-- UTILITY FUNCTIONS FOR ZONE DISCOVERY AND WAYPOINT REMOVAL
--------------------------

-- Function to check if a specific zone has been discovered/completed
function IsZoneDiscovered(achievementID, zoneName)
    -- Special handling for Isle of Quel'Danas (achievementID 868)
    if achievementID == 868 then
        -- Check if the achievement is completed account-wide
        local _, _, achievementCompleted = GetAchievementInfo(achievementID)
        if achievementCompleted then
            return true
        end
        
        -- If not completed, check if the current character has explored the zone
        local isleQuelDanasMapID = 122  -- Map ID for Isle of Quel'Danas
        local exploredMapTextures = C_MapExplorationInfo.GetExploredMapTextures(isleQuelDanasMapID)
        return exploredMapTextures ~= nil and #exploredMapTextures > 0
    end

    -- General logic for other zones based on achievement criteria
    local numCriteria = GetAchievementNumCriteria(achievementID)
    local trimmedZoneName = strtrim(zoneName):lower()

    for i = 1, numCriteria do
        local criteriaString, _, completed = GetAchievementCriteriaInfo(achievementID, i)
        if strtrim(criteriaString):lower() == trimmedZoneName then
            return completed
        end
    end

    -- Fallback: Check if the entire achievement is completed
    local _, _, achievementCompleted = GetAchievementInfo(achievementID)
    return achievementCompleted
end

-- Function to remove all active waypoints
function RemoveAllWaypoints()
    for desc, uid in pairs(activeWaypoints) do
        TomTom:RemoveWaypoint(uid)
    end
    activeWaypoints = {}  -- Reset the active waypoints table
end

-- Function to remove only zone-specific waypoints, keeping proxy waypoints intact
function RemoveZoneWaypoints()
    for desc, uid in pairs(activeWaypoints) do
        if desc ~= "proxy" then  -- Exclude proxy waypoints
            TomTom:RemoveWaypoint(uid)
            activeWaypoints[desc] = nil
        end
    end
end

--------------------------
-- WAYPOINT MANAGEMENT
--------------------------

-- Function to add waypoints for a specific continent and zone
function AddWaypointsForZone(continentName, zoneName)
    -- Clear existing waypoints to prevent duplication
    RemoveAllWaypoints()

    -- Retrieve waypoint data for the specified continent
    local continentInfo = WaypointData[continentName]
    if not continentInfo then
        --print("|cFFFF0000Continent not found: " .. (continentName or "unknown") .. "|r")
        return false
    end

    -- Retrieve waypoint data for the specified zone within the continent
    local zoneInfo = continentInfo[zoneName]
    if not zoneInfo then
        --print("|cFFFF0000Zone not found: " .. (zoneName or "unknown") .. "|r")
        return false
    end

    -- Get the player's current map ID to place waypoints correctly
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        --print("|cFFFF0000Failed to retrieve player's current map ID.|r")
        return false
    end

    local waypointsAdded = false -- Flag to track if any waypoints were added

    -- Iterate through all waypoints defined for the zone
    for _, waypoint in ipairs(zoneInfo.waypoints) do
        local x, y, description = unpack(waypoint)
        local normalizedX = tonumber(x) / 100 -- Normalize X coordinate
        local normalizedY = tonumber(y) / 100 -- Normalize Y coordinate

        -- Skip waypoints that have already been discovered
        if not IsZoneDiscovered(zoneInfo.achievementID, description) then
            local uid = TomTom:AddWaypoint(mapID, normalizedX, normalizedY, {
                title = description,
                from = "Explore with TomTom", -- Add custom "From" field
                callbacks = TomTom:DefaultCallbacks({}),
            })
            if uid then
                activeWaypoints[description] = uid
                waypointsAdded = true

                -- Continuously monitor the discovery status of the waypoint
                local ticker = C_Timer.NewTicker(0.1, function(self)
                    if IsZoneDiscovered(zoneInfo.achievementID, description) then
                        -- Remove the waypoint once it's discovered
                        TomTom:RemoveWaypoint(uid)
                        activeWaypoints[description] = nil
                        self:Cancel() -- Stop the ticker
                    end
                end)
            end
        end
    end

    if waypointsAdded then
        currentZone = zoneName -- Update the current zone tracker
        return true
    else
        print("|cFFFF0000No undiscovered waypoints found for zone: " .. zoneName .. "|r")
        return false
    end
end

-- Function to add a proxy waypoint near the target zone on the world map
function AddProxyWaypoint(continentName, zoneName)
    -- Ensure waypoint data exists for the specified continent
    local continentInfo = WaypointData[continentName]
    if not continentInfo then
        --print("|cFFFF0000Continent not found in WaypointData: " .. (continentName or "unknown") .. "|r")
        return
    end

    -- Ensure waypoint data exists for the specified zone within the continent
    local zoneInfo = continentInfo[zoneName]
    if not zoneInfo then
        --print("|cFFFF0000Zone not found in WaypointData: " .. (zoneName or "unknown") .. " for continent: " .. continentName .. "|r")
        return
    end

    -- Retrieve the proxy location data for the zone
    local proxyLocation = zoneInfo.proxyLocation
    if not proxyLocation then
        --print("|cFFFF0000Proxy location not defined for zone: " .. zoneName .. "|r")
        return
    end

    -- Get the map ID for the continent to place the proxy waypoint
    local continentMapID = GetContinentMapID(continentName)
    if not continentMapID then
        --print("|cFFFF0000Continent Map ID not found for: " .. continentName .. "|r")
        return
    end

    -- Remove existing proxy waypoint if present to avoid duplicates
    if currentProxy and activeWaypoints[zoneName] then
        TomTom:RemoveWaypoint(currentProxy)
        activeWaypoints[zoneName] = nil
        currentProxy = nil
    end

    -- Extract and normalize proxy location coordinates
    local x, y, desc = unpack(proxyLocation)
    x = tonumber(x) / 100 -- Normalize X coordinate
    y = tonumber(y) / 100 -- Normalize Y coordinate

    if x and y then
        -- Add the proxy waypoint using TomTom's API
        local uid = TomTom:AddWaypoint(continentMapID, x, y, {
            title = "Head to " .. zoneName,
            from = "Explore with TomTom", -- Add custom "From" field
        })
        if uid then
            activeWaypoints[zoneName] = uid
            currentProxy = uid
            print("|cFF00FF00Proxy waypoint added for zone: " .. zoneName .. " at (" .. x * 100 .. ", " .. y * 100 .. ").|r")
            return uid
        else
            --print("|cFFFF0000Failed to add proxy waypoint for zone: " .. zoneName .. "|r")
        end
    else
        --print("|cFFFF0000Invalid proxy location for zone: " .. zoneName .. "|r")
    end
end

--------------------------
-- MAP ID & LOCALIZATION
--------------------------

-- Function to retrieve the map ID for a given continent name, supporting multiple locales
function GetContinentMapID(continentName)
    local continentMapIDs = {
        -- English (EN)
        ["Eastern Kingdoms"] = 13,
        ["Outland"] = 101,
        ["Draenor"] = 572,
        ["Kul Tiras"] = 876,
        ["Zandalar"] = 875,
        ["Kalimdor"] = 12,
        ["Northrend"] = 113,
        ["Pandaria"] = 424,
        ["Broken Isles"] = 619,
        ["The Maelstrom"] = 207,
    
        -- French (FR)
        ["Royaumes de l’Est"] = 13,
        ["Outreterre"] = 101,
        ["Draenor"] = 572,
        ["Kul Tiras"] = 876,
        ["Zandalar"] = 875,
        ["Kalimdor"] = 12,
        ["Norfendre"] = 113,
        ["Pandarie"] = 424,
        ["Îles Brisées"] = 619,
        ["Le Maelström"] = 207,
    
        -- Russian (RU)
        ["Восточные королевства"] = 13,
        ["Запределье"] = 101,
        ["Дренор"] = 572,
        ["Кул-Тирас"] = 876,
        ["Зандалар"] = 875,
        ["Калимдор"] = 12,
        ["Нордскол"] = 113,
        ["Пандария"] = 424,
        ["Расколотые острова"] = 619,
        ["Водоворот"] = 207,
    
        -- German (DE)
        ["Die Östlichen Königreiche"] = 13,
        ["Scherbenwelt"] = 101,
        ["Draenor"] = 572,
        ["Kul Tiras"] = 876,
        ["Zandalar"] = 875,
        ["Kalimdor"] = 12,
        ["Nordends"] = 113,
        ["Pandaria"] = 424,
        ["Verheerten Inseln"] = 619,
        ["Der Mahlstrom"] = 207,
    
        -- Spanish (ES-EU)
        ["Reinos del Este"] = 13,
        ["Terrallende"] = 101,
        ["Draenor"] = 572,
        ["Kul Tiras"] = 876,
        ["Zandalar"] = 875,
        ["Kalimdor"] = 12,
        ["Rasganorte"] = 113,
        ["Pandaria"] = 424,
        ["Islas Quebradas"] = 619,
        ["La Vorágine"] = 207,
    
        -- Italian (IT)
        ["Regni Orientali"] = 13,
        ["Terre Esterne"] = 101,
        ["Draenor"] = 572,
        ["Kul Tiras"] = 876,
        ["Zandalar"] = 875,
        ["Kalimdor"] = 12,
        ["Nordania"] = 113,
        ["Pandaria"] = 424,
        ["Isole Disperse"] = 619,
        ["Il Maelstrom"] = 207,
    
        -- Portuguese (PT)
        ["Reinos do Leste"] = 13,
        ["Terralém"] = 101,
        ["Draenor"] = 572,
        ["Kul Tiras"] = 876,
        ["Zandalar"] = 875,
        ["Kalimdor"] = 12,
        ["Nortúndria"] = 113,
        ["Pandária"] = 424,
        ["Ilhas Partidas"] = 619,
        ["O Maelstrom"] = 207,
    
        -- Korean (KO)
        ["동부 왕국"] = 13,
        ["아웃랜드"] = 101,
        ["드레노어"] = 572,
        ["쿨 티라스"] = 876,
        ["잔달라"] = 875,
        ["칼림도어"] = 12,
        ["노스렌드"] = 113,
        ["판다리아"] = 424,
        ["부서진 섬"] = 619,
        ["소용돌이"] = 207,
    
        -- Simplified Chinese (ZH-CN)
        ["东部王国"] = 13,
        ["外域"] = 101,
        ["德拉诺"] = 572,
        ["库尔提拉斯"] = 876,
        ["赞达拉"] = 875,
        ["卡利姆多"] = 12,
        ["诺森德"] = 113,
        ["潘达利亚"] = 424,
        ["破碎群岛"] = 619,
        ["大漩涡"] = 207,
    }
    
    local mapID = continentMapIDs[continentName]
    return mapID
end

-- Function to localize continent names based on the user's locale
function LocalizeContinent(continentKey)
    local locale = GetLocale()
    if Localization 
       and Localization[locale] 
       and Localization[locale]["Continents"]
       and Localization[locale]["Continents"][continentKey] then

        return Localization[locale]["Continents"][continentKey]
    end
    -- Fallback to the original continent key if no translation is available
    return continentKey
end

--------------------------
-- ZONE SELECTION HANDLER
--------------------------

-- Function to handle zone selection and manage waypoints accordingly
function HandleZoneSelection(continentName, zoneName)
    -- Clear all existing waypoints to start fresh
    TomTom:ClearAllWaypoints()

    -- Remove any existing proxy waypoint
    if currentProxy then
        TomTom:RemoveWaypoint(currentProxy)
        currentProxy = nil
    end

    -- Retrieve the player's current map information
    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = C_Map.GetMapInfo(mapID)
    local parentMapInfo = mapInfo and C_Map.GetMapInfo(mapInfo.parentMapID)
    local currentContinent = parentMapInfo and parentMapInfo.name or "Unknown"

    -- Access zone-specific overrides from localization data
    local locale = GetLocale() or "enUS" -- Default to "enUS" if locale is unavailable
    local zoneOverrides = Localization[locale] and Localization[locale]["ZoneOverrides"]

    if not zoneOverrides then
        --print("|cFFFF0000Error: ZoneOverrides not found in Localization for locale: " .. locale .. "|r")
        return
    end

    -- Check if the current zone has any overrides
    local zoneOverride = zoneOverrides[GetZoneText()]
    if zoneOverride then
        -- Apply overrides to continent and zone names if available
        currentContinent = zoneOverride.continent or currentContinent
        zoneName = zoneOverride.zone or zoneName
    end

    -- Verify if the player is on the correct continent
    if currentContinent ~= continentName then
        print("|cFF00FF00You are currently on " .. currentContinent .. ". Please go to " .. continentName .. " and try again.|r")
        return
    end

    -- Determine if the player is already in the target zone
    local newZone = GetZoneText()
    if newZone == zoneName then
        -- If in the target zone, add waypoints directly
        AddWaypointsForZone(continentName, zoneName)
    else
        -- If not, add a proxy waypoint and queue the zone for later
        local proxyUid = AddProxyWaypoint(continentName, zoneName)
        queuedZone = zoneName
        selectedContinent = continentName
        currentProxy = proxyUid
    end
end

--------------------------
-- EVENT HANDLING
--------------------------

-- Function to handle zone change events and update waypoints if necessary
function OnZoneChange(event)
    local newZone = GetZoneText()

    -- Uncomment the next line for debugging zone changes
    -- print("|cFFFFA500Entering zone: " .. newZone .. "|r")

    -- Check if the new zone matches the queued zone for waypoint addition
    if queuedZone and queuedZone == newZone then
        local waypointsAdded = AddWaypointsForZone(selectedContinent, newZone)
        queuedZone = nil

        -- Remove the proxy waypoint once waypoints are added
        if currentProxy then
            TomTom:RemoveWaypoint(currentProxy)
            currentProxy = nil
        end

        -- Optionally, set the closest waypoint as the current target
        if waypointsAdded then
            TomTom:SetClosestWaypoint(true)
        end
    end

    -- Update the current zone tracker
    currentZone = newZone
end

-- Event frame to handle player login and subsequent zone change events
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    -- Delay event registration by 2 seconds to ensure all data is loaded
    C_Timer.After(2, function()
        local frame = CreateFrame("Frame")
        -- Register events related to zone changes and achievement updates
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("ZONE_CHANGED")
        frame:RegisterEvent("ZONE_CHANGED_INDOORS")
        frame:RegisterEvent("CRITERIA_UPDATE")
        frame:SetScript("OnEvent", OnZoneChange)

        -- Initialize the current zone tracker
        currentZone = GetZoneText()
    end)
end)