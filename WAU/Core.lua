local ADDON_NAME = ...
local L = LibStub("AceLocale-3.0"):GetLocale("WAU")

---------------------------------------------------------------------
-- SavedVariables defaults
---------------------------------------------------------------------
WoWAutoUpgradeDB = WoWAutoUpgradeDB or {}

if WoWAutoUpgradeDB.auto == nil then
    WoWAutoUpgradeDB.auto = true
end

if not WoWAutoUpgradeDB.blockedSlots then
    WoWAutoUpgradeDB.blockedSlots = {}
end

if not WoWAutoUpgradeDB.maxItemLevel then
    WoWAutoUpgradeDB.maxItemLevel = 739
end

---------------------------------------------------------------------
-- Utility print
---------------------------------------------------------------------
local function Print(msg)
    print("|cff33ff99WAU:|r " .. msg)
end

---------------------------------------------------------------------
-- Helper: dynamic max ilvl
---------------------------------------------------------------------
local function GetMaxILvl()
    return WoWAutoUpgradeDB.maxItemLevel or 739
end

---------------------------------------------------------------------
-- Slot name mapping for messages (slotID -> locale key)
---------------------------------------------------------------------
local SLOT_NAME_KEY = {
    [1]  = "Head",
    [2]  = "Neck",
    [3]  = "Shoulder",
    [5]  = "Chest",
    [6]  = "Waist",
    [7]  = "Legs",
    [8]  = "Feet",
    [9]  = "Wrist",
    [10] = "Hands",
    [11] = "Ring 1",
    [12] = "Ring 2",
    [13] = "Trinket 1",
    [14] = "Trinket 2",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand",
}

---------------------------------------------------------------------
-- Equip location to slotID mapping (Blizzard standard)
---------------------------------------------------------------------
local SLOT_MAP = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_CLOAK          = 15,
    INVTYPE_CHEST          = 5,
    INVTYPE_ROBE           = 5,
    INVTYPE_WRIST          = 9,
    INVTYPE_HAND           = 10,
    INVTYPE_WAIST          = 6,
    INVTYPE_LEGS           = 7,
    INVTYPE_FEET           = 8,
    INVTYPE_FINGER         = {11, 12},
    INVTYPE_TRINKET        = {13, 14},
    INVTYPE_WEAPON         = 16,     -- 1H default to MainHand
    INVTYPE_2HWEAPON       = 16,     -- 2H → MainHand
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND  = 17,
    INVTYPE_HOLDABLE       = 17,
    INVTYPE_SHIELD         = 17,
    INVTYPE_RANGED         = 16,
    INVTYPE_RANGEDRIGHT    = 16,
}

---------------------------------------------------------------------
-- Get item level
---------------------------------------------------------------------
local function GetItemLevel(itemLink)
    if not itemLink then return 0 end
    local _, _, _, ilvl = GetItemInfo(itemLink)
    return ilvl or 0
end

---------------------------------------------------------------------
-- Get equip slot(s) for an item (returns slotID or table of slotIDs)
---------------------------------------------------------------------
local function GetEquipSlotsForItem(itemLink)
    if not itemLink then return nil end
    local _, _, _, _, _, _, _, _, equipLoc =
        GetItemInfoInstant(itemLink)

    return SLOT_MAP[equipLoc]
end

---------------------------------------------------------------------
-- Try to equip an item if it's an upgrade
---------------------------------------------------------------------
local function TryEquip(itemLink)
    if not itemLink or UnitAffectingCombat("player") then return false end

    local newIL = GetItemLevel(itemLink)
    if newIL == 0 or newIL > GetMaxILvl() then return false end

    local slots = GetEquipSlotsForItem(itemLink)
    if not slots then return false end

    local bestSlot, bestDelta = nil, 0

    local function evaluateSlot(slotID)
        if WoWAutoUpgradeDB.blockedSlots[slotID] then return end
        local current = GetInventoryItemLink("player", slotID)
        local delta = newIL - GetItemLevel(current)
        if delta > bestDelta then
            bestDelta = delta
            bestSlot = slotID
        end
    end

    if type(slots) == "table" then
        for _, slotID in ipairs(slots) do
            evaluateSlot(slotID)
        end
    else
        evaluateSlot(slots)
    end

    if bestSlot and bestDelta > 0 then
        EquipItemByName(itemLink, bestSlot)

        local key = SLOT_NAME_KEY[bestSlot]
        local name = key and L[key] or ("Slot " .. bestSlot)

        Print(string.format(L["UPGRADED_SLOT"], name))
        return true
    end

    return false
end

---------------------------------------------------------------------
-- Scan bags for upgrades (manual = true shows message)
---------------------------------------------------------------------
function WAU_ScanAndEquip(manual)
    if UnitAffectingCombat("player") then
        if manual then Print(L["CANNOT_UPGRADE_COMBAT"]) end
        return
    end

    local found = false

    for bag = 0, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        for s = 1, slots do
            local link = C_Container.GetContainerItemLink(bag, s)
            if link and TryEquip(link) then
                found = true
            end
        end
    end

    if manual and not found then
        Print(L["NO_UPGRADES_FOUND"])
    end
end

---------------------------------------------------------------------
-- Events
---------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BAG_UPDATE_DELAYED")

local nextScan = 0

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Auto-detect the real addon folder name
        local realName = ADDON_NAME or "WAU"
        local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

        local version = meta(realName, "Version") or "?"
        local iface   = meta(realName, "Interface") or "?"

        Print("Version |cff00ff00" .. version ..
              "|r (Interface |cffff9900" .. iface .. "|r)")
        Print("Max iLvl: |cffffff00" .. GetMaxILvl() .. "|r")
    end

    if event == "BAG_UPDATE_DELAYED" and WoWAutoUpgradeDB.auto then
        local now = GetTime()
        if now > nextScan then
            nextScan = now + 0.15
            WAU_ScanAndEquip(false)
        end
    end
end)

---------------------------------------------------------------------
-- Slash Commands
---------------------------------------------------------------------
SLASH_WAU1 = "/wau"
SlashCmdList["WAU"] = function(msg)
    msg = (msg and msg:lower()) or ""

    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    arg = arg or ""

    if cmd == "max" and arg == "" then
        Print(L["USAGE_WAU_MAX"])
        return
    end

    if cmd == "max" and arg ~= "" then
        local val = tonumber(arg)
        if val and val > 0 then
            WoWAutoUpgradeDB.maxItemLevel = val
            Print("Max item level set to |cffffff00" .. val .. "|r")
        else
            Print(L["USAGE_WAU_MAX"])
        end
        return
    end

    if cmd == "scan" then
        WAU_ScanAndEquip(true)
        return
    end

    if cmd == "on" then
        WoWAutoUpgradeDB.auto = true
        Print(L["AUTO_ON"])
        return
    end

    if cmd == "off" then
        WoWAutoUpgradeDB.auto = false
        Print(L["AUTO_OFF"])
        return
    end
    
    if cmd == "help" then
        Print("Use:/wau for Options, /wau scan, /wau on or off, /wau max <number>")
        return
    end

    if WAU_Category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(WAU_Category)
    else
        Print("Use:/wau for Options, /wau scan, /wau on or off, /wau max <number>")
    end
end
