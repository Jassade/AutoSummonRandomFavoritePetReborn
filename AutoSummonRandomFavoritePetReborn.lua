local db
local addonLoadedEvent = "ADDON_LOADED"
local addonName = "AutoSummonRandomFavoritePetReborn"
local events = {"PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_INDOORS",
                "ZONE_CHANGED_NEW_AREA", "PLAYER_MOUNT_DISPLAY_CHANGED", "PLAYER_ALIVE", "PLAYER_UNGHOST" }
local defaultSavedVars = {
    global = {
        disableOverwriteExistingPet = false,
        disableSummonInCombat = true,
},}
SLASH_AUTO_SUMMON_RANDOM_FAVORITE_PET1 = "/asrfp"
SLASH_AUTO_SUMMON_RANDOM_FAVORITE_PET2 = "/autoSummonPet"

local dbName = "AutoSummonRandomFavoritePetRebornDB"

local function isEventActive(val)
    for index, value in ipairs(events) do
        if value == val then
            return true
        end
    end
    return false
end

local function Commands (msg)
    if msg == "disableOverwriteExistingPet" then
        db.disableOverwriteExistingPet = true
    elseif msg == "enableOverwriteExistingPet" then
        db.disableOverwriteExistingPet = false
    elseif msg == "disableSummonInCombat" then
        db.disableSummonInCombat = true
    elseif msg == "enableSummonInCombat" then
        db.disableSummonInCombat = false
    end
end

SlashCmdList["AUTO_SUMMON_RANDOM_FAVORITE_PET"] = Commands
local shadowmeldIds = {58984}
local invisibilityIds = {55848, 60190, 60191, 28500, 110311, 99277, 96243, 11392, 32612, 23452, 32754, 155167,
                         135207, 216173, 194048, 175833, 52060, 176190, 114967, 168223, 66, 100796, 98147}
local greaterInvisibilityIds = {16380, 122293, 34426, 110959, 41253, 113862, 203613, 32811, 110960}
local invisibleIds = {228525, 176026, 302332, 283126, 250873, 310407, 307195}
local dimensionalShifterIds = {321405, 321422}
local feignDeathIds = {287172, 82436, 312779, 94995, 51329, 85267, 228659, 88991, 57626, 126009, 173805, 99450, 312998,
                       284354, 261610, 167477, 186640, 188721, 145666, 67691, 185726, 28728, 37493, 35571, 117577, 42557,
                       5384}
local gliderIds = {131347, 320521, 197154, 230255, 197130}

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function isInvisible()
    for i=1,255 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i)
        if not auraData then
            return false
        end

        local spellId = auraData.spellId
        if not spellId then
            return false
        elseif has_value(shadowmeldIds, spellId) or has_value(invisibilityIds, spellId) or has_value(greaterInvisibilityIds, spellId)
            or has_value(invisibleIds, spellId) or has_value(dimensionalShifterIds, spellId)  or has_value(gliderIds, spellId) then
            return true
        end
    end
    return false
end

local function isFeignDeath()
    for i=1,255 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i)
        if not auraData then
            return false
        end

        local spellId = auraData.spellId
        if not spellId then
            return false
        elseif has_value(feignDeathIds, spellId) then
            return true
        end
    end
    return false
end

local function wantToSummonNewPet()
    if IsMounted() or IsStealthed() or isInvisible() or isFeignDeath() then
        return false
    elseif db.disableSummonInCombat and UnitAffectingCombat("player") then
        return false
    elseif db.disableInStealth and IsStealthed() then
        return false
    elseif db.disableOverwriteExistingPet and C_PetJournal.GetSummonedPetGUID() ~= nil then
        return false
    end
    return true
end

function AutoSummonRandomFavoritePetReborn_OnLoad(self)
    self:RegisterEvent(addonLoadedEvent)
    for index, value in ipairs(events) do
        self:RegisterEvent(value)
    end
end


local function summonPet()
    if wantToSummonNewPet() then
        C_PetJournal.SummonRandomPet(true)
    end
end

local function addBlizzardOptions()

    local options = CreateFrame("FRAME", "AutoSummonRandomFavoritePetRebornOptions")
    local title = C_AddOns.GetAddOnMetadata(addonName, "Title")
    options.name = title

    local category = Settings.RegisterCanvasLayoutCategory(options, title)
    Settings.RegisterAddOnCategory(category)

    local optionsHeader = options:CreateFontString(nil, "ARTWORK")
    optionsHeader:SetFontObject(GameFontNormalLarge)
    optionsHeader:SetJustifyH("LEFT")
    optionsHeader:SetJustifyV("TOP")
    optionsHeader:ClearAllPoints()
    optionsHeader:SetPoint("TOPLEFT", 16, -16)
    optionsHeader:SetText(title)
    local count = 0
    local function addCheckButton(text, dbVariable)
        local button = CreateFrame("CheckButton", text .. "_GlobalNameText", options, "InterfaceOptionsCheckButtonTemplate")
        button:SetPoint("TOPLEFT", optionsHeader, "BOTTOMLEFT", -2, (count * -30) - 8)
        button:SetScript("OnClick", function()
            db[dbVariable] = not button:GetChecked()
        end)
        getglobal(button:GetName() .. 'Text'):SetText(text);
        button:SetChecked(not db[dbVariable]);
        count = count + 1
    end
    addCheckButton("Overwrite existing pet", "disableOverwriteExistingPet")
    addCheckButton("Summon pet in combat", "disableSummonInCombat")
end

function AutoSummonRandomFavoritePetReborn_OnEvent(self, event, ...)
    if event == addonLoadedEvent and ... == addonName then
        db = LibStub("AceDB-3.0"):New(dbName, defaultSavedVars).global
        self:UnregisterEvent(addonLoadedEvent)
        addBlizzardOptions()
    elseif isEventActive(event) then
       summonPet()
    end
end
