local _, KeystonePolaris = ...;

local H = KeystonePolaris.OptionsHelpers
local L = H.L
local FormatSeasonDate = H.FormatSeasonDate
local InsertSortedDungeonOptions = H.InsertSortedDungeonOptions

local pairs = pairs
local select = select
local strsplit = strsplit
local CALENDAR_WEEKDAY_NAMES = _G.CALENDAR_WEEKDAY_NAMES

local expansions = KeystonePolaris.Expansions

-- Pure helper: days until a YYYY-MM-DD or YYYY-MM-DD HH:MM date (nil if invalid)
local function GetDaysUntil(dateStr)
    if not dateStr or dateStr == "" then return nil end
    local y, m, d, h, min = dateStr:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)%s+(%d%d):(%d%d)$")
    local hasTime = y ~= nil
    if not hasTime then
        y, m, d = dateStr:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    end
    local year, month, day = tonumber(y), tonumber(m), tonumber(d)
    if not year or not month or not day then return nil end

    local target
    local current
    if hasTime then
        local hour, minute = tonumber(h), tonumber(min)
        if not hour or not minute then return nil end
        target = time({year = year, month = month, day = day, hour = hour, min = minute})
        current = time()
        if target < current then
            return -1
        end
    else
        local currentDate = date("%Y-%m-%d")
        local cYear, cMonth, cDay = strsplit("-", currentDate)
        cYear, cMonth, cDay = tonumber(cYear), tonumber(cMonth), tonumber(cDay)
        if not cYear or not cMonth or not cDay then return nil end
        target = time({year = year, month = month, day = day, hour = 12})
        current = time({year = cYear, month = cMonth, day = cDay, hour = 12})
    end

    return math.floor((target - current) / 86400)
end

-- Pure helper: formatted countdown text
local function GetSeasonCountdownText(daysUntil, prefixKey, withIcon, targetDate)
    if not daysUntil or daysUntil < 0 then return nil end
    local iconPrefix = withIcon and
                           "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:16:16:0:0|t " or
                           ""
    if daysUntil <= 7 then
        local weekdaySuffix = ""
        if targetDate then
            local dateOnly = targetDate:match("^(%d%d%d%d%-%d%d%-%d%d)") or targetDate
            local year, month, day = strsplit("-", dateOnly)
            year, month, day = tonumber(year), tonumber(month), tonumber(day)
            if year and month and day then
                local target = time({year = year, month = month, day = day, hour = 12})
                local wday = date("*t", target).wday
                local weekdayName = CALENDAR_WEEKDAY_NAMES and
                                        CALENDAR_WEEKDAY_NAMES[wday]
                if weekdayName then
                    local weekdayFormat = L["WEEKDAY_NEXT_FORMAT"]
                    weekdaySuffix = " " .. weekdayFormat:format(weekdayName)
                end
            end
        end
        if daysUntil == 1 then
            return iconPrefix .. L[prefixKey .. "_TOMORROW"]
        end
        local dayText = L[prefixKey .. "_DAYS"]:format(daysUntil)
        return iconPrefix .. dayText .. weekdaySuffix
    end
    if daysUntil <= 14 then
        local weeks = math.ceil(daysUntil / 7)
        local weekKey = weeks == 1 and "_WEEK" or "_WEEKS"
        local weekText = L[prefixKey .. weekKey]
        if weeks ~= 1 then
            weekText = weekText:format(weeks)
        end
        return iconPrefix .. weekText
    end
    if daysUntil <= 30 then
        return iconPrefix .. L[prefixKey .. "_ONE_MONTH"]
    end
    return nil
end

-- Pure helper: add days to a YYYY-MM-DD string
local function AddDays(dateStr, days)
    if not dateStr or days == 0 then return dateStr end
    local year, month, day = strsplit("-", dateStr)
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if not year or not month or not day then return dateStr end

    -- Convert to timestamp, add seconds, convert back
    local t = time({year=year, month=month, day=day, hour=12}) -- noon to avoid DST issues
    t = t + (days * 86400)
    return date("%Y-%m-%d", t)
end

function KeystonePolaris:GetAdvancedOptions()
    -- Helper function to get dungeon name with icon (closes over self)
    local function GetDungeonNameWithIcon(dungeonKey)
        local mapId = self:GetDungeonIdByKey(dungeonKey)

        local name, texture
        if mapId then
            name = select(1, C_ChallengeMode.GetMapUIInfo(mapId))
            texture = select(4, C_ChallengeMode.GetMapUIInfo(mapId))
        end

        -- Retrieve manual display name
        local manualName
        for _, expansion in ipairs(expansions) do
            local names = self[expansion.id .. "_DUNGEON_NAMES"]
            if names and names[dungeonKey] then
                manualName = names[dungeonKey]
                break
            end
        end

        -- Fallbacks
        local icon = texture or "Interface\\Icons\\INV_Misc_QuestionMark"
        local displayName = name or manualName or dungeonKey or "Unknown"

        return '|T' .. icon .. ":20:20:0:0|t " .. displayName
    end

    -- Helper function to format dungeon text (closes over self via GetDungeonNameWithIcon)
    local function FormatDungeonText(dungeonKey, defaults)
        local text = ""
        if defaults then
            text = text .. "|cffffd700" .. GetDungeonNameWithIcon(dungeonKey) ..
                       "|r:\n"

            local bossNum = 1
            while defaults["Boss" .. self:GetBossNumberString(bossNum)] do
                local bossKey = "Boss" .. self:GetBossNumberString(bossNum)
                local informKey = bossKey .. "Inform"
                local bossName = self:GetBossName(dungeonKey, bossNum)

                text = text ..
                           string.format(
                               "  %s: |cff40E0D0%.2f%%|r - " ..
                                   L["SHOW_INFORM_GROUP_BUTTON"] .. ": %s\n",
                               bossName,
                               defaults[bossKey] or 0,
                               defaults[informKey] and '|cff00ff00' .. L["YES"] ..
                                   '|r' or '|cffff0000' .. L["NO"] .. '|r')
                bossNum = bossNum + 1
            end

            -- Show logical boss order if available
            local bossOrder = defaults.bossOrder
            if type(bossOrder) == "table" and next(bossOrder) ~= nil then
                -- Extra blank line between last boss percentage and order header
                text = text .. "\n"
                -- Collect boss names in logical section order
                local names = {}
                local numSections = #bossOrder
                for section = 1, numSections do
                    local idx = bossOrder[section]
                    if type(idx) == "number" then
                        local bossName = self:GetBossName(dungeonKey, idx)
                        table.insert(names, bossName)
                    end
                end

                if #names > 0 then
                    -- Orange title and numbered list (1) BossName, 2) BossName, ...)
                    local orderTitle = "|cffffa500" .. L["BOSS_ORDER"] .. "|r"
                    text = text .. "  " .. orderTitle .. ":\n"

                    for i, bossName in ipairs(names) do
                        text = text .. string.format("    %d) %s\n", i, bossName)
                    end

                    text = text .. "\n"
                else
                    text = text .. "\n"
                end
            else
                text = text .. "\n"
            end
        end
        return text
    end

    -- Create shared dungeon options
    local sharedDungeonOptions = {}
    for _, expansion in ipairs(expansions) do
        local dungeonIds = self[expansion.id .. "_DUNGEON_IDS"]
        if dungeonIds then
            for dungeonKey, _ in pairs(dungeonIds) do
                sharedDungeonOptions[dungeonKey] =
                    self:CreateDungeonOptions(dungeonKey, 0)
            end
        end
    end

    -- Generic builder for section args (used for seasons and expansions)
    local function CreateGenericSectionArgs(sectionLabel, dungeonKeys, dungeonFilter, getDefaultsFn, headerTitle, extraDisclaimerText)
        local args = {
            title = {
                order = 0,
                type = "description",
                fontSize = "large",
                name = (headerTitle or ("|cffeda55f" .. sectionLabel .. "|r")) .. "\n"
            },
            seasonAlert = extraDisclaimerText and {
                order = 0.1,
                type = "description",
                fontSize = "medium",
                name = extraDisclaimerText or "",
            } or nil,
            separatorTitle = {
                order = 0.2,
                type = "header",
                name = "",
            },
            disclaimer = {
                order = 0.5,
                type = "description",
                fontSize = "medium",
                name = L["ROUTES_DISCLAIMER"],
            },
            separator = {order = 1, type = "header", name = ""},
            export = {
                order = 1.25,
                type = "execute",
                name = L["EXPORT_SECTION"],
                desc = (L["EXPORT_SECTION_DESC"]):format(sectionLabel),
                func = function()
                    local addon = KeystonePolaris
                    local sectionData = {}
                    for _, dungeonKey in ipairs(dungeonKeys) do
                        if addon.db and addon.db.profile and addon.db.profile.advanced and addon.db.profile.advanced[dungeonKey] then
                            sectionData[dungeonKey] = addon.db.profile.advanced[dungeonKey]
                        end
                    end
                    addon:ExportDungeonSettings(sectionData, "section", sectionLabel)
                end
            },
            import = {
                order = 1.5,
                type = "execute",
                name = L["IMPORT_SECTION"],
                desc = (L["IMPORT_SECTION_DESC"]):format(sectionLabel),
                func = function()
                    KeystonePolaris:ShowImportDialog(sectionLabel, dungeonFilter)
                end
            },
            separatorDefaultPercentages = {
                order = 2,
                type = "header",
                name = L["DEFAULT_PERCENTAGES"],
            },
            defaultPercentages = {
                order = 2.5,
                type = "description",
                fontSize = "medium",
                name = L["DEFAULT_PERCENTAGES_DESC"],
            },
            separatorDefaultPercentagesText = {
                order = 2.8,
                type = "header",
                name = "",
            },
            defaultPercentagesText = {
                order = 3,
                type = "description",
                fontSize = "medium",
                name = function()
                    local text = ""
                    for _, dungeonKey in ipairs(dungeonKeys) do
                        local defaults = getDefaultsFn and getDefaultsFn(dungeonKey) or nil
                        text = text .. FormatDungeonText(dungeonKey, defaults)
                    end
                    return text
                end
            }
        }

        -- Add per-dungeon options (alphabetical by localized name)
        -- Start at order 4 to come after the defaults header/description/text
        InsertSortedDungeonOptions(self, dungeonKeys, sharedDungeonOptions, args, 4)
        return args
    end

    -- Create current season options
    local currentSeasonDungeons = {}
    local currentSeasonTitle
    local currentSeasonListTitle
    local currentSeasonAlertText

    -- Get the current date
    local currentDate = date("%Y-%m-%d")

    -- Resolve the current season based on start/end dates
    local currentSeasonId, currentSeasonStart, currentSeasonEnd =
        self:GetSeasonByDate(currentDate)

    if currentSeasonId then
        local seasonDungeonsTabName = currentSeasonId .. "_DUNGEONS"
        local seasonDungeons = self[seasonDungeonsTabName]

        if seasonDungeons then
            for _, expansion in ipairs(expansions) do
                local dungeonIds = self[expansion.id .. "_DUNGEON_IDS"]
                if dungeonIds then
                    for dungeonKey, dungeonId in pairs(dungeonIds) do
                        if seasonDungeons[dungeonId] then
                            table.insert(currentSeasonDungeons,
                                         {key = dungeonKey, id = dungeonId})
                        end
                    end
                end
            end
        end
    end

    -- Sort dungeons alphabetically by their localized names
    table.sort(currentSeasonDungeons, function(a, b)
        local mapIdA = a.id or self:GetDungeonIdByKey(a.key)
        local mapIdB = b.id or self:GetDungeonIdByKey(b.key)

        local nameA
        if mapIdA then nameA = select(1, C_ChallengeMode.GetMapUIInfo(mapIdA)) end
        nameA = nameA or a.key

        local nameB
        if mapIdB then nameB = select(1, C_ChallengeMode.GetMapUIInfo(mapIdB)) end
        nameB = nameB or b.key

        return nameA < nameB
    end)

    -- Create current season dungeon args (using generic builder)
    local dungeonArgs
    do
        local keys = {}
        local filter = {}
        for _, d in ipairs(currentSeasonDungeons) do
            table.insert(keys, d.key)
            filter[d.key] = true
        end

        local function getDefaultsFn(dungeonKey)
            for _, expansion in ipairs(expansions) do
                local ids = self[expansion.id .. "_DUNGEON_IDS"]
                if ids and ids[dungeonKey] then
                    local defaults = self[expansion.id .. "_DEFAULTS"]
                    return defaults and defaults[dungeonKey] or nil
                end
            end
            return nil
        end

        local daysUntilEnd = currentSeasonEnd and GetDaysUntil(currentSeasonEnd)
        local countdownText = GetSeasonCountdownText(daysUntilEnd, "SEASON_ENDS_IN", true, currentSeasonEnd)
        local hasEndSoon = countdownText ~= nil
        currentSeasonTitle = "|cff40E0D0" .. L["CURRENT_SEASON"] .. "|r - |cffbbbbbb" .. FormatSeasonDate(currentSeasonStart)
        if currentSeasonEnd and currentSeasonEnd ~= "" then
            currentSeasonTitle = currentSeasonTitle .. " -> " .. FormatSeasonDate(currentSeasonEnd)
        end
        currentSeasonTitle = currentSeasonTitle .. "|r"
        currentSeasonListTitle = currentSeasonTitle
        if hasEndSoon then
            currentSeasonListTitle = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:16:16:0:0|t " ..
                currentSeasonTitle
            currentSeasonAlertText = countdownText
        end
        dungeonArgs = CreateGenericSectionArgs(L["CURRENT_SEASON"], keys, filter, getDefaultsFn, currentSeasonTitle, currentSeasonAlertText)
    end

    -- Create next season dungeon args
    local nextSeasonDungeons = {}
    local nextSeasonTitle
    local nextSeasonListTitle

    -- Find the next season (first season that starts after current date)
    local _, _, _, nextSeasonId, nextSeasonDate = self:GetSeasonByDate(currentDate)

    if nextSeasonId then
        local nextSeasonDungeonsTabName = nextSeasonId .. "_DUNGEONS"
        local nextSeasonDungeonsTable = self[nextSeasonDungeonsTabName]

        if nextSeasonDungeonsTable then
            for _, expansion in ipairs(expansions) do
                local dungeonIds = self[expansion.id .. "_DUNGEON_IDS"]
                if dungeonIds then
                    for dungeonKey, dungeonId in pairs(dungeonIds) do
                        if nextSeasonDungeonsTable[dungeonId] then
                            table.insert(nextSeasonDungeons,
                                         {key = dungeonKey, id = dungeonId})
                        end
                    end
                end
            end
        end
    end

    -- Sort dungeons alphabetically by their localized names
    table.sort(nextSeasonDungeons, function(a, b)
        local mapIdA = a.id or self:GetDungeonIdByKey(a.key)
        local mapIdB = b.id or self:GetDungeonIdByKey(b.key)

        local nameA
        if mapIdA then nameA = select(1, C_ChallengeMode.GetMapUIInfo(mapIdA)) end
        nameA = nameA or a.key

        local nameB
        if mapIdB then nameB = select(1, C_ChallengeMode.GetMapUIInfo(mapIdB)) end
        nameB = nameB or b.key

        return nameA < nameB
    end)

    -- Create next season dungeon args (using generic builder)
    local nextSeasonDungeonArgs
    do
        local keys = {}
        local filter = {}
        for _, d in ipairs(nextSeasonDungeons) do
            table.insert(keys, d.key)
            filter[d.key] = true
        end

        local function getDefaultsFn(dungeonKey)
            for _, expansion in ipairs(expansions) do
                local ids = self[expansion.id .. "_DUNGEON_IDS"]
                if ids and ids[dungeonKey] then
                    local defaults = self[expansion.id .. "_DEFAULTS"]
                    return defaults and defaults[dungeonKey] or nil
                end
            end
            return nil
        end

        nextSeasonTitle = "|cffff5733" .. L["NEXT_SEASON"] .. "|r - |cffbbbbbb" .. FormatSeasonDate(nextSeasonDate)
        local nextSeasonAlertText
        local nextSeasonEnd
        if nextSeasonId then
            local nextSeasonTable = self[nextSeasonId .. "_DUNGEONS"]
            if nextSeasonTable and nextSeasonTable.end_date then
                local portal = C_CVar.GetCVar("portal")
                if type(nextSeasonTable.end_date) == "table" then
                    nextSeasonEnd = nextSeasonTable.end_date[portal] or
                                    nextSeasonTable.end_date.default or
                                    nextSeasonTable.end_date.US or
                                    nextSeasonTable.end_date.EU
                else
                    nextSeasonEnd = nextSeasonTable.end_date
                end
            end
        end
        if nextSeasonEnd and nextSeasonEnd ~= "" then
            nextSeasonTitle = nextSeasonTitle .. " -> " .. FormatSeasonDate(nextSeasonEnd)
        end
        nextSeasonTitle = nextSeasonTitle .. "|r"
        local nextSeasonDaysUntilStart = nextSeasonDate and GetDaysUntil(nextSeasonDate)
        nextSeasonAlertText = GetSeasonCountdownText(nextSeasonDaysUntilStart, "SEASON_STARTS_IN", true, nextSeasonDate)
        nextSeasonListTitle = nextSeasonTitle
        if nextSeasonAlertText then
            nextSeasonListTitle = "|TInterface\\OptionsFrame\\UI-OptionsFrame-NewFeatureIcon:16:16:0:0|t " ..
                nextSeasonTitle
        end
        nextSeasonDungeonArgs = CreateGenericSectionArgs(L["NEXT_SEASON"], keys, filter, getDefaultsFn, nextSeasonTitle, nextSeasonAlertText)
    end

    -- Create expansion sections
    local args = {
        disclaimer = {
            order = 0,
            type = "description",
            fontSize = "medium",
            name = L["ROUTES_DISCLAIMER"],
        },
        separator = {
            order = 1,
            type = "header",
            name = "",
        },
        resetAll = {
            order = 2,
            type = "execute",
            name = L["RESET_ALL_DUNGEONS"],
            desc = L["RESET_ALL_DUNGEONS_DESC"],
            confirm = true,
            confirmText = L["RESET_ALL_DUNGEONS_CONFIRM"],
            func = function()
                -- Reset all dungeons to their defaults
                self:ResetAllDungeons()
            end
        },
        exportAllDungeons = {
            order = 3,
            type = "execute",
            name = L["EXPORT_ALL_DUNGEONS"],
            desc = L["EXPORT_ALL_DUNGEONS_DESC"],
            func = function()
                local addon = KeystonePolaris

                -- Collect all dungeon data
                local allDungeonData = {}
                for _, expansion in ipairs(expansions) do
                    if addon.db.profile.advanced then
                        for dungeonKey, _ in pairs(addon[expansion.id .. "_DUNGEON_IDS"] or {}) do
                            if addon.db.profile.advanced[dungeonKey] then
                                allDungeonData[dungeonKey] = addon.db.profile.advanced[dungeonKey]
                            end
                        end
                    end
                end
                addon:ExportDungeonSettings(allDungeonData, "all_dungeons")
            end
        },
        importAllDungeons = {
            order = 3.5,
            type = "execute",
            name = L["IMPORT_ALL_DUNGEONS"],
            desc = L["IMPORT_ALL_DUNGEONS_DESC"],
            func = function()
                KeystonePolaris:ShowImportDialog(nil)
            end
        }
    }

    -- Only add current season section if a current season exists and has dungeons
    if currentSeasonId and #currentSeasonDungeons > 0 then
        args.dungeons = {
            name = currentSeasonListTitle,
            type = "group",
            childGroups = "tree",
            order = 5,
            args = dungeonArgs
        }
    end

    -- Only add next season section if there are next season dungeons
    if nextSeasonId and #nextSeasonDungeons > 0 then
        args.nextseason = {
            name = nextSeasonListTitle,
            type = "group",
            childGroups = "tree",
            order = 4,
            args = nextSeasonDungeonArgs
        }
    end

    -- Helper to create a remix section (closes over self)
    local function HandleRemixSection(_, data, _)
        -- Collect dungeon keys
        local remixDungeons = {}
        for id, enabled in pairs(data) do
            if id ~= "expansion" and id ~= "start_date" and id ~= "end_date" and enabled then
                    local dungeonKey = self:GetDungeonKeyById(id)
                    if dungeonKey then
                        table.insert(remixDungeons, {key = dungeonKey, id = id})
                    end
            end
        end

        -- Sort dungeons alphabetically by their localized names
        table.sort(remixDungeons, function(a, b)
            local mapIdA = a.id or self:GetDungeonIdByKey(a.key)
            local mapIdB = b.id or self:GetDungeonIdByKey(b.key)

            local nameA
            if mapIdA then nameA = select(1, C_ChallengeMode.GetMapUIInfo(mapIdA)) end
            nameA = nameA or a.key

            local nameB
            if mapIdB then nameB = select(1, C_ChallengeMode.GetMapUIInfo(mapIdB)) end
            nameB = nameB or b.key

            return nameA < nameB
        end)

        local keys = {}
        for _, d in ipairs(remixDungeons) do
                table.insert(keys, d.key)
        end

        -- Handle dates with region offset
        local eDate = data.end_date

        -- Add +1 day for non-US regions if dates are present
        local portal = C_CVar.GetCVar("portal")
        local eDateFromTable = false
        if type(eDate) == "table" then
            eDate = eDate[portal] or eDate.default or eDate.US or eDate.EU
            eDateFromTable = true
        end
        if portal ~= "US" then
            if eDate and eDate ~= "" and not eDateFromTable then
                eDate = AddDays(eDate, 1)
            end
        end

        local daysUntilEnd
        if eDate and eDate ~= "" then
            daysUntilEnd = GetDaysUntil(eDate)
            if daysUntilEnd and daysUntilEnd < 0 then
                return
            end
        end

        -- Add dates to title if available
    end

    -- Create remix season sections
    for key, data in pairs(self) do
        if type(key) == "string" and key:match("_DUNGEONS$") and type(data) == "table" and rawget(data, "expansion") then
            HandleRemixSection(key, data, args)
        end
    end

    -- Create expansion sections
    for _, expansion in ipairs(expansions) do
        local sectionKey = expansion.id:lower()
        local dungeonIds = self[expansion.id .. "_DUNGEON_IDS"]
        local defaults = self[expansion.id .. "_DEFAULTS"]
        local keys = {}
        local filter = {}
        if dungeonIds then
            for dungeonKey, _ in pairs(dungeonIds) do
                table.insert(keys, dungeonKey)
                filter[dungeonKey] = true
            end
        end

        local function getDefaultsFn(dungeonKey)
            return defaults and defaults[dungeonKey] or nil
        end

        local expansionTitle = "|cffffffff" .. L[expansion.name] .. "|r"
        args[sectionKey] = {
            name = expansionTitle,
            type = "group",
            childGroups = "tree",
            order = expansion.order + 4, -- Shift expansion orders to after next season
            args = CreateGenericSectionArgs(L[expansion.name], keys, filter, getDefaultsFn, expansionTitle)
        }
    end
    return {
        name = L["ADVANCED_SETTINGS"],
        type = "group",
        childGroups = "tree",
        order = 2,
        args = args
    }
end
