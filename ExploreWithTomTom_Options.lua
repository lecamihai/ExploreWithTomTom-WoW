-- ExploreWithTomTom_Options.lua

-- Create a new frame with a thin white border and black background
local exploreFrame = CreateFrame("Frame", "ExploreWithTomTomFrame", UIParent, "ThinBorderTemplate")
exploreFrame:SetSize(600, 480)  -- Set size of the frame
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
headerText:SetText("Select a Zone")

-- Continent Dropdown
local continentLabel = exploreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
continentLabel:SetPoint("TOPLEFT", headerContainer, "TOPLEFT", 5, 0)
continentLabel:SetText("Select Continent")

continentDropdown = CreateFrame("Frame", "WaypointContinentDropdown", headerContainer, "UIDropDownMenuTemplate")
continentDropdown:SetPoint("TOPLEFT", continentLabel, "BOTTOMLEFT", -16, -8)
UIDropDownMenu_SetWidth(continentDropdown, 150)

UIDropDownMenu_Initialize(continentDropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for continent in pairs(WaypointData) do
        -- Only process valid continents (keys that aren’t "Continents" or any other special key)
        if continent ~= "Continents" then
            info.text = continent
            info.checked = (continent == selectedContinent)
            info.func = function()
                selectedContinent = continent
                selectedZone = nil
                UIDropDownMenu_SetText(continentDropdown, continent)
                UIDropDownMenu_SetText(zoneDropdown, "Select Zone")
                UpdateZoneStatusContainer(continent)
                headerText:SetText(continent)
                ScheduleNextUpdate()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
end)

local continentOrder = {
    "Eastern Kingdoms", "Outland", "Cataclysm",
    "Draenor", "Battle for Azeroth", "Kalimdor",
    "Northrend", "Pandaria", "Broken Isles"
}


-- Zone Dropdown
local zoneLabel = exploreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
zoneLabel:SetPoint("TOPLEFT", continentDropdown, "BOTTOMLEFT", 16, -20)
zoneLabel:SetText("Select Zone")

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
addButton:SetText("Add Waypoints")
addButton:SetScript("OnClick", function()
    if selectedContinent and selectedZone then
        HandleZoneSelection(selectedContinent, selectedZone)
    else
        print("Please select a continent and zone.")
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
    -- Reset scroll position
    scrollFrame:SetVerticalScroll(0)

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

    -- Ensure only the required number of FontStrings are visible
    for i = #zoneStatus + 1, #fontStringPool do
        fontStringPool[i]:Hide()
    end

    -- Adjust scroll child height to fit content
    scrollChild:SetHeight(math.abs(yOffset) + 10)
    scrollChild:Show()
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
continentStatusContainer:SetSize(580, 120)  -- Increased height to accommodate three rows
continentStatusContainer:SetPoint("BOTTOM", exploreFrame, "BOTTOM", 0, 10)

local function CreateContinentStatusTexts(parent, totalContinents)
    -- Ensure totalContinents is a valid number
    totalContinents = tonumber(totalContinents) or 0

    local texts = {}
    local numColumns = 3  -- Number of columns per row (adjust for better layout with 9 items)
    local containerPadding = 10  -- Padding inside the container
    local cellSpacing = 10  -- Spacing between cells
    local containerWidth = parent:GetWidth() - 2 * containerPadding
    local cellWidth = (containerWidth - (numColumns - 1) * cellSpacing) / numColumns
    local cellHeight = 25  -- Fixed height for each text element

    for i = 1, totalContinents do
        -- Calculate the current row and column based on the continent index
        local col = (i - 1) % numColumns  -- Current column (0-based)
        local row = math.floor((i - 1) / numColumns)  -- Current row (0-based)

        -- Create and position the text
        texts[i] = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        texts[i]:SetWidth(cellWidth)
        texts[i]:SetHeight(cellHeight)
        texts[i]:SetJustifyH("CENTER")  -- Center-align horizontally
        texts[i]:SetJustifyV("MIDDLE")  -- Center-align vertically
        texts[i]:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            containerPadding + col * (cellWidth + cellSpacing),
            -(containerPadding + row * (cellHeight + cellSpacing))
        )
    end

    return texts
end


local continentStatusTexts = CreateContinentStatusTexts(continentStatusContainer, #continentOrder)



for index, continent in ipairs(continentOrder) do
    local zones = WaypointData[continent]
    -- ...
    local color = ...
    continentStatusTexts[index]:SetText(
        color .. string.format("%s: %d/%d", continent, completedZones, totalZones) .. "|r"
    )
end


function UpdateContinentStatus()
    local continentOrder = {
        "Eastern Kingdoms", "Outland", "Cataclysm",
        "Draenor", "Battle for Azeroth", "Kalimdor",
        "Northrend", "Pandaria", "Broken Isles"
    }

    for index, englishContinentKey in ipairs(continentOrder) do
        -- 1) Get the localized name of the continent (for display and for indexing WaypointData).
        local localizedContinentKey = LocalizeContinent(englishContinentKey)
        
        -- 2) Lookup zone data using that localized key
        local zones = WaypointData[localizedContinentKey]
        
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
            continentStatusTexts[index]:SetText(
                color .. string.format("%s: %d/%d", localizedContinentKey, completedZones, totalZones) .. "|r"
            )
            continentStatusTexts[index]:Show()
        else
            -- Hide if we have no data for that continent (possibly not in that locale yet)
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
