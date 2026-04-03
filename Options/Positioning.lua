local _, KeystonePolaris = ...;

local H = KeystonePolaris.OptionsHelpers
local L = H.L
local ColumnRow = H.ColumnRow

local HideUIPanel = _G.HideUIPanel

function KeystonePolaris:GetPositioningOptions()
    return {
        name = L["POSITIONING"],
        type = "group",
        order = 3,
        args = {
            positionRow = ColumnRow(2, {
                name = L["POSITION"],
                type = "select",
                sorting = { "TOP", "CENTER", "BOTTOM" },
                values = {
                    TOP = L["TOP"],
                    CENTER = L["CENTER"],
                    BOTTOM = L["BOTTOM"]
                },
                get = function()
                    return self.db.profile.general.position
                end,
                set = function(_, value)
                    self.db.profile.general.position = value
                    self.db.profile.general.xOffset = 0
                    self.db.profile.general.yOffset = 0
                    self:Refresh()
                end
            }, {
                name = L["SHOW_ANCHOR"],
                type = "execute",
                func = function()
                    HideUIPanel(SettingsPanel)
                    self:EnterPositioningMode()
                end
            }),
            offsetRow = ColumnRow(3, {
                name = L["X_OFFSET"],
                type = "range",
                min = -math.ceil(GetScreenWidth()),
                max = math.ceil(GetScreenWidth()),
                step = 1,
                get = function()
                    return self.db.profile.general.xOffset
                end,
                set = function(_, value)
                    self.db.profile.general.xOffset = value
                    self:Refresh()
                end
            }, {
                name = L["Y_OFFSET"],
                type = "range",
                min = -math.ceil(GetScreenHeight()),
                max = math.ceil(GetScreenHeight()),
                step = 1,
                get = function()
                    return self.db.profile.general.yOffset
                end,
                set = function(_, value)
                    self.db.profile.general.yOffset = value
                    self:Refresh()
                end
            }),
            positioningHeader = {
                type = "header",
                name = "",
                order = 4,
            },
            dimBackground = {
                name = L["DIM_BACKGROUND"],
                type = "toggle",
                order = 5,
                get = function()
                    return self.db.profile.general.positioningDimBackground
                end,
                set = function(_, value)
                    self.db.profile.general.positioningDimBackground = not not value
                end,
            },
            showGrid = {
                name = L["SHOW_GRID"],
                type = "toggle",
                order = 6,
                get = function()
                    return self.db.profile.general.positioningShowGrid
                end,
                set = function(_, value)
                    self.db.profile.general.positioningShowGrid = not not value
                end,
            },
            gridSpacing = {
                name = L["GRID_SPACING"],
                type = "range",
                order = 7,
                min = 10,
                max = 200,
                step = 5,
                get = function()
                    return self.db.profile.general.positioningGridSpacing
                end,
                set = function(_, value)
                    self.db.profile.general.positioningGridSpacing = value
                end,
                disabled = function()
                    return not self.db.profile.general.positioningShowGrid
                end,
            }
        }
    }
end
