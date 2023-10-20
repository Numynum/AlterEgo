AlterEgo = LibStub("AceAddon-3.0"):NewAddon("AlterEgo", "AceConsole-3.0", "AceEvent-3.0", "AceBucket-3.0")

local options = {
    name = "AlterEgo",
    handler = AlterEgo,
    type = "group",
    args = {}
}

local defaultDB = {
    global = {
        characters = {},
    },
    profile = {
        settings = {}
    }
}

local function MaxLength(str, len)
    if len == nil then
        len = 15
    end
    if string.len(str) > len then
        return str:sub(1, len) .. "..."
    end
    return str
end

local Maps = {
    [1] = {
        id = 206,
        mapId = 1458,
        name = "Neltharion's Lair",
        abbr = "NL"
    },
    [2] = {
        id = 245,
        mapId = 1754,
        name = "Freehold",
        abbr = "FH"
    },
    [3] = {
        id = 251,
        mapId = 1841,
        name = "The Underrot",
        abbr = "UR"
    },
    [4] = {
        id = 403,
        mapId = 2451,
        name = "Uldaman: Legacy of Tyr",
        abbr = "UL"
    },
    [5] = {
        id = 404,
        mapId = 2519,
        name = "Neltharus",
        abbr = "NEL"
    },
    [6] = {
        id = 405,
        mapId = 2520,
        name = "Brackenhide Hollow",
        abbr = "BH"
    },
    [7] = {
        id = 406,
        mapId = 2527,
        name = "Halls of Infusion",
        abbr = "HOI"
    },
    [8] = {
        id = 438,
        mapId = 657,
        name = "The Vortex Pinnacle",
        abbr = "VP"
    },
}

local function GetMapShortName(mapId)
    local map = "??"
    for i, mapInfo in pairs(Maps) do
        if mapInfo.mapId == mapId then
            return mapInfo.abbr
        end
    end
    return map
end

local ALTEREGO_MAX_CELL_LENGTH = 15
local rowHeight = 20
local colWidth = 120
local cellPadding = 4
local backdropinfo = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    -- edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileEdge = true,
    tileSize = 8,
    edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

function AlterEgo:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("AlterEgoDB", defaultDB)
    self:RegisterChatCommand("alterego", "OnSlashCommand")
    self:RegisterChatCommand("ae", "OnSlashCommand")
    self:RegisterBucketEvent({"BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED"}, 1, "EQUIP_CHANGED")

    C_MythicPlus.RequestMapInfo()

    self.ui = {}

    AlterEgo:UpdateCharacter()
    AlterEgo:CreateUI()
end

function AlterEgo:OnSlashCommand(message)
    if self.frame:IsVisible() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function AlterEgo:EQUIP_CHANGED()
    local playerGUID = UnitGUID("player")
    local _, avgItemLevelEquipped = GetAverageItemLevel()
    self.db.global.characters[playerGUID].ilvl = avgItemLevelEquipped

    self:UpdateUI()
end

function AlterEgo:UpdateCharacter()
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    local playerRealm = GetRealmName()
    local activities = C_WeeklyRewards.GetActivities(1)
    -- local playerRealm = GetNormalizedRealmName()
    local playerGUID = UnitGUID("player")
    local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    local keyStoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
    -- local currentWeekBestLevel, weeklyRewardLevel, nextDifficultyWeeklyRewardLevel, nextBestLevel = C_MythicPlus.GetWeeklyChestRewardLevel()
    -- local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(keyStoneLevel)
    -- local weeklyRewardAvailable = C_MythicPlus.IsWeeklyRewardAvailable()
    -- local history = C_MythicPlus.GetRunHistory(true)
    -- C_ChallengeMode.GetMapUIInfo(mapid)

    self.db.global.characters[playerGUID] = {
        name = playerName,
        realm = playerRealm,
        class = playerClass,
        rating = ratingSummary.currentSeasonScore,
        ilvl = avgItemLevelEquipped,
        vault = {},
        key = {
            map = mapID,
            level = keyStoneLevel or 0
        },
        dungeons = {}
    }

    for i, mapInfo in pairs(Maps) do
        local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapInfo.id)
        if affixScores ~= nil then
            local fortified = 0
            local tyrannical = 0
            for _, affixScore in pairs(affixScores) do
                if affixScore.name == "Fortified" then
                    fortified = affixScore.level
                end
                if affixScore.name == "Tyrannical" then
                    tyrannical = affixScore.level
                end
            end

            self.db.global.characters[playerGUID].dungeons[mapInfo.id] = {
                [1] = tyrannical,
                [2] = fortified,
            }
        else
            self.db.global.characters[playerGUID].dungeons[mapInfo.id] = {
                [1] = 0,
                [2] = 0,
            }
        end
    end

    for _, activity in pairs(activities) do
        self.db.global.characters[playerGUID].vault[activity.index] = activity.level
    end
end

function AlterEgo:GetCharacters()
    local characters = self.db.global.characters

    -- Filters
    -- Sorting

    return characters
end

local UIData = {
    [1] = {
        name = "Name",
        label = "Characters:",
        value = function(self, character)
            local characterColor = "|cffffffff"
            if character.class ~= nil then
                local classColor = C_ClassColor.GetClassColor(character.class)
                if classColor ~= nil then
                    characterColor = "|c" .. classColor.GenerateHexColor(classColor)
                end
            end
            return characterColor .. MaxLength(character.name) .. "|r"
        end
    },
    [2] = {
        name = "Realm",
        label = "Realm:",
        value = function(self, character)
            return MaxLength(character.realm)
        end
    },
    [3] = {
        name = "Rating",
        label = "Rating:",
        value = function(self, character)
            local ratingColor = "|cffffffff"
            if character.rating > 0 then
                local color = C_ChallengeMode.GetDungeonScoreRarityColor(character.rating)
                if color ~= nil then
                    ratingColor = "|c" .. color.GenerateHexColor(color)
                end
            end
            return ratingColor .. character.rating .. "|r"
        end
    },
    [4] = {
        name = "ItemLevel",
        label = "Item Level:",
        value = function(self, character)
            local r, g, b = GetItemLevelColor()
            local itemLevelColorHex = "|cffffffff"
            if r ~= nil then
                local color = CreateColor(r, g, b, 1)
                itemLevelColorHex = "|c" .. color:GenerateHexColor()
            end
            return itemLevelColorHex .. floor(character.ilvl) .. "|r"
        end
    },
    [5] = {
        name = "Vault1",
        label = "Vault 1:",
        value = function(self, character)
            if character.vault[1] == 0 then
                return "-"
            end
            return character.vault[1]
        end
    },
    [6] = {
        name = "Vault2",
        label = "Vault 2:",
        value = function(self, character)
            if character.vault[2] == 0 then
                return "-"
            end
            return character.vault[2]
        end
    },
    [7] = {
        name = "Vault3",
        label = "Vault 3:",
        value = function(self, character)
            if character.vault[3] == 0 then
                return "-"
            end
            return character.vault[3]
        end
    },
    [8] = {
        name = "CurrentKey",
        label = "Current Key:",
        value = function(self, character)
            if character.key.map == nil or character.key.map == "" then
                return "-"
            end
            return GetMapShortName(character.key.map) .. " " .. character.key.level
        end
    },
}

function AlterEgo:CreateUI()
    local characters = AlterEgo:GetCharacters()

    self.tableFrame = CreateFrame("Frame", "AlterEgoFrame", UIParent, "BackdropTemplate")
    self.tableFrame:SetPoint("CENTER")
    self.tableFrame:SetSize(0, 0)
    self.tableFrame:SetBackdrop(backdropinfo)
    self.tableFrame:SetBackdropColor(0, 0, 0, 1)

    local rowIndex = 0

    -- Character loop
    for i, row in ipairs(UIData) do
        local characterRowFrame = self.tableFrame:GetName() .. "ROW" .. rowIndex
        self.tableFrame[characterRowFrame] = CreateFrame("Frame", characterRowFrame, self.tableFrame, "BackdropTemplate")
        self.tableFrame[characterRowFrame]:SetPoint("TOPLEFT", self.tableFrame, "TOPLEFT", 0, -rowHeight * rowIndex)
        self.tableFrame[characterRowFrame]:SetSize(self.tableFrame:GetWidth(), rowHeight)

        local characterCellName = characterRowFrame .. "CELL0"
        self.tableFrame[characterCellName] = CreateFrame("Frame", characterCellName, self.tableFrame[characterRowFrame], "BackdropTemplate")
        self.tableFrame[characterCellName]:SetSize(colWidth, rowHeight)
        self.tableFrame[characterCellName]:SetPoint("TOPLEFT", self.tableFrame[characterRowFrame], "TOPLEFT")
        self.tableFrame[characterCellName]:SetBackdrop(backdropinfo)
        self.tableFrame[characterCellName]:SetBackdropColor(0, 0, 0, 0)
        self.tableFrame[characterCellName].fontString = self.tableFrame[characterCellName]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.tableFrame[characterCellName].fontString:SetPoint("LEFT", self.tableFrame[characterCellName], "LEFT", cellPadding, 0)
        -- self.tableFrame[characterCellName].fontString:SetText(MaxLength(row.label))
        self.tableFrame[characterCellName].fontString:SetJustifyH("LEFT")

        local lastCellFrame = self.tableFrame[characterCellName]
        local columnIndex = 1
        for _, character in pairs(characters) do
            characterCellName = characterRowFrame .. "CELL" .. columnIndex
            self.tableFrame[characterCellName] = CreateFrame("Frame", characterCellName, lastCellFrame, "BackdropTemplate")
            self.tableFrame[characterCellName]:SetSize(colWidth, rowHeight)
            self.tableFrame[characterCellName]:SetPoint("TOPLEFT", lastCellFrame, "TOPRIGHT")
            self.tableFrame[characterCellName]:SetBackdrop(backdropinfo)
            self.tableFrame[characterCellName]:SetBackdropColor(0, 0, 0, 0)
            self.tableFrame[characterCellName].fontString = self.tableFrame[characterCellName]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.tableFrame[characterCellName].fontString:SetPoint("CENTER", self.tableFrame[characterCellName], "CENTER", cellPadding, 0)
            -- self.tableFrame[characterCellName].fontString:SetText(row:value(character))
            self.tableFrame[characterCellName].fontString:SetJustifyH("CENTER")
            lastCellFrame = self.tableFrame[characterCellName]
            columnIndex = columnIndex + 1
        end

        rowIndex = rowIndex + 1
    end

    -- Dungeon Header
    local dungeonHeaderRowName = self.tableFrame:GetName() .. "DUNGEONHEADERROW"
    self.tableFrame[dungeonHeaderRowName] = CreateFrame("Frame", dungeonHeaderRowName, self.tableFrame, "BackdropTemplate")
    self.tableFrame[dungeonHeaderRowName]:SetPoint("TOPLEFT", self.tableFrame, "TOPLEFT", 0, -rowHeight * rowIndex)
    self.tableFrame[dungeonHeaderRowName]:SetSize(self.tableFrame:GetWidth(), rowHeight)

    local dungeonHeaderCellName = dungeonHeaderRowName .. "CELL0"
    self.tableFrame[dungeonHeaderCellName] = CreateFrame("Frame", dungeonHeaderCellName, self.tableFrame[dungeonHeaderRowName], "BackdropTemplate")
    self.tableFrame[dungeonHeaderCellName]:SetSize(colWidth, rowHeight)
    self.tableFrame[dungeonHeaderCellName]:SetPoint("TOPLEFT", self.tableFrame[dungeonHeaderRowName], "TOPLEFT")
    self.tableFrame[dungeonHeaderCellName]:SetBackdrop(backdropinfo)
    self.tableFrame[dungeonHeaderCellName]:SetBackdropColor(0, 0, 0, 0)
    self.tableFrame[dungeonHeaderCellName].fontString = self.tableFrame[dungeonHeaderCellName]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.tableFrame[dungeonHeaderCellName].fontString:SetPoint("LEFT", self.tableFrame[dungeonHeaderCellName], "LEFT", cellPadding, 0)
    self.tableFrame[dungeonHeaderCellName].fontString:SetText("Dungeons:")
    self.tableFrame[dungeonHeaderCellName].fontString:SetJustifyH("LEFT")

    local lastCellFrame = self.tableFrame[dungeonHeaderCellName]
    local columnIndex = 1
    for _, character in pairs(characters) do
        for affixIndex = 1, 2 do
            dungeonHeaderCellName = dungeonHeaderRowName .. "CELL" .. columnIndex
            self.tableFrame[dungeonHeaderCellName] = CreateFrame("Frame",  dungeonHeaderCellName, lastCellFrame, "BackdropTemplate")
            self.tableFrame[dungeonHeaderCellName]:SetSize(colWidth / 2, rowHeight)
            self.tableFrame[dungeonHeaderCellName]:SetPoint("TOPLEFT", lastCellFrame, "TOPRIGHT")
            self.tableFrame[dungeonHeaderCellName]:SetBackdrop(backdropinfo)
            self.tableFrame[dungeonHeaderCellName]:SetBackdropColor(0, 0, 0, 0)
            self.tableFrame[dungeonHeaderCellName].fontString = self.tableFrame[dungeonHeaderCellName]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.tableFrame[dungeonHeaderCellName].fontString:SetPoint("CENTER", self.tableFrame[dungeonHeaderCellName], "CENTER", cellPadding, 0)
            self.tableFrame[dungeonHeaderCellName].fontString:SetText("AFFIX")
            self.tableFrame[dungeonHeaderCellName].fontString:SetJustifyH("CENTER")
            lastCellFrame = self.tableFrame[dungeonHeaderCellName]
            columnIndex = columnIndex + 1
        end
    end

    rowIndex = rowIndex + 1

    -- Dungeon Loop
    for i, map in ipairs(Maps) do
        local dungeonRowFrame = self.tableFrame:GetName() .. "ROW" .. rowIndex
        self.tableFrame[dungeonRowFrame] = CreateFrame("Frame", dungeonRowFrame, self.tableFrame, "BackdropTemplate")
        self.tableFrame[dungeonRowFrame]:SetPoint("TOPLEFT", self.tableFrame, "TOPLEFT", 0, -rowHeight * rowIndex)
        self.tableFrame[dungeonRowFrame]:SetSize(self.tableFrame:GetWidth(), rowHeight)

        local dungeonHeaderFrame = dungeonRowFrame .. "CELL0"
        self.tableFrame[dungeonHeaderFrame] = CreateFrame("Frame", dungeonHeaderFrame, self.tableFrame[dungeonRowFrame], "BackdropTemplate")
        self.tableFrame[dungeonHeaderFrame]:SetSize(colWidth, rowHeight)
        self.tableFrame[dungeonHeaderFrame]:SetPoint("TOPLEFT", self.tableFrame[dungeonRowFrame], "TOPLEFT")
        self.tableFrame[dungeonHeaderFrame]:SetBackdrop(backdropinfo)
        self.tableFrame[dungeonHeaderFrame]:SetBackdropColor(0, 0, 0, 0)
        self.tableFrame[dungeonHeaderFrame].fontString = self.tableFrame[dungeonHeaderFrame]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.tableFrame[dungeonHeaderFrame].fontString:SetPoint("LEFT", self.tableFrame[dungeonHeaderFrame], "LEFT", cellPadding, 0)
        -- self.tableFrame[dungeonHeaderFrame].fontString:SetText(MaxLength(map.name))
        self.tableFrame[dungeonHeaderFrame].fontString:SetJustifyH("LEFT")

        local lastCellFrame = self.tableFrame[dungeonHeaderFrame]
        local columnIndex = 1
        for _, character in pairs(characters) do
            for affixIndex = 1, 2 do
                -- local level = character.dungeons[map.id][affixIndex]
                -- if level == 0 then
                --     level = "-"
                -- end
                local dungeonCellFrame = dungeonRowFrame .. "CELL" .. columnIndex
                self.tableFrame[dungeonCellFrame] = CreateFrame("Frame", dungeonCellFrame, lastCellFrame, "BackdropTemplate")
                self.tableFrame[dungeonCellFrame]:SetSize(colWidth / 2, rowHeight)
                self.tableFrame[dungeonCellFrame]:SetPoint("TOPLEFT", lastCellFrame, "TOPRIGHT")
                self.tableFrame[dungeonCellFrame]:SetBackdrop(backdropinfo)
                self.tableFrame[dungeonCellFrame]:SetBackdropColor(0, 0, 0, 0)
                self.tableFrame[dungeonCellFrame].fontString = self.tableFrame[dungeonCellFrame]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                self.tableFrame[dungeonCellFrame].fontString:SetPoint("CENTER", self.tableFrame[dungeonCellFrame], "CENTER", cellPadding, 0)
                -- self.tableFrame[dungeonCellFrame].fontString:SetText(level)
                self.tableFrame[dungeonCellFrame].fontString:SetJustifyH("CENTER")
                lastCellFrame = self.tableFrame[dungeonCellFrame]
                columnIndex = columnIndex + 1
            end
        end

        rowIndex = rowIndex + 1
    end


    -- self.frame = CreateFrame("Frame", "AlterEgoFrame", UIParent, "BackdropTemplate")
    -- self.frame:Hide()
    -- self.frame:SetPoint("CENTER")
    -- self.frame:SetSize(600, 600)
    -- self.frame:SetBackdrop(backdropinfo)
    -- self.frame:SetBackdropColor(0, 0, 0, 1)
    
    -- local rowCharacterName = CreateFrame("Frame", self.frame:GetName() .. "HeaderRow", self.frame, "BackdropTemplate")
    -- rowCharacterName:SetSize(self.frame:GetWidth(), rowHeight)
    -- rowCharacterName:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
    -- rowCharacterName.columns = {}
    -- rowCharacterName.columns[0] = CreateFrame("Frame", rowCharacterName:GetName() .. "COL0", rowCharacterName, "BackdropTemplate")
    -- rowCharacterName.columns[0]:SetSize(colWidth, rowHeight)
    -- rowCharacterName.columns[0]:SetPoint("TOPLEFT", rowCharacterName, "TOPLEFT")
    -- rowCharacterName.columns[0]:SetBackdrop(backdropinfo)
    -- rowCharacterName.columns[0]:SetBackdropColor(0, 0, 0, 0)
    -- rowCharacterName.columns[0].fontString = rowCharacterName.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- rowCharacterName.columns[0].fontString:SetPoint("LEFT", rowCharacterName.columns[0], "LEFT", cellPadding, 0)
    -- rowCharacterName.columns[0].fontString:SetText("Characters:")
    -- rowCharacterName.columns[0].fontString:SetJustifyH("LEFT")
    
    -- local previousFrame = 0
    -- for playerGUID,character in pairs(characters) do

    --     local characterColor = "|cffffffff"
    --     if character.class ~= nil then
    --         local classColor = C_ClassColor.GetClassColor(character.class)
    --         if classColor ~= nil then
    --             characterColor = "|c" .. classColor.GenerateHexColor(classColor)
    --         end
    --     end

    --     rowCharacterName.columns[playerGUID] = CreateFrame("Frame", rowCharacterName:GetName() .. "COL" .. playerGUID, rowCharacterName, "BackdropTemplate")
    --     rowCharacterName.columns[playerGUID]:SetSize(colWidth, rowHeight)
    --     rowCharacterName.columns[playerGUID]:SetPoint("TOPLEFT", rowCharacterName.columns[previousFrame], "TOPRIGHT")
    --     rowCharacterName.columns[playerGUID]:SetBackdrop(backdropinfo)
    --     rowCharacterName.columns[playerGUID]:SetBackdropColor(0, 0, 0, 0)
    --     rowCharacterName.columns[playerGUID].fontString = rowCharacterName.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowCharacterName.columns[playerGUID].fontString:SetPoint("CENTER", rowCharacterName.columns[playerGUID], "CENTER", cellPadding, 0)
    --     rowCharacterName.columns[playerGUID].fontString:SetJustifyH("CENTER")
    --     rowCharacterName.columns[playerGUID].fontString:SetText(characterColor .. character.name .. "|r")
    --     previousFrame = playerGUID
    -- end

    -- local rowRealmName = CreateFrame("Frame", self.frame:GetName() .. "RowRealm", self.frame, "BackdropTemplate")
    -- rowRealmName:SetSize(self.frame:GetWidth(), rowHeight)
    -- rowRealmName:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight)
    -- rowRealmName.columns = {}
    -- rowRealmName.columns[0] = CreateFrame("Frame", rowRealmName:GetName() .. "COL0", rowRealmName, "BackdropTemplate")
    -- rowRealmName.columns[0]:SetSize(colWidth, rowHeight)
    -- rowRealmName.columns[0]:SetPoint("TOPLEFT", rowRealmName, "TOPLEFT")
    -- rowRealmName.columns[0]:SetBackdrop(backdropinfo)
    -- rowRealmName.columns[0]:SetBackdropColor(0, 0, 0, 0)
    -- rowRealmName.columns[0].fontString = rowRealmName.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- rowRealmName.columns[0].fontString:SetPoint("LEFT", rowRealmName.columns[0], "LEFT", cellPadding, 0)
    -- rowRealmName.columns[0].fontString:SetText("Realm:")
    -- rowRealmName.columns[0].fontString:SetJustifyH("LEFT")

    -- local previousFrame = 0
    -- for playerGUID,character in pairs(characters) do
    --     rowRealmName.columns[playerGUID] = CreateFrame("Frame", rowRealmName:GetName() .. "COL" .. playerGUID, rowRealmName, "BackdropTemplate")
    --     rowRealmName.columns[playerGUID]:SetSize(colWidth, rowHeight)
    --     rowRealmName.columns[playerGUID]:SetPoint("TOPLEFT", rowRealmName.columns[previousFrame], "TOPRIGHT")
    --     rowRealmName.columns[playerGUID]:SetBackdrop(backdropinfo)
    --     rowRealmName.columns[playerGUID]:SetBackdropColor(0, 0, 0, 0)
    --     rowRealmName.columns[playerGUID].fontString = rowRealmName.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowRealmName.columns[playerGUID].fontString:SetPoint("CENTER", rowRealmName.columns[playerGUID], "CENTER", cellPadding, 0)
    --     rowRealmName.columns[playerGUID].fontString:SetJustifyH("CENTER")
    --     rowRealmName.columns[playerGUID].fontString:SetText((character.realm or ""))
    --     previousFrame = playerGUID
    -- end

    -- local rowRating = CreateFrame("Frame", self.frame:GetName() .. "Rating", self.frame, "BackdropTemplate")
    -- rowRating:SetSize(self.frame:GetWidth(), rowHeight)
    -- rowRating:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight * 2)
    -- rowRating.columns = {}
    -- rowRating.columns[0] = CreateFrame("Frame", rowRating:GetName() .. "COL0", rowRating, "BackdropTemplate")
    -- rowRating.columns[0]:SetSize(colWidth, rowHeight)
    -- rowRating.columns[0]:SetPoint("TOPLEFT", rowRating, "TOPLEFT")
    -- rowRating.columns[0]:SetBackdrop(backdropinfo)
    -- rowRating.columns[0]:SetBackdropColor(0, 0, 0, 0)
    -- rowRating.columns[0].fontString = rowRating.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- rowRating.columns[0].fontString:SetPoint("LEFT", rowRating.columns[0], "LEFT", cellPadding, 0)
    -- rowRating.columns[0].fontString:SetJustifyH("LEFT")
    -- rowRating.columns[0].fontString:SetText("Rating:")

    -- local previousFrame = 0
    -- for playerGUID,character in pairs(characters) do

    --     local ratingColor = "|cffffffff"
    --     if character.rating > 0 then
    --         local color = C_ChallengeMode.GetDungeonScoreRarityColor(character.rating)
    --         if color ~= nil then
    --             ratingColor = "|c" .. color.GenerateHexColor(color)
    --         end
    --     end
    --     rowRating.columns[playerGUID] = CreateFrame("Frame", rowRating:GetName() .. "COL" .. playerGUID, rowRating, "BackdropTemplate")
    --     rowRating.columns[playerGUID]:SetSize(colWidth, rowHeight)
    --     rowRating.columns[playerGUID]:SetPoint("TOPLEFT", rowRating.columns[previousFrame], "TOPRIGHT")
    --     rowRating.columns[playerGUID]:SetBackdrop(backdropinfo)
    --     rowRating.columns[playerGUID]:SetBackdropColor(0, 0, 0, 0)
    --     rowRating.columns[playerGUID].fontString = rowRating.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowRating.columns[playerGUID].fontString:SetPoint("CENTER", rowRating.columns[playerGUID], "CENTER", cellPadding, 0)
    --     rowRating.columns[playerGUID].fontString:SetJustifyH("CENTER")
    --     rowRating.columns[playerGUID].fontString:SetText(ratingColor .. character.rating .. "|r")
    --     previousFrame = playerGUID
    -- end

    -- local rowItemLevel = CreateFrame("Frame", self.frame:GetName() .. "ItemLevel", self.frame, "BackdropTemplate")
    -- rowItemLevel:SetSize(self.frame:GetWidth(), rowHeight)
    -- rowItemLevel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight * 3)
    -- rowItemLevel.columns = {}
    -- rowItemLevel.columns[0] = CreateFrame("Frame", rowItemLevel:GetName() .. "COL0", rowItemLevel, "BackdropTemplate")
    -- rowItemLevel.columns[0]:SetSize(colWidth, rowHeight)
    -- rowItemLevel.columns[0]:SetPoint("TOPLEFT", rowItemLevel, "TOPLEFT")
    -- rowItemLevel.columns[0]:SetBackdrop(backdropinfo)
    -- rowItemLevel.columns[0]:SetBackdropColor(0, 0, 0, 0)
    -- rowItemLevel.columns[0].fontString = rowItemLevel.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- rowItemLevel.columns[0].fontString:SetPoint("LEFT", rowItemLevel.columns[0], "LEFT", cellPadding, 0)
    -- rowItemLevel.columns[0].fontString:SetJustifyH("LEFT")
    -- rowItemLevel.columns[0].fontString:SetText("Item Level:")

    -- local previousFrame = 0
    -- for playerGUID,character in pairs(characters) do
    --     rowItemLevel.columns[playerGUID] = CreateFrame("Frame", rowItemLevel:GetName() .. "COL" .. playerGUID, rowItemLevel, "BackdropTemplate")
    --     rowItemLevel.columns[playerGUID]:SetSize(colWidth, rowHeight)
    --     rowItemLevel.columns[playerGUID]:SetPoint("TOPLEFT", rowItemLevel.columns[previousFrame], "TOPRIGHT")
    --     rowItemLevel.columns[playerGUID]:SetBackdrop(backdropinfo)
    --     rowItemLevel.columns[playerGUID]:SetBackdropColor(0, 0, 0, 0)
    --     rowItemLevel.columns[playerGUID].fontString = rowItemLevel.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowItemLevel.columns[playerGUID].fontString:SetPoint("CENTER", rowItemLevel.columns[playerGUID], "CENTER", cellPadding, 0)
    --     rowItemLevel.columns[playerGUID].fontString:SetJustifyH("CENTER")
    --     rowItemLevel.columns[playerGUID].fontString:SetText(math.floor(character.ilvl))
    --     previousFrame = playerGUID
    -- end

    -- for i = 1, 3 do
    --     local rowVault = CreateFrame("Frame", self.frame:GetName() .. "Vault" .. i, self.frame, "BackdropTemplate")
    --     rowVault:SetSize(self.frame:GetWidth(), rowHeight)
    --     rowVault:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight * (3 + i))
    --     rowVault.columns = {}
    --     rowVault.columns[0] = CreateFrame("Frame", rowVault:GetName() .. "COL0", rowVault, "BackdropTemplate")
    --     rowVault.columns[0]:SetSize(colWidth, rowHeight)
    --     rowVault.columns[0]:SetPoint("TOPLEFT", rowVault, "TOPLEFT")
    --     rowVault.columns[0]:SetBackdrop(backdropinfo)
    --     rowVault.columns[0]:SetBackdropColor(0, 0, 0, 0)
    --     rowVault.columns[0].fontString = rowVault.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowVault.columns[0].fontString:SetPoint("LEFT", rowVault.columns[0], "LEFT", cellPadding, 0)
    --     rowVault.columns[0].fontString:SetJustifyH("LEFT")
    --     rowVault.columns[0].fontString:SetText("Vault " .. i .. ":")
    
    --     local previousFrame = 0
    --     for playerGUID,character in pairs(characters) do
    --         rowVault.columns[playerGUID] = CreateFrame("Frame", rowVault:GetName() .. "COL" .. playerGUID, rowVault, "BackdropTemplate")
    --         rowVault.columns[playerGUID]:SetSize(colWidth, rowHeight)
    --         rowVault.columns[playerGUID]:SetPoint("TOPLEFT", rowVault.columns[previousFrame], "TOPRIGHT")
    --         rowVault.columns[playerGUID]:SetBackdrop(backdropinfo)
    --         rowVault.columns[playerGUID]:SetBackdropColor(0, 0, 0, 0)
    --         rowVault.columns[playerGUID].fontString = rowVault.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --         rowVault.columns[playerGUID].fontString:SetPoint("CENTER", rowVault.columns[playerGUID], "CENTER", cellPadding, 0)
    --         rowVault.columns[playerGUID].fontString:SetJustifyH("CENTER")
    --         if character.vault[i] == 0 then
    --             rowVault.columns[playerGUID].fontString:SetText("-")
    --         else
    --             rowVault.columns[playerGUID].fontString:SetText(character.vault[i])
    --         end
    --         previousFrame = playerGUID
    --     end
    -- end

    
    -- local rowCurrentKey = CreateFrame("Frame", self.frame:GetName() .. "CurrentKey", self.frame, "BackdropTemplate")
    -- rowCurrentKey:SetSize(self.frame:GetWidth(), rowHeight)
    -- rowCurrentKey:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight * 7)
    -- rowCurrentKey.columns = {}
    -- rowCurrentKey.columns[0] = CreateFrame("Frame", rowCurrentKey:GetName() .. "COL0", rowCurrentKey, "BackdropTemplate")
    -- rowCurrentKey.columns[0]:SetSize(colWidth, rowHeight)
    -- rowCurrentKey.columns[0]:SetPoint("TOPLEFT", rowCurrentKey, "TOPLEFT")
    -- rowCurrentKey.columns[0]:SetBackdrop(backdropinfo)
    -- rowCurrentKey.columns[0]:SetBackdropColor(0, 0, 0, 0)
    -- rowCurrentKey.columns[0].fontString = rowCurrentKey.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- rowCurrentKey.columns[0].fontString:SetPoint("LEFT", rowCurrentKey.columns[0], "LEFT", cellPadding, 0)
    -- rowCurrentKey.columns[0].fontString:SetJustifyH("LEFT")
    -- rowCurrentKey.columns[0].fontString:SetText("Current Key:")

    -- local previousFrame = 0
    -- for playerGUID,character in pairs(characters) do
    --     rowCurrentKey.columns[playerGUID] = CreateFrame("Frame", rowCurrentKey:GetName() .. "COL" .. playerGUID, rowCurrentKey, "BackdropTemplate")
    --     rowCurrentKey.columns[playerGUID]:SetSize(colWidth, rowHeight)
    --     rowCurrentKey.columns[playerGUID]:SetPoint("TOPLEFT", rowCurrentKey.columns[previousFrame], "TOPRIGHT")
    --     rowCurrentKey.columns[playerGUID]:SetBackdrop(backdropinfo)
    --     rowCurrentKey.columns[playerGUID]:SetBackdropColor(0, 0, 0, 0)
    --     rowCurrentKey.columns[playerGUID].fontString = rowCurrentKey.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowCurrentKey.columns[playerGUID].fontString:SetPoint("CENTER", rowCurrentKey.columns[playerGUID], "CENTER", cellPadding, 0)
    --     rowCurrentKey.columns[playerGUID].fontString:SetJustifyH("CENTER")
    --     if character.key.map == nil or character.key.map == "" then
    --         rowCurrentKey.columns[playerGUID].fontString:SetText("-")
    --     else
    --         rowCurrentKey.columns[playerGUID].fontString:SetText(GetMapShortName(character.key.map) .. " " .. character.key.level)
    --     end
    --     previousFrame = playerGUID
    -- end
    
    -- self.frame.rowDungeonHeader = CreateFrame("Frame", self.frame:GetName() .. "DungeonHeader", self.frame, "BackdropTemplate")
    -- self.frame.rowDungeonHeader:SetSize(self.frame:GetWidth(), rowHeight)
    -- self.frame.rowDungeonHeader:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight * 8)
    -- self.frame.rowDungeonHeader:SetBackdrop(backdropinfo)
    -- self.frame.rowDungeonHeader:SetBackdropColor(0.2, 0.2, 0.2, 1)
    -- self.frame.rowDungeonHeader.columns = {}
    -- self.frame.rowDungeonHeader.columns[0] = CreateFrame("Frame", self.frame.rowDungeonHeader:GetName() .. "COL0", self.frame.rowDungeonHeader, "BackdropTemplate")
    -- self.frame.rowDungeonHeader.columns[0]:SetSize(colWidth, rowHeight)
    -- self.frame.rowDungeonHeader.columns[0]:SetPoint("TOPLEFT", self.frame.rowDungeonHeader, "TOPLEFT")
    -- self.frame.rowDungeonHeader.columns[0]:SetBackdrop(backdropinfo)
    -- self.frame.rowDungeonHeader.columns[0]:SetBackdropColor(0, 0, 0, 0)
    -- self.frame.rowDungeonHeader.columns[0].fontString = self.frame.rowDungeonHeader.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- self.frame.rowDungeonHeader.columns[0].fontString:SetPoint("LEFT", self.frame.rowDungeonHeader.columns[0], "LEFT", cellPadding, 0)
    -- self.frame.rowDungeonHeader.columns[0].fontString:SetJustifyH("LEFT")
    -- self.frame.rowDungeonHeader.columns[0].fontString:SetText("Dungeons:")

    -- local previousFrame = 0
    -- for playerGUID,character in pairs(characters) do
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"] = CreateFrame("Frame", self.frame.rowDungeonHeader:GetName() .. "COL" .. playerGUID .. "F", self.frame.rowDungeonHeader, "BackdropTemplate")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"]:SetSize(colWidth / 2, rowHeight)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"]:SetPoint("TOPLEFT", self.frame.rowDungeonHeader.columns[previousFrame], "TOPRIGHT")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"]:SetBackdrop(backdropinfo)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"]:SetBackdropColor(0, 0, 0, 0)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"].fontString = self.frame.rowDungeonHeader.columns[playerGUID .. "F"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"].fontString:SetPoint("CENTER", self.frame.rowDungeonHeader.columns[playerGUID .. "F"], "CENTER", cellPadding, 0)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"].fontString:SetJustifyH("CENTER")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "F"].fontString:SetText("F")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"] = CreateFrame("Frame", self.frame.rowDungeonHeader:GetName() .. "COL" .. playerGUID .. "T", self.frame.rowDungeonHeader, "BackdropTemplate")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"]:SetSize(colWidth / 2, rowHeight)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"]:SetPoint("TOPLEFT", self.frame.rowDungeonHeader.columns[playerGUID .. "F"], "TOPRIGHT")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"]:SetBackdrop(backdropinfo)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"]:SetBackdropColor(0, 0, 0, 0)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"].fontString = self.frame.rowDungeonHeader.columns[playerGUID .. "T"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"].fontString:SetPoint("CENTER", self.frame.rowDungeonHeader.columns[playerGUID .. "T"], "CENTER", cellPadding, 0)
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"].fontString:SetJustifyH("CENTER")
    --     self.frame.rowDungeonHeader.columns[playerGUID .. "T"].fontString:SetText("T")
    --     previousFrame = playerGUID .. "T"
    -- end

    -- for i, mapInfo in pairs(Maps) do
    --     local rowDungeon = CreateFrame("Frame", self.frame:GetName() .. "Dungeon" .. i, self.frame, "BackdropTemplate")
    --     rowDungeon:SetSize(self.frame:GetWidth(), rowHeight)
    --     rowDungeon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -rowHeight * (8 + i))
    --     rowDungeon.columns = {}
    --     rowDungeon.columns[0] = CreateFrame("Frame", rowDungeon:GetName() .. "COL0", rowDungeon, "BackdropTemplate")
    --     rowDungeon.columns[0]:SetSize(colWidth, rowHeight)
    --     rowDungeon.columns[0]:SetPoint("TOPLEFT", rowDungeon, "TOPLEFT")
    --     rowDungeon.columns[0]:SetBackdrop(backdropinfo)
    --     if i % 2 == 0 then
    --         rowDungeon.columns[0]:SetBackdropColor(1, 1, 1, 0.1)
    --     else
    --         rowDungeon.columns[0]:SetBackdropColor(0, 0, 0, 0)
    --     end
    --     rowDungeon.columns[0].fontString = rowDungeon.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --     rowDungeon.columns[0].fontString:SetPoint("LEFT", rowDungeon.columns[0], "LEFT", cellPadding, 0)
    --     rowDungeon.columns[0].fontString:SetWidth(colWidth - cellPadding * 2)
    --     rowDungeon.columns[0].fontString:SetJustifyH("LEFT")
    --     rowDungeon.columns[0].fontString:SetText(MaxLength(mapInfo.name, 13))

    --     local previousFrame = 0
    --     for playerGUID,character in pairs(characters) do
    --         rowDungeon.columns[playerGUID .. "F"] = CreateFrame("Frame", rowDungeon:GetName() .. "COL" .. playerGUID .. "F", rowDungeon, "BackdropTemplate")
    --         rowDungeon.columns[playerGUID .. "F"]:SetSize(colWidth / 2, rowHeight)
    --         rowDungeon.columns[playerGUID .. "F"]:SetPoint("TOPLEFT", rowDungeon.columns[previousFrame], "TOPRIGHT")
    --         rowDungeon.columns[playerGUID .. "F"]:SetBackdrop(backdropinfo)
    --         if i % 2 == 0 then
    --             rowDungeon.columns[playerGUID .. "F"]:SetBackdropColor(1, 1, 1, 0.1)
    --         else
    --             rowDungeon.columns[playerGUID .. "F"]:SetBackdropColor(0, 0, 0, 0)
    --         end
    --         rowDungeon.columns[playerGUID .. "F"].fontString = rowDungeon.columns[playerGUID .. "F"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --         rowDungeon.columns[playerGUID .. "F"].fontString:SetPoint("CENTER", rowDungeon.columns[playerGUID .. "F"], "CENTER", cellPadding, 0)
    --         rowDungeon.columns[playerGUID .. "F"].fontString:SetJustifyH("CENTER")
    --         local level = character.dungeons[mapInfo.id][2]
    --         if level == 0 then
    --             level = "-"
    --         end
    --         rowDungeon.columns[playerGUID .. "F"].fontString:SetText(level)
    --         rowDungeon.columns[playerGUID .. "T"] = CreateFrame("Frame", rowDungeon:GetName() .. "COL" .. playerGUID .. "T", rowDungeon, "BackdropTemplate")
    --         rowDungeon.columns[playerGUID .. "T"]:SetSize(colWidth / 2, rowHeight)
    --         rowDungeon.columns[playerGUID .. "T"]:SetPoint("TOPLEFT", rowDungeon.columns[playerGUID .. "F"], "TOPRIGHT")
    --         rowDungeon.columns[playerGUID .. "T"]:SetBackdrop(backdropinfo)
    --         if i % 2 == 0 then
    --             rowDungeon.columns[playerGUID .. "T"]:SetBackdropColor(1, 1, 1, 0.1)
    --         else
    --             rowDungeon.columns[playerGUID .. "T"]:SetBackdropColor(0, 0, 0, 0)
    --         end
    --         rowDungeon.columns[playerGUID .. "T"].fontString = rowDungeon.columns[playerGUID .. "T"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    --         rowDungeon.columns[playerGUID .. "T"].fontString:SetPoint("CENTER", rowDungeon.columns[playerGUID .. "T"], "CENTER", cellPadding, 0)
    --         rowDungeon.columns[playerGUID .. "T"].fontString:SetJustifyH("CENTER")
    --         local level = character.dungeons[mapInfo.id][1]
    --         if level == 0 then
    --             level = "-"
    --         end
    --         rowDungeon.columns[playerGUID .. "T"].fontString:SetText(level)
    --         previousFrame = playerGUID .. "T"
    --     end
    -- end
    

    AlterEgo:UpdateUI()
end

function AlterEgo:UpdateUI()
    local characters = AlterEgo:GetCharacters()

    local frameWidth = colWidth

    for _, __ in pairs(characters) do
        frameWidth = frameWidth + colWidth
    end

    local rowIndex = 0

    -- Character loop
    for i, row in ipairs(UIData) do
        local characterRowFrame = self.tableFrame:GetName() .. "ROW" .. rowIndex
        self.tableFrame[characterRowFrame]:SetSize(frameWidth, rowHeight)
        local characterCellName = characterRowFrame .. "CELL0"
        self.tableFrame[characterCellName]:SetSize(colWidth, rowHeight)
        self.tableFrame[characterCellName].fontString:SetText(MaxLength(row.label))

        local columnIndex = 1
        for _, character in pairs(characters) do
            characterCellName = characterRowFrame .. "CELL" .. columnIndex
            self.tableFrame[characterCellName]:SetSize(colWidth, rowHeight)
            self.tableFrame[characterCellName].fontString:SetText(row:value(character))
            columnIndex = columnIndex + 1
        end

        rowIndex = rowIndex + 1
    end

    -- Dungeon Header
    local dungeonHeaderRowName = self.tableFrame:GetName() .. "DUNGEONHEADERROW"
    self.tableFrame[dungeonHeaderRowName]:SetSize(frameWidth, rowHeight)
    rowIndex = rowIndex + 1

    -- Dungeon Loop
    for i, map in ipairs(Maps) do
        local dungeonRowFrame = self.tableFrame:GetName() .. "ROW" .. rowIndex
        self.tableFrame[dungeonRowFrame]:SetSize(frameWidth, rowHeight)

        local dungeonHeaderFrame = dungeonRowFrame .. "CELL0"
        self.tableFrame[dungeonHeaderFrame].fontString:SetText(MaxLength(map.name))

        local columnIndex = 1
        for _, character in pairs(characters) do
            for affixIndex = 1, 2 do
                local level = character.dungeons[map.id][affixIndex]
                if level == 0 then
                    level = "-"
                end
                local dungeonCellFrame = dungeonRowFrame .. "CELL" .. columnIndex
                self.tableFrame[dungeonCellFrame].fontString:SetText(level)
                columnIndex = columnIndex + 1
            end
        end

        rowIndex = rowIndex + 1
    end

    self.tableFrame:SetSize(frameWidth, rowHeight * rowIndex)
end
