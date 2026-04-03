local AddOnName, KeystonePolaris = ...;

local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)

KeystonePolaris.defaults = {
    profile = {
        general = {
            fontSize = 12,
            textOpacity = 1,
            position = "CENTER",
            xOffset = 0,
            yOffset = 0,
            positioningDimBackground = false,
            positioningShowGrid = false,
            positioningGridSpacing = 60,
            informGroup = true,
            informChannel = "PARTY",
            showCompartmentIcon = true,
            showMinimapIcon = true,
            minimapAngle = 225,
            advancedOptionsEnabled = false,
            lastSeasonCheck = "",
            lastVersionCheck = "",
            rolesEnabled = {
                LEADER = true,
                TANK = true,
                HEALER = true,
                DAMAGER = true
            },
            -- Main display content options
            mainDisplay = {
                showCurrentPercent = true,            -- Show overall current enemy forces percent
                showCurrentPullPercent = true,        -- Show current MDT pull percent (if MDT is available)
                multiLine = true,                     -- Display extras on new lines instead of a single line
                showRequiredText = true,              -- Show the required/remaining text base
                requiredLabel = L["REQUIRED_DEFAULT"], -- Label for the required base value when numeric
                showSectionRequiredText = false,       -- Show the required/remaining text base
                sectionRequiredLabel = L["SECTION_REQUIRED_DEFAULT"], -- Label for the required base value when numeric
                currentLabel = L["CURRENT_DEFAULT"],   -- Label for current percent
                pullLabel = L["PULL_DEFAULT"],         -- Label for current pull percent
                formatMode = "percent",               -- Display format: "percent" or "count"
                prefixColor = { r = 1, g = 0.7960784, b = 0.2, a = 1 }, -- Color for prefixes (labels) (default: #ffcb33)
                singleLineSeparator = " | ",           -- Separator for single-line layout
                textAlign = "CENTER",                  -- Horizontal font alignment: LEFT, CENTER, RIGHT
                showProjected = false                   -- Append projected values next to Current/Required
            }
        },
        text = {font = "Friz Quadrata TT"},
        color = {
            inProgress = {r = 1, g = 1, b = 1, a = 1},
            finished = {r = 0, g = 1, b = 0, a = 1},
            missing = {r = 1, g = 0, b = 0, a = 1}
        },
        advanced = {}
    }
}

KeystonePolaris.defaults.profile.groupReminder = {
    enabled = true,
    showPopup = true,
    showChat = true,
    showPopupWhenGroupIsFull = false,
    suppressQuickJoinToast = false,
    showDungeonName = true,
    showGroupName = true,
    showGroupDescription = true,
    showAppliedRole = true,
    lastReminder = nil,
}
