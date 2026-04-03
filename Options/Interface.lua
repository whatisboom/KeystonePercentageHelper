local _, KeystonePolaris = ...;

local H = KeystonePolaris.OptionsHelpers
local L = H.L
local ColumnRow = H.ColumnRow

function KeystonePolaris:GetInterfaceOptions()
    return {
        name = L["INTERFACE"],
        type = "group",
        order = 5,
        args = {
            iconsRow = ColumnRow(1, {
                type = "toggle",
                name = L["SHOW_COMPARTMENT_ICON"],
                get = function()
                    return self.db.profile.general.showCompartmentIcon
                end,
                set = function(_, value)
                    self.db.profile.general.showCompartmentIcon = not not value
                    self:UpdateCompartmentIconVisibility()
                end,
            }, {
                type = "toggle",
                name = L["SHOW_MINIMAP_ICON"],
                get = function()
                    return self.db.profile.general.showMinimapIcon
                end,
                set = function(_, value)
                    self.db.profile.general.showMinimapIcon = not not value
                    self:UpdateMinimapIconVisibility()
                end,
            }),
            commandsHeader = {
                order = 3,
                type = "header",
                name = L["COMMANDS_HEADER"] or "Commands",
            },
            commandsDescription = {
                order = 4,
                type = "description",
                name = function()
                    return self:ColorizeCommands(L["COMMANDS_HELP_DESC"] or "")
                end,
                fontSize = "medium",
            },
        }
    }
end
