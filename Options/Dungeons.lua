local AddOnName, KeystonePolaris = ...;

local H = KeystonePolaris.OptionsHelpers
local L = H.L
local ACR = H.ACR
local CloneTable = H.CloneTable

local pairs = pairs
local select = select
local format = string.format

local expansions = KeystonePolaris.Expansions

function KeystonePolaris:CreateDungeonOptions(dungeonKey, order)
    local numBosses = #self.DUNGEONS[self:GetDungeonIdByKey(dungeonKey)]

    -- Ensure the advanced settings table exists for this dungeon
    if not self.db.profile.advanced[dungeonKey] then
        self.db.profile.advanced[dungeonKey] = {}

        -- Initialize with defaults if needed
        for _, expansion in ipairs(expansions) do
            if self[expansion.id .. "_DUNGEON_IDS"] and
                self[expansion.id .. "_DUNGEON_IDS"][dungeonKey] then
                local defaults = self[expansion.id .. "_DEFAULTS"][dungeonKey]
                if defaults then
                    for key, value in pairs(defaults) do
                        if type(value) == "table" then
                            self.db.profile.advanced[dungeonKey][key] = CloneTable(value)
                        else
                            self.db.profile.advanced[dungeonKey][key] = value
                        end
                    end
                end
                break
            end
        end
    end

    local options = {
        name = function()
            local mapId = self:GetDungeonIdByKey(dungeonKey)

            local name, texture
            if mapId then
                name = select(1, C_ChallengeMode.GetMapUIInfo(mapId))
                texture = select(4, C_ChallengeMode.GetMapUIInfo(mapId))
            end

            -- Fallback if name/texture is missing
            if not name then
                -- Try to find manual name
                for _, expansion in ipairs(expansions) do
                    local names = self[expansion.id .. "_DUNGEON_NAMES"]
                    if names and names[dungeonKey] then
                        name = names[dungeonKey]
                        break
                    end
                end
            end
            name = name or dungeonKey or "Unknown"
            texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"

            return '|T' .. texture .. ":16:16:0:0|t " .. (name)
        end,
        type = "group",
        order = order,
        args = {
            dungeonHeader = {
                order = 0,
                type = "description",
                fontSize = "large",
                name = function()
                    local mapId = self:GetDungeonIdByKey(dungeonKey)

                    local name, texture
                    if mapId then
                        name = select(1, C_ChallengeMode.GetMapUIInfo(mapId))
                        texture = select(4, C_ChallengeMode.GetMapUIInfo(mapId))
                    end

                    -- Fallback if name/texture is missing
                    if not name then
                         -- Try to find manual name
                         for _, expansion in ipairs(expansions) do
                             local names = self[expansion.id .. "_DUNGEON_NAMES"]
                             if names and names[dungeonKey] then
                                 name = names[dungeonKey]
                                 break
                             end
                         end
                    end
                    name = name or dungeonKey or "Unknown"
                    texture = texture or "Interface\\Icons\\INV_Misc_QuestionMark"

                    return "|T" .. texture .. ":20:20:0:0|t |cff40E0D0" ..
                               (name) .. "|r"
                end
            },
            dungeonSecondHeader = {type = "header", name = "", order = 1},
            reset = {
                order = 2,
                type = "execute",
                name = L["RESET_DUNGEON"],
                desc = L["RESET_DUNGEON_DESC"],
                func = function()
                    local dungeonId = self:GetDungeonIdByKey(dungeonKey)
                    if dungeonId and self.DUNGEONS[dungeonId] then
                        -- Reset all boss percentages and inform group settings for this dungeon to defaults
                        if not self.db.profile.advanced[dungeonKey] then
                            self.db.profile.advanced[dungeonKey] = {}
                        else
                            wipe(self.db.profile.advanced[dungeonKey])
                        end

                        -- Get the appropriate defaults
                        local defaults
                        for _, expansion in ipairs(expansions) do
                            if self[expansion.id .. "_DUNGEON_IDS"][dungeonKey] then
                                defaults =
                                    self[expansion.id .. "_DEFAULTS"][dungeonKey]
                                break
                            end
                        end

                        if defaults then
                            for key, value in pairs(defaults) do
                                if type(value) == "table" then
                                    self.db.profile.advanced[dungeonKey][key] = CloneTable(value)
                                else
                                    self.db.profile.advanced[dungeonKey][key] = value
                                end
                            end
                        end

                        -- Update the display
                        self:UpdateDungeonData()
                        if self.currentDungeonID and self.BuildSectionOrder then
                            self:BuildSectionOrder(self.currentDungeonID)
                        end
                        ACR:NotifyChange(AddOnName)
                        if self.UpdatePercentageText then self:UpdatePercentageText() end
                    end
                end,
                confirm = true,
                confirmText = L["RESET_DUNGEON_CONFIRM"]
            },
            export = {
                order = 3,
                type = "execute",
                name = L["EXPORT_DUNGEON"],
                desc = L["EXPORT_DUNGEON_DESC"],
                func = function()
                    local addon = KeystonePolaris
                    local dungeonId = addon:GetDungeonIdByKey(dungeonKey)
                    if dungeonId and addon.DUNGEONS[dungeonId] and
                        addon.db.profile.advanced[dungeonKey] then
                        addon:ExportDungeonSettings(
                            addon.db.profile.advanced[dungeonKey],
                            "dungeon",
                            dungeonKey
                        )
                    end
                end
            },
            import = {
                order = 3.5,
                type = "execute",
                name = L["IMPORT_DUNGEON"],
                desc = L["IMPORT_DUNGEON_DESC"],
                func = function()
                    local addon = KeystonePolaris

                    -- Create filter for this specific dungeon
                    local dungeonFilter = {}
                    dungeonFilter[dungeonKey] = true

                    local dungeonLabel = addon:GetDungeonDisplayName(dungeonKey) or dungeonKey
                    addon:ShowImportDialog(dungeonLabel, dungeonFilter)
                end
            },
            header = {order = 4, type = "header", name = L["TANK_GROUP_HEADER"]}
        }
    }

    -- Build choices for boss order selector (indexed by boss index in DUNGEONS)
    local bossChoices = {}
    for i = 1, numBosses do
        local bossName = self:GetBossName(dungeonKey, i)
        bossChoices[i] = bossName
    end

    -- Group to control logical section order (bossOrder)
    options.args.bossOrder = {
        type = "group",
        name = L["BOSS_ORDER"],
        inline = true,
        order = 4.5,
        args = {}
    }

    for section = 1, numBosses do
        options.args.bossOrder.args["section" .. section] = {
            type = "select",
            name = format(L["BOSS"] .. " %d", section),
            order = section,
            values = bossChoices,
            get = function()
                local adv = self.db.profile.advanced[dungeonKey]
                local orderTable = adv and adv.bossOrder
                local idx = orderTable and orderTable[section]
                if type(idx) ~= "number" or idx < 1 or idx > numBosses then
                    return section
                end
                return idx
            end,
            set = function(_, value)
                if not self.db.profile.advanced[dungeonKey].bossOrder then
                    self.db.profile.advanced[dungeonKey].bossOrder = {}
                end
                self.db.profile.advanced[dungeonKey].bossOrder[section] = value
                local dungeonId = self:GetDungeonIdByKey(dungeonKey)
                if dungeonId then
                    if self.BuildSectionOrder then
                        self:BuildSectionOrder(dungeonId)
                    end
                    self:UpdateDungeonData()
                    if self.UpdatePercentageText then self:UpdatePercentageText() end
                end
            end
        }
    end

    for i = 1, numBosses do
        local bossNumStr = self:GetBossNumberString(i)
        local bossName = self:GetBossName(dungeonKey, i)

        -- Create a group for each boss line
        options.args["boss" .. i] = {
            type = "group",
            name = bossName,
            inline = true,
            order = i + 4, -- Start boss orders at 5 (after header)
            args = {
                percent = {
                    name = L["PERCENTAGE"],
                    type = "range",
                    min = 0,
                    max = 100,
                    step = 0.01,
                    order = 1,
                    width = 1,
                    get = function()
                        return self.db.profile.advanced[dungeonKey]["Boss" ..
                                   bossNumStr]
                    end,
                    set = function(_, value)
                        self.db.profile.advanced[dungeonKey]["Boss" ..
                            bossNumStr] = value
                        self:UpdateDungeonData()
                    end
                },
                inform = {
                    name = L["SHOW_INFORM_GROUP_BUTTON"],
                    desc = L["SHOW_INFORM_GROUP_BUTTON_DESC"],
                    type = "toggle",
                    order = 2,
                    width = 1,
                    get = function()
                        return self.db.profile.advanced[dungeonKey]["Boss" ..
                                   bossNumStr .. "Inform"]
                    end,
                    set = function(_, value)
                        self.db.profile.advanced[dungeonKey]["Boss" ..
                            bossNumStr .. "Inform"] = value
                        self:UpdateDungeonData()
                    end
                }
            }
        }
    end
    return options
end
