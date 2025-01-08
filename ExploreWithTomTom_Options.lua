-- ExploreWithTomTom_Options.lua

-----------------------------
-- MAIN FRAME & BACKGROUND --
-----------------------------

-- Create a new frame with a thin white border and black background
local exploreFrame = CreateFrame("Frame", "ExploreWithTomTomFrame", UIParent, "ThinBorderTemplate")
exploreFrame:SetSize(600, 520)  -- Set size of the frame
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

---------------------------------
-- TITLE & CLOSE/REFRESH BUTTONS --
---------------------------------

-- Title text for the new frame
exploreFrame.title = exploreFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
exploreFrame.title:SetPoint("TOP", exploreFrame, "TOP", 0, -10)
exploreFrame.title:SetText("Explore with TomTom")

-- Close button (X) for the new frame
local closeButton = CreateFrame("Button", nil, exploreFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", exploreFrame, "TOPRIGHT", -5, -5)

--------------
-- VARIABLES --
--------------

local continentDropdown, zoneDropdown
local selectedContinent, selectedZone
local updateTimer = nil   -- We'll use this to schedule delayed updates
local fontStringPool = {} -- Reusable font strings for the scroll container

---------------------------------
-- DYNAMIC HEADER (TOP SECTION) --
---------------------------------

local headerContainer = CreateFrame("Frame", nil, exploreFrame)
headerContainer:SetSize(410, 100)
headerContainer:SetPoint("TOP", -50, -50)

local headerText = headerContainer:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
headerText:SetPoint("TOP", headerContainer, "TOP", 100, 15)
headerText:SetText("Select a Zone")

-------------------------
-- CONTINENT DROPDOWN  --
-------------------------

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
        if continent ~= "Continents" and continent ~= "ZoneOverrides" then
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

-------------------
-- CONTINENT ORDER --
-------------------

local continentOrder = {
    "Eastern Kingdoms", "Outland", "Draenor",
    "Kul Tiras", "Zandalar", "Northrend",
    "Pandaria", "Broken Isles", "Kalimdor",
    "The Maelstrom"
}

---------------------
-- ZONE DROPDOWN   --
---------------------

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

---------------------------------
-- BUTTONS BELOW ZONE DROPDOWN --
---------------------------------

-- Add Waypoints Button
local addButton = CreateFrame("Button", nil, exploreFrame, "UIPanelButtonTemplate")
addButton:SetPoint("TOPLEFT", zoneDropdown, "BOTTOMLEFT", 25, -20)
addButton:SetSize(140, 30)
addButton:SetText("Add Waypoints")
addButton:SetScript("OnClick", function()
    if selectedContinent and selectedZone then
        HandleZoneSelection(selectedContinent, selectedZone)
    else
        print("Please select a continent and zone.")
    end
end)

-- Select Closest Waypoint Button
local closestButton = CreateFrame("Button", nil, exploreFrame, "UIPanelButtonTemplate")
closestButton:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -10)  -- Position below "Add Waypoints"
closestButton:SetSize(140, 30)
closestButton:SetText("Closest Waypoint")
closestButton:SetScript("OnClick", function()
    if TomTom and TomTom.SetClosestWaypoint then
        TomTom:SetClosestWaypoint()
    else
        --print("TomTom not found or doesn't support SetClosestWaypoint.")
    end
end)

-- Remove Waypoints Button
local removeButton = CreateFrame("Button", nil, exploreFrame, "UIPanelButtonTemplate")
removeButton:SetPoint("TOPLEFT", closestButton, "BOTTOMLEFT", 0, -10)  -- Position below "Closest Waypoint"
removeButton:SetSize(140, 30)
removeButton:SetText("Remove Waypoints")
removeButton:SetScript("OnClick", function()
    RemoveAllWaypoints() -- Call your RemoveAllWaypoints function
end)

-------------------------------------------------------
-- SCROLL FRAME (RIGHT CONTAINER) FOR ZONE STATUS INFO --
-------------------------------------------------------

local scrollFrameContainer = CreateFrame("Frame", nil, exploreFrame, "ThinBorderTemplate")
scrollFrameContainer:SetSize(290, 280)
scrollFrameContainer:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 200, 150)

local scrollFrame = CreateFrame("ScrollFrame", nil, scrollFrameContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, 0)
scrollFrame:SetSize(290, 280)

local scrollChild = CreateFrame("Frame")
scrollChild:SetSize(290, 250)
scrollFrame:SetScrollChild(scrollChild)

-- "Loading..." text inside the right container (zone status container)
local loadingText = scrollFrameContainer:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
loadingText:SetPoint("CENTER", scrollFrameContainer, "CENTER")
loadingText:SetText("|cFF00FF00Loading...|r") -- Green-colored text
loadingText:Hide() -- Initially hidden


------------------------------------
-- REFRESH BUTTON (TOP RIGHT AREA) --
------------------------------------

local refreshButton = CreateFrame("Button", nil, exploreFrame, "UIPanelButtonTemplate")

-- Set the button size to match other buttons
refreshButton:SetSize(24, 24) -- Button size remains consistent with the close button
refreshButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)

-- Add the normal texture for the button
local normalTexture = refreshButton:CreateTexture(nil, "ARTWORK")
normalTexture:SetTexture("Interface\\Buttons\\UI-RefreshButton")
normalTexture:SetPoint("CENTER", refreshButton, "CENTER") -- Center the texture in the button
normalTexture:SetSize(16, 16) -- Make the texture smaller than the button
refreshButton:SetNormalTexture(normalTexture)

-- Add the highlight texture for the button
local highlightTexture = refreshButton:CreateTexture(nil, "HIGHLIGHT")
highlightTexture:SetTexture("Interface\\Buttons\\UI-RefreshButton")
highlightTexture:SetPoint("CENTER", refreshButton, "CENTER") -- Center the texture in the button
highlightTexture:SetSize(16, 16) -- Match the smaller texture size
refreshButton:SetHighlightTexture(highlightTexture)


-- When clicked, display the loading text and hide the continent text
refreshButton:SetScript("OnClick", function()
    -- Step 1: Show the "Loading..." text and hide the scroll content
    loadingText:Show()
    scrollChild:Hide() -- Immediately hide existing content
    
    -- Step 2: Perform the refresh process (delayed to simulate "Loading..." display)
    C_Timer.After(0.5, function()
        if selectedContinent and selectedZone then
            UpdateZoneStatusContainer(selectedContinent, selectedZone)
        elseif selectedContinent then
            UpdateZoneStatusContainer(selectedContinent)
        end
        UpdateContinentStatus()

        -- Step 3: Hide "Loading..." text and show the refreshed content
        loadingText:Hide()
        scrollChild:Show()
    end)
end)

-----------------------------------------------------
-- FUNCTION: UPDATE ZONE STATUS CONTAINER (RIGHT) --
-----------------------------------------------------

function UpdateZoneStatusContainer(continent, zone)
    -- Reset scroll position
    scrollFrame:SetVerticalScroll(0)

    -- Hide old scrollChild content and reset size
    scrollChild:Hide()
    scrollChild:SetHeight(1)
    scrollChild:SetSize(350, 1)  -- width matches scrollFrame

    -- Clear previous font strings
    for _, fontString in ipairs(fontStringPool) do
        fontString:Hide()
    end

    -- Build a table of zone or waypoint statuses
    local zoneStatus = {}
    if zone then
        -- Show waypoints in the selected zone
        local waypoints = WaypointData[continent][zone].waypoints
        for _, waypoint in ipairs(waypoints) do
            local pointName = waypoint[3]  -- name of the waypoint
            local numTotal = 1
            local numCompleted = IsZoneDiscovered(
                WaypointData[continent][zone].achievementID,
                pointName
            ) and 1 or 0
            
            table.insert(zoneStatus, {
                zoneName = pointName,
                numCompleted = numCompleted,
                numTotal = numTotal
            })
        end

        -- Sort by the waypoint name
        table.sort(zoneStatus, function(a, b)
            return a.zoneName:lower() < b.zoneName:lower()
        end)
    else
        -- Show zones within the selected continent
        for zoneName, zoneInfo in pairs(WaypointData[continent]) do
            local numTotal = #zoneInfo.waypoints
            local numCompleted = 0
            
            for _, waypoint in ipairs(zoneInfo.waypoints) do
                if IsZoneDiscovered(zoneInfo.achievementID, waypoint[3]) then
                    numCompleted = numCompleted + 1
                end
            end

            table.insert(zoneStatus, {
                zoneName = zoneName,
                numCompleted = numCompleted,
                numTotal = numTotal
            })
        end

        -- Sort by the zone name
        table.sort(zoneStatus, function(a, b)
            return a.zoneName:lower() < b.zoneName:lower()
        end)
    end

    -- Display each zone/waypoint in the scroll container
    local yOffset = -10
    for i, entry in ipairs(zoneStatus) do
        -- Completed in green, incomplete in yellow
        local color = (entry.numCompleted == entry.numTotal) and "|cFF00FF00" or "|cFFFFFF00"

        -- Reuse or create a new FontString from the pool
        local zoneStatusText = fontStringPool[i]
        if not zoneStatusText then
            zoneStatusText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            fontStringPool[i] = zoneStatusText
        end
        
        zoneStatusText:SetPoint("TOPLEFT", 16, yOffset)
        zoneStatusText:SetText(color .. string.format("%s: %d/%d", 
            entry.zoneName, entry.numCompleted, entry.numTotal) .. "|r")
        zoneStatusText:Show()

        -- Move the offset down
        yOffset = yOffset - 20
        scrollChild:SetHeight(scrollChild:GetHeight() + 20)
    end

    -- Hide any extra font strings beyond our current zoneStatus count
    for i = #zoneStatus + 1, #fontStringPool do
        fontStringPool[i]:Hide()
    end

    -- Adjust scrollChild height to fit everything
    scrollChild:SetHeight(math.abs(yOffset) + 10)
    scrollChild:Show()
end

--------------------------------
-- FUNCTION: SCHEDULE NEXT UPDATE
--------------------------------

function ScheduleNextUpdate()
    -- Cancel any existing timer
    if updateTimer then
        updateTimer:Cancel()
    end

    -- Start a new timer (2 seconds) to update status
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

----------------------------------------------------
-- BOTTOM STATUS CONTAINER (CONTINENTS COMPLETION) --
----------------------------------------------------

local continentStatusContainer = CreateFrame("Frame", nil, exploreFrame, "ThinBorderTemplate")
continentStatusContainer:SetSize(580, 150)  -- Increased height to accommodate three rows
continentStatusContainer:SetPoint("BOTTOM", exploreFrame, "BOTTOM", 0, 10)

local function CreateContinentStatusTexts(parent, totalContinents)
    totalContinents = tonumber(totalContinents) or 0

    local texts = {}
    local buttons = {}
    local hoverFrames = {}
    local numColumns = 3
    local containerPadding = 10
    local cellSpacing = 10
    local containerWidth = parent:GetWidth() - 2 * containerPadding
    local cellWidth = (containerWidth - (numColumns - 1) * cellSpacing) / numColumns
    local cellHeight = 25

    for i = 1, totalContinents do
        local col = (i - 1) % numColumns
        local row = math.floor((i - 1) / numColumns)

        -- Create and position the text
        texts[i] = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        texts[i]:SetWidth(cellWidth)
        texts[i]:SetHeight(cellHeight)
        texts[i]:SetJustifyH("CENTER")
        texts[i]:SetJustifyV("MIDDLE")
        texts[i]:SetPoint(
            "TOPLEFT",
            parent,
            "TOPLEFT",
            containerPadding + col * (cellWidth + cellSpacing),
            -(containerPadding + row * (cellHeight + cellSpacing))
        )

        -- Create an invisible button over the text
        buttons[i] = CreateFrame("Button", nil, parent)
        buttons[i]:SetSize(cellWidth, cellHeight)
        buttons[i]:SetPoint("TOPLEFT", texts[i], "TOPLEFT")

        -- OnClick logic with fallback to English if localization fails
        buttons[i]:SetScript("OnClick", function()
            local localizedContinentKey = LocalizeContinent(continentOrder[i])
            local continent = WaypointData[localizedContinentKey] and localizedContinentKey or continentOrder[i]

            if WaypointData[continent] then
                selectedContinent = continent
                selectedZone = nil
                UIDropDownMenu_SetText(continentDropdown, localizedContinentKey or continentOrder[i])
                UIDropDownMenu_SetText(zoneDropdown, "Select Zone")
                UpdateZoneStatusContainer(continent)
                headerText:SetText(continent)
                ScheduleNextUpdate()
            else
                --print("Error: Continent data not found for " .. (localizedContinentKey or continentOrder[i]))
            end
        end)

        -- Add hover frame for visual feedback
        hoverFrames[i] = parent:CreateTexture(nil, "BACKGROUND")
        hoverFrames[i]:SetSize(cellWidth, cellHeight)
        hoverFrames[i]:SetPoint("TOPLEFT", texts[i], "TOPLEFT")
        hoverFrames[i]:SetColorTexture(1, 1, 1, 0.2) -- Light white background with transparency
        hoverFrames[i]:Hide()

        -- Mouseover effects
        buttons[i]:SetScript("OnEnter", function() hoverFrames[i]:Show() end)
        buttons[i]:SetScript("OnLeave", function() hoverFrames[i]:Hide() end)
    end

    return texts
end

local continentStatusTexts = CreateContinentStatusTexts(continentStatusContainer, #continentOrder)

-------------------------------------------
-- OPTIONAL: INITIALIZE BOTTOM CONTINENTS --
-------------------------------------------

-- For an initial display, we can quickly run through them:
for index, continent in ipairs(continentOrder) do
    local zones = WaypointData[continent]
    local totalZones = 0
    local completedZones = 0

    if zones then
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
    end

    local color = (completedZones == totalZones and totalZones > 0) and "|cFF00FF00" or "|cFFFFFF00"
    continentStatusTexts[index]:SetText(
        color .. string.format("%s: %d/%d", continent, completedZones, totalZones) .. "|r"
    )
end

----------------------------
-- FUNCTION: UPDATE STATUS --
----------------------------

function UpdateContinentStatus()
    local continentOrder = {
        "Eastern Kingdoms", "Outland", "Draenor",
        "Kul Tiras", "Zandalar", "Northrend",
        "Pandaria", "Broken Isles", "Kalimdor",
        "The Maelstrom"
    }

    for index, englishContinentKey in ipairs(continentOrder) do
        -- 1) Get the localized name
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
            
            local color = (completedZones == totalZones and totalZones > 0) and "|cFF00FF00" or "|cFFFFFF00"
            continentStatusTexts[index]:SetText(
                color .. string.format("%s: %d/%d", localizedContinentKey, completedZones, totalZones) .. "|r"
            )
            continentStatusTexts[index]:Show()
        else
            -- Hide if we have no data for that continent
            continentStatusTexts[index]:Hide()
        end
    end
end

-------------------------
-- SLASH COMMAND SETUP --
-------------------------

SLASH_EXPLOREWITHTOMTOM1 = "/ewtt"
SlashCmdList["EXPLOREWITHTOMTOM"] = function(msg)
    if exploreFrame:IsVisible() then
        exploreFrame:Hide()
    else
        UpdateContinentStatus()
        exploreFrame:Show()
        ScheduleNextUpdate()
    end
end

------------------------------
-- STOP UPDATES WHEN CLOSED --
------------------------------

local function OnFrameHide()
    if updateTimer then
        updateTimer:Cancel()
        updateTimer = nil
    end
end

exploreFrame:SetScript("OnHide", OnFrameHide)