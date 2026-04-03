local AddOnName, KeystonePolaris = ...;

local H = KeystonePolaris.OptionsHelpers
local L = H.L
local ACR = H.ACR
local ColumnRow = H.ColumnRow
local PreviewScenarioValues = H.PreviewScenarioValues
local MDT_FEATURES_ENABLED = H.MDT_FEATURES_ENABLED

local _G = _G

local function IsMDTAvailable()
    if not MDT_FEATURES_ENABLED then return false end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("MythicDungeonTools") or (_G.MDT ~= nil) or (_G.MethodDungeonTools ~= nil)
    end
    return (_G and (_G.MDT or _G.MethodDungeonTools))
end

-- Display options: control which values to show and layout
function KeystonePolaris:GetDisplayOptions()
    return {
        name = L["DISPLAY"],
        type = "group",
        order = 1,
        args = {
            previewScenario = {
                name = L["PREVIEW_SCENARIO"],
                type = "select",
                order = 0.01,
                width = "full",
                values = PreviewScenarioValues,
                get = function()
                    return KeystonePolaris._previewScenario or 1
                end,
                set = function(_, value)
                    KeystonePolaris._previewScenario = value
                    ACR:NotifyChange(AddOnName)
                end,
            },
            preview = {
                name = "",
                type = "select",
                dialogControl = "KeystonePolaris_Preview",
                order = 1,
                width = "full",
                values = PreviewScenarioValues,
                get = function()
                    return KeystonePolaris._previewScenario or 1
                end,
                set = function() end,
            },
            formatMode = {
                name = L["FORMAT_MODE"],
                desc = L["FORMAT_MODE_DESC"],
                type = "select",
                order = 2,
                width = "full",
                values = function()
                    local percentLabel = L["PERCENTAGE"]
                    local countLabel = L["COUNT"]
                    return { percent = percentLabel, count = countLabel }
                end,
                get = function()
                    return self.db.profile.general.mainDisplay.formatMode or "percent"
                end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.formatMode = value == "count" and "count" or "percent"
                    if self.UpdatePercentageText then self:UpdatePercentageText() end
                    if self.ApplyTextLayout then self:ApplyTextLayout() end
                    if self.AdjustDisplayFrameSize then self:AdjustDisplayFrameSize() end
                end
            },
            requiredRow = ColumnRow(3, {
                name = L["SHOW_REQUIRED_PREFIX"],
                desc = L["SHOW_REQUIRED_PREFIX_DESC"],
                type = "toggle",
                get = function() return self.db.profile.general.mainDisplay.showRequiredText end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.showRequiredText = value
                    self:UpdatePercentageText()
                end
            }, {
                name = L["LABEL"],
                desc = L["REQUIRED_LABEL_DESC"],
                type = "input",
                get = function() return self.db.profile.general.mainDisplay.requiredLabel end,
                set = function(_, value)
                    local text = type(value) == "string" and value or ""
                    text = (text ~= "" and text) or L["REQUIRED_DEFAULT"]
                    self.db.profile.general.mainDisplay.requiredLabel = text
                    self:UpdatePercentageText()
                end,
                disabled = function()
                    return not self.db.profile.general.mainDisplay.showRequiredText
                end
            }),
            sectionRequiredRow = ColumnRow(5, {
                name = L["SHOW_SECTION_REQUIRED_PREFIX"],
                desc = L["SHOW_SECTION_REQUIRED_PREFIX_DESC"],
                type = "toggle",
                get = function() return self.db.profile.general.mainDisplay.showSectionRequiredText end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.showSectionRequiredText = value
                    self:UpdatePercentageText()
                end
            }, {
                name = L["LABEL"],
                desc = L["SECTION_REQUIRED_LABEL_DESC"],
                type = "input",
                get = function() return self.db.profile.general.mainDisplay.sectionRequiredLabel end,
                set = function(_, value)
                    local text = type(value) == "string" and value or ""
                    text = (text ~= "" and text) or L["SECTION_REQUIRED_DEFAULT"]
                    self.db.profile.general.mainDisplay.sectionRequiredLabel = text
                    self:UpdatePercentageText()
                end,
                disabled = function()
                    return not self.db.profile.general.mainDisplay.showSectionRequiredText
                end
            }),
            currentRow = ColumnRow(7, {
                name = L["SHOW_CURRENT_PERCENT"],
                desc = L["SHOW_CURRENT_PERCENT_DESC"],
                type = "toggle",
                get = function() return self.db.profile.general.mainDisplay.showCurrentPercent end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.showCurrentPercent = value
                    self:UpdatePercentageText()
                end
            }, {
                name = L["LABEL"],
                desc = L["CURRENT_LABEL_DESC"],
                type = "input",
                get = function() return self.db.profile.general.mainDisplay.currentLabel end,
                set = function(_, value)
                    local text = type(value) == "string" and value or ""
                    text = (text ~= "" and text) or L["CURRENT_DEFAULT"]
                    self.db.profile.general.mainDisplay.currentLabel = text
                    self:UpdatePercentageText()
                end,
                disabled = function()
                    return not self.db.profile.general.mainDisplay.showCurrentPercent
                end
            }),
            showCurrentPullPercentLocked = {
                name = "|cff9d9d9d" .. L["SHOW_CURRENT_PULL_PERCENT"] .. "|r",
                desc = L["MDT_FEATURE_UNAVAILABLE"],
                type = "description",
                dialogControl = "InteractiveLabel",
                order = 12,
                width = 1.4,
                hidden = function() return MDT_FEATURES_ENABLED and IsMDTAvailable() end,
                image = "Interface\\PetBattles\\PetBattle-LockIcon",
                imageWidth = 20,
                imageHeight = 20,
                fontSize = "medium",
            },
            showCurrentPullPercent = {
                name = L["SHOW_CURRENT_PULL_PERCENT"],
                desc = L["SHOW_CURRENT_PULL_PERCENT_DESC"],
                type = "toggle",
                order = 12,
                width = 1.4,
                hidden = function() return (not MDT_FEATURES_ENABLED) or (not IsMDTAvailable()) end,
                get = function() return self.db.profile.general.mainDisplay.showCurrentPullPercent end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.showCurrentPullPercent = value
                    self:UpdatePercentageText()
                end,
            },
            pullLabel = {
                name = L["LABEL"],
                desc = L["PULL_LABEL_DESC"],
                type = "input",
                order = 13,
                width = 1,
                get = function() return self.db.profile.general.mainDisplay.pullLabel end,
                set = function(_, value)
                    local text = type(value) == "string" and value or ""
                    text = (text ~= "" and text) or L["PULL_DEFAULT"]
                    self.db.profile.general.mainDisplay.pullLabel = text
                    self:UpdatePercentageText()
                end,
                hidden = function()
                    return not self.db.profile.general.mainDisplay.showCurrentPullPercent or not IsMDTAvailable()
                end
            },
            showProjectedLocked = {
                name = "|cff9d9d9d" .. L["SHOW_PROJECTED"] .. "|r",
                desc = L["MDT_FEATURE_UNAVAILABLE"],
                type = "description",
                dialogControl = "InteractiveLabel",
                order = 14,
                width = 1.6,
                hidden = function() return MDT_FEATURES_ENABLED and IsMDTAvailable() end,
                image = "Interface\\PetBattles\\PetBattle-LockIcon",
                imageWidth = 20,
                imageHeight = 20,
                fontSize = "medium",
            },
            showProjected = {
                name = L["SHOW_PROJECTED"],
                desc = L["SHOW_PROJECTED_DESC"],
                type = "toggle",
                order = 14,
                width = 1.6,
                hidden = function() return (not MDT_FEATURES_ENABLED) or (not IsMDTAvailable()) end,
                get = function() return self.db.profile.general.mainDisplay.showProjected end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.showProjected = value
                    if self.UpdatePercentageText then self:UpdatePercentageText() end
                    if self.ApplyTextLayout then self:ApplyTextLayout() end
                    if self.AdjustDisplayFrameSize then self:AdjustDisplayFrameSize() end
                end,
            },
            multiLineRow = ColumnRow(9, {
                name = L["USE_MULTI_LINE_LAYOUT"],
                desc = L["USE_MULTI_LINE_LAYOUT_DESC"],
                type = "toggle",
                get = function() return self.db.profile.general.mainDisplay.multiLine end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.multiLine = value
                    if self.UpdatePercentageText then self:UpdatePercentageText() end
                    if self.ApplyTextLayout then self:ApplyTextLayout() end
                    if self.AdjustDisplayFrameSize then self:AdjustDisplayFrameSize() end
                    ACR:NotifyChange(AddOnName)
                    local function reapply()
                        if self.displayFrame and self.displayFrame.text then
                            if self.UpdatePercentageText then self:UpdatePercentageText() end
                            if self.ApplyTextLayout then self:ApplyTextLayout() end
                            if self.AdjustDisplayFrameSize then self:AdjustDisplayFrameSize() end
                            local t = self.displayFrame.text
                            t:SetText(t:GetText())
                        end
                    end
                    C_Timer.After(0.03, reapply)
                    C_Timer.After(0.08, reapply)
                    C_Timer.After(0.15, reapply)
                end
            }, {
                name = L["SINGLE_LINE_SEPARATOR"],
                desc = L["SINGLE_LINE_SEPARATOR_DESC"],
                type = "input",
                get = function() return self.db.profile.general.mainDisplay.singleLineSeparator end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.singleLineSeparator = tostring(value or " | ")
                    self:UpdatePercentageText()
                end,
                disabled = function()
                    return self.db.profile.general.mainDisplay.multiLine
                end
            }),
        }
    }
end
