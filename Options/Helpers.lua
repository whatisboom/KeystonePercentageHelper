local AddOnName, KeystonePolaris = ...;

local pairs = pairs
local gsub = string.gsub
local strsplit = strsplit

-- Get localization table
local L = LibStub("AceLocale-3.0"):GetLocale(AddOnName, true)
local ACR = LibStub("AceConfigRegistry-3.0")

-- MDT integration unavailable due to Blizzard API changes in Midnight
local MDT_FEATURES_ENABLED = false
KeystonePolaris.mdtFeaturesEnabled = MDT_FEATURES_ENABLED

-- Shared preview scenario index (persists across Display and Appearance pages)
KeystonePolaris._previewScenario = 1

-- Create helpers namespace for shared utilities across Options/ files
local H = {}
KeystonePolaris.OptionsHelpers = H

-- Re-export commonly needed references
H.L = L
H.ACR = ACR
H.AddOnName = AddOnName
H.MDT_FEATURES_ENABLED = MDT_FEATURES_ENABLED

function H.PreviewScenarioValues()
    local scenarios = KeystonePolaris.PreviewScenarios
    if not scenarios then return {} end
    local vals = {}
    for i, s in ipairs(scenarios) do
        if not s.requiresMDT or KeystonePolaris.mdtFeaturesEnabled then
            vals[i] = s.name
        end
    end
    return vals
end

function H.ColumnRow(order, left, right, spacerWidth)
    left.order = 1
    left.width = left.width or 1.25
    right.order = 2
    right.width = right.width or 1.25
    return {
        type = "group", inline = true, name = "", order = order,
        args = {
            col1 = left,
            spacer = { name = " ", type = "description", order = 1.5, width = spacerWidth or 0.12 },
            col2 = right,
        }
    }
end

function H.MakeStatusColorOption(name, desc, colorKey, self)
    return {
        name = name,
        desc = desc,
        type = "color",
        get = function()
            local color = self.db.profile.color[colorKey]
            return color.r, color.g, color.b, color.a
        end,
        set = function(_, r, g, b, a)
            local color = self.db.profile.color[colorKey]
            color.r, color.g, color.b, color.a = r, g, b, a
            if self.UpdateColorCache then self:UpdateColorCache() end
            if self.UpdatePercentageText then self:UpdatePercentageText() end
            self:Refresh()
            ACR:NotifyChange(AddOnName)
        end
    }
end

-- Shallow-clone a table. If the WoW utility `CopyTable` exists we use it,
-- otherwise fall back to manual copy. This is needed so that changing the
-- `order` field for one AceConfig option group does not overwrite the value
-- used in another section.
function H.CloneTable(tbl)
    if type(CopyTable) == "function" then return CopyTable(tbl) end
    local t = {}
    for k, v in pairs(tbl) do t[k] = v end
    return t
end

-- Helper to format date string "YYYY-MM-DD" to localized format or default
function H.FormatSeasonDate(dateStr)
    if not dateStr then return "" end
    local year, month, day = strsplit("-", dateStr)
    if year and month and day then
         if L["%month%-%day%-%year%"] then
            local formatted = L["%month%-%day%-%year%"]
            formatted = gsub(formatted, "%%year%%", year)
            formatted = gsub(formatted, "%%month%%", month)
            formatted = gsub(formatted, "%%day%%", day)
            return formatted
         else
            return string.format("%s-%s-%s", year, month, day)
         end
    end
    return dateStr
end

-- Insert dungeon option groups into an AceConfig args table in alphabetical
-- order. Every option is cloned from `sharedOptions[key]`, placed after the
-- section headers (offset with `baseOrder`), and assigned its own `order` so
-- AceConfig displays them deterministically.
function H.InsertSortedDungeonOptions(addon, dungeonKeys, sharedOptions, targetArgs, baseOrder)
    local sortable = {}
    for _, key in ipairs(dungeonKeys) do
        local mapId = addon:GetDungeonIdByKey(key)
        local name = (mapId and select(1, C_ChallengeMode.GetMapUIInfo(mapId))) or key
        table.insert(sortable, { key = key, name = name })
    end
    table.sort(sortable, function(a, b) return a.name < b.name end)

    for idx, entry in ipairs(sortable) do
        local opt = H.CloneTable(sharedOptions[entry.key])
        opt.order = baseOrder + idx
        targetArgs[entry.key] = opt
    end
end
