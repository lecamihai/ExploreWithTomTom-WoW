-- Import localization
local localize = Localize

-- Create a new frame with a thin white border and black background
local exploreFrame = CreateFrame("Frame", "ExploreWithTomTomFrame", UIParent, "ThinBorderTemplate")
exploreFrame:SetSize(600, 450)  -- Set size of the frame
exploreFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Center the frame
exploreFrame:SetMovable(true)  -- Make the frame movable
exploreFrame:EnableMouse(true)
exploreFrame:RegisterForDrag("LeftButton")
exploreFrame:SetScript("OnDragStart", exploreFrame.StartMoving)
exploreFrame:SetScript("OnDragStop", exploreFrame.StopMovingOrSizing)
exploreFrame:Hide()  -- Start hidden

-- Add black background
local backgroundTexture = exploreFrame:CreateTexture(nil, "BACKGROUND")
backgroundTexture:SetAllPoints(exploreFrame)
backgroundTexture:SetColorTexture(0, 0, 0, 0.8)

-- Title text for the new frame
exploreFrame.title = exploreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
exploreFrame.title:SetPoint("TOP", exploreFrame, "TOP", 0, -10)
exploreFrame.title:SetText("Explore with TomTom")

-- Close button for the new frame
local closeButton = CreateFrame("Button", nil, exploreFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", exploreFrame, "TOPRIGHT", -5, -5)

-- UI Elements for Continent and Zone Selection
local continentDropdown, zoneDropdown
local selectedContinent, selectedZone

-- Dynamic Header
local headerContainer = CreateFrame("Frame", nil, exploreFrame)
headerContainer:SetSize(410, 100)
headerContainer:SetPoint("TOP", -50, -50)

local headerText = headerContainer:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
headerText:SetPoint("TOP", headerContainer, "TOP", 100, 15)
headerText:SetText(localize("SELECT_A_ZONE"))

-- Continent Dropdown
local continentLabel = exploreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
continentLabel:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 5, 0)
continentLabel:SetText(localize("SELECT_CONTINENT"))

continentDropdown = CreateFrame("Frame", "WaypointContinentDropdown", headerContainer, "UIDropDownMenuTemplate")
continentDropdown:SetPoint("TOPLEFT", continentLabel, "BOTTOMLEFT", -16, -8)
UIDropDownMenu_SetWidth(continentDropdown, 150)

UIDropDownMenu_Initialize(continentDropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for continent in pairs(WaypointData) do
        info.text = continent
        info.checked = (continent == selectedContinent)
        info.func = function()
            selectedContinent = continent
            selectedZone = nil  -- Reset selected zone
            UIDropDownMenu_SetText(continentDropdown, continent)
            UIDropDownMenu_SetText(zoneDropdown, localize("SELECT_ZONE"))
            UpdateZoneStatusContainer(continent)
            headerText:SetText(continent)
            ScheduleNextUpdate()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

-- Zone Dropdown
local zoneLabel = exploreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
zoneLabel:SetPoint("TOPLEFT", continentDropdown, "BOTTOMLEFT", 16, -20)
zoneLabel:SetText(localize("SELECT_ZONE"))

zoneDropdown = CreateFrame("Frame", "WaypointZoneDropdown", headerContainer, "UIDropDownMenuTemplate")
zoneDropdown:SetPoint("TOPLEFT", zoneLabel, "BOTTOMLEFT", -16, -8)
UIDropDownMenu_SetWidth(zoneDropdown, 150)

UIDropDownMenu_Initialize(zoneDropdown, function(self, level)
    if not selectedContinent then return end
    local info = UIDropDownMenu_CreateInfo()
    
    -- Create a table for the zone names
    local zones = {}
    for zone in pairs(WaypointData[selectedContinent]) do
        table.insert(zones, zone)
    end

    -- Sort the zones alphabetically
    table.sort(zones)

    -- Add sorted zones to the dropdown
    for _, zone in ipairs(zones) do
        info.text = zone
        info.checked = (zone == selectedZone)
        info.func = function()
            selectedZone = zone
            UIDropDownMenu_SetText(zoneDropdown, zone)
            UpdateZoneStatusContainer(selectedContinent, zone)
            headerText:SetText(zone)
            ScheduleNextUpdate()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

-- Add Waypoints Button
local addButton = CreateFrame("Button", nil, exploreFrame, "UIPanelButtonTemplate")
addButton:SetPoint("TOPLEFT", zoneDropdown, "BOTTOMLEFT", 25, -20)
addButton:SetSize(140, 22)
addButton:SetText(localize("ADD_WAYPOINTS"))
addButton:SetScript("OnClick", function()
    if selectedContinent and selectedZone then
        HandleZoneSelection(selectedContinent, selectedZone)
    else
        print(localize("SELECT_CONTINENT_AND_ZONE"))
    end
end)

-- Scroll Frame for Zone Status with a thin border around it
local scrollFrameContainer = CreateFrame("Frame", nil, exploreFrame, "ThinBorderTemplate")
scrollFrameContainer:SetSize(290, 280)
scrollFrameContainer:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 200, 150)

local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, 0)
scrollFrame:SetSize(290, 280)

local scrollChild = CreateFrame("Frame")
scrollChild:SetSize(290, 250)
scrollFrame:SetScrollChild(scrollChild)

local fontStringPool = {}  -- Initialize the font string pool as an empty table

-- Add this near the top of the file
local updateTimer = nil

-- Modify the UpdateZoneStatusContainer function
function UpdateZoneStatusContainer(continent, zone)
    -- Store the current scroll position
    local currentScroll = scrollFrame:GetVerticalScroll()

    -- Remove old scrollChild and create a new one
    if scrollChild then
        scrollChild:Hide()
        scrollChild:SetHeight(1)  -- Reset height
    end

    scrollChild:SetSize(350, 1)  -- Reset size; width matches scrollFrame

    -- Clear previous font strings
    for _, fontString in ipairs(fontStringPool) do
        fontString:Hide()
    end

    -- Create a table to store zones/waypoints with their completion status
    local zoneStatus = {}
    
    if zone then
        -- If a zone is selected, show the waypoints within that zone
        local waypoints = WaypointData[continent][zone].waypoints
        for i, waypoint in ipairs(waypoints) do
            local pointName = waypoint[3]  -- Retrieving the name of the waypoint
            local numTotal = 1
            local numCompleted = IsZoneDiscovered(WaypointData[continent][zone].achievementID, pointName) and 1 or 0
            
            table.insert(zoneStatus, {zoneName = pointName, numCompleted = numCompleted, numTotal = numTotal})
        end

        -- Sort alphabetically by zoneName (waypoints)
        table.sort(zoneStatus, function(a, b)
            return a.zoneName:lower() < b.zoneName:lower()
        end)
    else
        -- If only a continent is selected, show the zones within that continent
        for zoneName, zoneInfo in pairs(WaypointData[continent]) do
            local numTotal = #zoneInfo.waypoints
            local numCompleted = 0
            
            for _, waypoint in ipairs(zoneInfo.waypoints) do
                if IsZoneDiscovered(zoneInfo.achievementID, waypoint[3]) then
                    numCompleted = numCompleted + 1
                end
            end

            table.insert(zoneStatus, {zoneName = zoneName, numCompleted = numCompleted, numTotal = numTotal})
        end

        -- Sort alphabetically by zoneName (zones)
        table.sort(zoneStatus, function(a, b)
            return a.zoneName:lower() < b.zoneName:lower()
        end)
    end

    -- Add new content based on sorted data
    local yOffset = -10
    for i, zone in ipairs(zoneStatus) do
        -- Determine the color (green for completed, yellow for not completed)
        local color = (zone.numCompleted == zone.numTotal) and "|cFF00FF00" or "|cFFFFFF00"

        -- Reuse or create a new FontString
        local zoneStatusText = fontStringPool[i]
        if not zoneStatusText then
            zoneStatusText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            fontStringPool[i] = zoneStatusText
        end
        
        zoneStatusText:SetPoint("TOPLEFT", 16, yOffset)
        zoneStatusText:SetText(color .. string.format("%s: %d/%d", zone.zoneName, zone.numCompleted, zone.numTotal) .. "|r")
        zoneStatusText:Show()

        yOffset = yOffset - 20
        scrollChild:SetHeight(scrollChild:GetHeight() + 20)
    end

    scrollChild:SetHeight(math.abs(yOffset) + 10)  -- Adjust scroll child height to fit content
    scrollChild:Show()

    -- Restore the previous scroll position
    C_Timer.After(0, function()
        scrollFrame:SetVerticalScroll(currentScroll)
    end)

    -- After updating the content, schedule the next update
    ScheduleNextUpdate()
end

-- Add this new function
function ScheduleNextUpdate()
    if updateTimer then
        updateTimer:Cancel()
    end
    updateTimer = C_Timer.NewTimer(2, function()
        if exploreFrame:IsVisible() then
            if selectedContinent and selectedZone then
                UpdateZoneStatusContainer(selectedContinent, selectedZone)
            elseif selectedContinent then
                UpdateZoneStatusContainer(selectedContinent)
            end
            UpdateContinentStatus()
        end
    end)
end

-- Container for Continent Status at the bottom of the frame with expanded layout
local continentStatusContainer = CreateFrame("Frame", nil, exploreFrame, "ThinBorderTemplate")
continentStatusContainer:SetSize(560, 80)  -- Increased height to accommodate three rows
continentStatusContainer:SetPoint("BOTTOM", exploreFrame, "BOTTOM", 0, 10)

local function CreateContinentStatusTexts(parent)
    local texts = {}
    local positions = {
        {10, -10},    -- Outland
        {150, -10},   -- Pandaria
        {270, -10},   -- Northrend
        {390, -10},   -- Kalimdor
        {10, -35},    -- Draenor
        {150, -35},   -- Zandalar
        {270, -35},   -- Kul Tiras
        {430, -35},   -- Shadowlands
        {10, -60},    -- The Maelstrom
        {150, -60},   -- Dragon Isles
        {270, -60},   -- Broken Isles
        {390, -60},   -- Eastern Kingdoms
        {150, -60},   -- Vashj'ir
    }

    for i = 1, 13 do
        texts[i] = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        texts[i]:SetPoint("TOPLEFT", parent, "TOPLEFT", positions[i][1], positions[i][2])
    end

    return texts
end

local continentStatusTexts = CreateContinentStatusTexts(continentStatusContainer)

function UpdateContinentStatus()
    local continentOrder = {
        localize("CONTINENT_OUTLAND"), localize("CONTINENT_PANDARIA"), localize("CONTINENT_NORTHREND"), localize("CONTINENT_KALIMDOR"), localize("CONTINENT_DRAENOR"),
        localize("CONTINENT_ZANDALAR"), localize("CONTINENT_KUL_TIRAS"), localize("CONTINENT_SHADOWLANDS"), localize("CONTINENT_MAELSTROM"),
        localize("CONTINENT_DRAGON_ISLES"), localize("CONTINENT_BROKEN_ISLES"), localize("CONTINENT_EASTERN_KINGDOMS"), localize("CONTINENT_VASHJIR")
    }

    for index, continent in ipairs(continentOrder) do
        local zones = WaypointData[continent]
        if zones then
            local totalZones = 0
            local completedZones = 0
            
            for zoneName, zoneInfo in pairs(zones) do
                totalZones = totalZones + 1
                local numCompleted = 0
                
                for _, waypoint in ipairs(zoneInfo.waypoints) do
                    if IsZoneDiscovered(zoneInfo.achievementID, waypoint[3]) then
                        numCompleted = numCompleted + 1
                    end
                end
                
                if numCompleted == #zoneInfo.waypoints then
                    completedZones = completedZones + 1
                end
            end
            
            local color = (completedZones == totalZones) and "|cFF00FF00" or "|cFFFFFF00"
            continentStatusTexts[index]:SetText(color .. string.format("%s: %d/%d", continent, completedZones, totalZones) .. "|r")
            continentStatusTexts[index]:Show()
        else
            continentStatusTexts[index]:Hide()
        end
    end
end

-- Modify the SLASH_EXPLOREWITHTOMTOM1 function
SLASH_EXPLOREWITHTOMTOM1 = "/ewtt"
SlashCmdList["EXPLOREWITHTOMTOM"] = function(msg)
    UpdateContinentStatus()  -- Update the continent status when the frame is shown
    exploreFrame:Show()
    ScheduleNextUpdate()  -- Start the update cycle
end

-- Add this new function to stop updates when the frame is closed
local function OnFrameHide()
    if updateTimer then
        updateTimer:Cancel()
        updateTimer = nil
    end
end

-- Set the OnHide script so that updates stop when the frame is closed
exploreFrame:SetScript("OnHide", OnFrameHide)
