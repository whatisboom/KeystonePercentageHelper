local AddOnName, KeystonePolaris = ...;

local H = KeystonePolaris.OptionsHelpers
local L = H.L
local ACR = H.ACR
local ColumnRow = H.ColumnRow
local MakeStatusColorOption = H.MakeStatusColorOption
local PreviewScenarioValues = H.PreviewScenarioValues

local AceGUIWidgetLSMlists = _G.AceGUIWidgetLSMlists

function KeystonePolaris:GetAppearanceOptions()
    return {
        name = L["APPEARANCE"],
        type = "group",
        order = 2,
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
                order = 0.02,
                width = "full",
                values = PreviewScenarioValues,
                get = function()
                    return KeystonePolaris._previewScenario or 1
                end,
                set = function() end,
            },
            fontRow = ColumnRow(1, {
                name = L["FONT"],
                type = "select",
                dialogControl = 'LSM30_Font',
                values = AceGUIWidgetLSMlists.font,
                style = "dropdown",
                get = function() return self.db.profile.text.font end,
                set = function(_, value)
                    self.db.profile.text.font = value
                    self:Refresh()
                end
            }, {
                name = L["FONT_ALIGN"],
                desc = L["FONT_ALIGN_DESC"],
                type = "select",
                values = {
                    LEFT = L["LEFT"],
                    CENTER = L["CENTER"],
                    RIGHT = L["RIGHT"],
                },
                get = function() return self.db.profile.general.mainDisplay.textAlign end,
                set = function(_, value)
                    self.db.profile.general.mainDisplay.textAlign = value
                    if self.ApplyTextLayout then self:ApplyTextLayout() end
                    if self.displayFrame and self.displayFrame.text then
                        local t = self.displayFrame.text
                        t:SetText(t:GetText())
                    end
                    if self.UpdatePercentageText then self:UpdatePercentageText() end
                    if self.ApplyTextLayout then self:ApplyTextLayout() end
                    if self.AdjustDisplayFrameSize then self:AdjustDisplayFrameSize() end

                    local function reapply()
                        if self.displayFrame and self.displayFrame.text then
                            if self.ApplyTextLayout then self:ApplyTextLayout() end
                            local t = self.displayFrame.text
                            t:SetText(t:GetText())
                            if self.AdjustDisplayFrameSize then self:AdjustDisplayFrameSize() end
                        end
                    end
                    C_Timer.After(0.03, reapply)
                    C_Timer.After(0.08, reapply)
                    C_Timer.After(0.15, reapply)

                    local origMulti = self.db.profile.general.mainDisplay.multiLine
                    local function setMulti(val)
                        self.db.profile.general.mainDisplay.multiLine = val
                        ACR:NotifyChange(AddOnName)
                    end
                    setMulti(not origMulti)
                    reapply()
                    C_Timer.After(0.05, function()
                        setMulti(origMulti)
                        reapply()
                    end)
                    C_Timer.After(0.10, function()
                        setMulti(origMulti)
                        reapply()
                    end)
                    C_Timer.After(0.20, function()
                        setMulti(origMulti)
                        reapply()
                    end)
                end,
                disabled = function()
                    return not self.db.profile.general.mainDisplay.multiLine
                end
            }),
            fontSizeRow = ColumnRow(2, {
                name = L["FONT_SIZE"],
                desc = L["FONT_SIZE_DESC"],
                type = "range",
                min = 8,
                max = 64,
                step = 1,
                get = function()
                    return self.db.profile.general.fontSize
                end,
                set = function(_, value)
                    self.db.profile.general.fontSize = value
                    self:Refresh()
                end
            }, {
                name = L["TEXT_OPACITY"],
                desc = L["TEXT_OPACITY_DESC"],
                type = "range",
                min = 0, max = 1, step = 0.05,
                isPercent = true,
                get = function()
                    return self.db.profile.general.textOpacity or 1
                end,
                set = function(_, value)
                    self.db.profile.general.textOpacity = value
                    if self.UpdatePercentageText then self:UpdatePercentageText() end
                    self:Refresh()
                end,
            }),
            colorsSpacer = {
                type = "description",
                name = " ",
                order = 2.9,
                width = "full",
            },
            colorsHeader = {
                type = "header",
                name = L["COLORS"],
                order = 3,
            },
            colorsRow1 = ColumnRow(4, {
                name = L["PREFIX_COLOR"],
                desc = L["PREFIX_COLOR_DESC"],
                type = "color",
                get = function()
                    local c = self.db.profile.general.mainDisplay.prefixColor or (self.defaults and self.defaults.profile.general.mainDisplay.prefixColor) or {r=1,g=0.7960784,b=0.2,a=1}
                    return c.r, c.g, c.b, c.a
                end,
                set = function(_, r, g, b, a)
                    local cfg = self.db.profile.general.mainDisplay
                    if not cfg.prefixColor then
                        cfg.prefixColor = { r = r, g = g, b = b, a = a }
                    else
                        local c = cfg.prefixColor
                        c.r, c.g, c.b, c.a = r, g, b, a
                    end
                    self:UpdateColorCache()
                    self:UpdatePercentageText()
                    self:Refresh()
                    ACR:NotifyChange(AddOnName)
                end
            }, MakeStatusColorOption(L["IN_PROGRESS"], L["IN_PROGRESS_COLOR_DESC"], "inProgress", self)),
            colorsRow2 = ColumnRow(5,
                MakeStatusColorOption(L["MISSING"], L["MISSING_COLOR_DESC"], "missing", self),
                MakeStatusColorOption(L["FINISHED_COLOR"], L["FINISHED_COLOR_DESC"], "finished", self)),
        }
    }
end
