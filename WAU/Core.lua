local ADDON_NAME = ...
WoWAutoUpgradeDB = WoWAutoUpgradeDB or {}

local L = LibStub("AceLocale-3.0"):GetLocale("WAU")

--------------------------------------------------
-- SavedVariables defaults
--------------------------------------------------
if WoWAutoUpgradeDB.auto == nil then
    WoWAutoUpgradeDB.auto = true
end

if not WoWAutoUpgradeDB.blockedSlots then
    WoWAutoUpgradeDB.blockedSlots = {}
end

if not WoWAutoUpgradeDB.maxItemLevel then
    WoWAutoUpgradeDB.maxItemLevel = 739
end

--------------------------------------------------
-- Utility
--------------------------------------------------
local function Print(msg)
    print("|cff00ff88[WAU]|r " .. tostring(msg))
end

local function GetMaxILvl()
    return WoWAutoUpgradeDB.maxItemLevel or 739
end

--------------------------------------------------
-- Slot names (for messages)
--------------------------------------------------
local SLOT_NAMES = {
    [1] = "Head",
    [2] = "Neck",
    [3] = "Shoulder",
    [4] = "Shirt",
    [5] = "Chest",
    [6] = "Waist",
    [7] = "Legs",
    [8] = "Feet",
    [9] = "Wrist",
    [10] = "Hands",
    [11] = "Ring 1",
    [12] = "Ring 2",
    [13] = "Trinket 1",
    [14] = "Trinket 2",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand",
}

--------------------------------------------------
-- EquipLoc → Slot mapping (simple, but Remix-safe)
--------------------------------------------------
local EquipLocMap = {
    INVTYPE_HEAD           = 1,
    INVTYPE_NECK           = 2,
    INVTYPE_SHOULDER       = 3,
    INVTYPE_CHEST          = 5,
    INVTYPE_ROBE           = 5,
    INVTYPE_WAIST          = 6,
    INVTYPE_LEGS           = 7,
    INVTYPE_FEET           = 8,
    INVTYPE_WRIST          = 9,
    INVTYPE_HAND           = 10,
    INVTYPE_FINGER         = 11, -- base, actual handling below
    INVTYPE_TRINKET        = 13, -- base, actual handling below
    INVTYPE_CLOAK          = 15,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND  = 17,
    INVTYPE_2HWEAPON       = 16,
}

--------------------------------------------------
-- Item level helper
--------------------------------------------------
local function GetILVL(link)
    return (link and GetDetailedItemLevelInfo(link)) or 0
end

--------------------------------------------------
-- Unique check for Remix rings/trinkets
--------------------------------------------------
local function IsUniqueEquipped(link)
    if not link then return false end
    local newID = GetItemInfoInstant(link)
    if not newID then return false end

    -- Trinket slots
    local t1 = GetItemInfoInstant(GetInventoryItemLink("player", 13) or "")
    local t2 = GetItemInfoInstant(GetInventoryItemLink("player", 14) or "")

    -- Ring slots
    local r1 = GetItemInfoInstant(GetInventoryItemLink("player", 11) or "")
    local r2 = GetItemInfoInstant(GetInventoryItemLink("player", 12) or "")

    return (newID == t1 or newID == t2 or newID == r1 or newID == r2)
end

--------------------------------------------------
-- Main equip logic (based on v1.10 behaviour)
--------------------------------------------------
local function EquipBetterItem(bag, slot, slotId, link, equipLoc, upgradedFlag)
    local newIL = GetILVL(link)
    if newIL == 0 then return end
    if newIL > GetMaxILvl() then return end

    -- Unique check applies to all Remix rings/trinkets
    if equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_TRINKET" then
        if IsUniqueEquipped(link) then return end

        -- Determine which slot is weaker
        local s1, s2 = (equipLoc == "INVTYPE_FINGER") and 11 or 13,
                       (equipLoc == "INVTYPE_FINGER") and 12 or 14

        local il1 = GetILVL(GetInventoryItemLink("player", s1))
        local il2 = GetILVL(GetInventoryItemLink("player", s2))
        local target = (il1 <= il2) and s1 or s2

        local oldIL = (target == s1) and il1 or il2
        if newIL <= oldIL then return end

        C_Container.PickupContainerItem(bag, slot)
        EquipCursorItem(target)

        upgradedFlag.value = true
        local displayName = L[SLOT_NAMES[target]] or SLOT_NAMES[target]
        Print(L["UPGRADED_SLOT"]:format(displayName))
        return
    end

    -- Normal items
    local currIL = GetILVL(GetInventoryItemLink("player", slotId))
    if newIL > currIL then
        C_Container.PickupContainerItem(bag, slot)
        EquipCursorItem(slotId)

        upgradedFlag.value = true
        local displayName = L[SLOT_NAMES[slotId]] or SLOT_NAMES[slotId]
        Print(L["UPGRADED_SLOT"]:format(displayName))
    end
end

--------------------------------------------------
-- Full bag scan
--------------------------------------------------
function WAU_ScanAndEquip(mode)
    if InCombatLockdown() then
        if mode == "manual" then
            Print(L["CANNOT_UPGRADE_COMBAT"])
        end
        return
    end

    local upgradedFlag = { value = false }

    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then
                local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
                if equipLoc then
                    local slotId = EquipLocMap[equipLoc]
                    if slotId and not WoWAutoUpgradeDB.blockedSlots[slotId] then
                        EquipBetterItem(bag, slot, slotId, link, equipLoc, upgradedFlag)
                    end
                end
            end
        end
    end

    -- Only show message once on manual scans
    if mode == "manual" and not upgradedFlag.value then
        Print(L["NO_UPGRADES_FOUND"])
    end
end

--------------------------------------------------
-- Slash commands
--------------------------------------------------
SLASH_WAU1 = "/wau"
SlashCmdList["WAU"] = function(msg)
    msg = msg and msg:lower() or ""
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    cmd = cmd or ""
    arg = arg or ""

    -- /wau scan → manual scan
    if cmd == "scan" then
        WAU_ScanAndEquip("manual")
        return
    end

    -- /wau on → enable auto mode
    if cmd == "on" then
        WoWAutoUpgradeDB.auto = true
        Print(L["AUTO_ON"])
        return
    end

    -- /wau off → disable auto mode
    if cmd == "off" then
        WoWAutoUpgradeDB.auto = false
        Print(L["AUTO_OFF"])
        return
    end

    -- /wau max → show usage
    if cmd == "max" and arg == "" then
        Print(L["USAGE_WAU_MAX"])
        return
    end

    -- /wau max <number>
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

    -- default: open settings panel
    if WAU_Category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(WAU_Category)
    else
        Print("Use: /wau scan, /wau on, /wau off, /wau max <number>")
    end
end

--------------------------------------------------
-- Events
--------------------------------------------------
local WAU_LoginBlockUntil = 0
local WAU_NextScanAt = 0

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BAG_UPDATE_DELAYED")

f:SetScript("OnEvent", function(_, event)
    -- ensure defaults
    WoWAutoUpgradeDB.blockedSlots = WoWAutoUpgradeDB.blockedSlots or {}
    if WoWAutoUpgradeDB.auto == nil then
        WoWAutoUpgradeDB.auto = true
    end

    if event == "PLAYER_LOGIN" then
        -- Version + Interface from TOC, folder name safe
        local realName = ADDON_NAME or "WAU"
        local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

        local version = meta and meta(realName, "Version") or "?"
        local iface   = meta and meta(realName, "Interface") or "?"

        Print("|cffffff00WAU|r – Version |cff00ff00" .. version ..
              "|r (Interface |cffff9900" .. iface .. "|r)")
        Print("Max iLvl: |cffffff00" .. GetMaxILvl() .. "|r")

        -- Prevent auto-scan for 3 sec after login
        WAU_LoginBlockUntil = GetTime() + 3

    elseif event == "BAG_UPDATE_DELAYED" and WoWAutoUpgradeDB.auto then
        local now = GetTime()
        if now > WAU_LoginBlockUntil and now > WAU_NextScanAt then
            WAU_NextScanAt = now + 0.15
            WAU_ScanAndEquip("auto")
        end
    end
end)
