WoWAutoUpgradeDB = WoWAutoUpgradeDB or {}

local L = LibStub("AceLocale-3.0"):GetLocale("WAU")

local function Print(msg)
    print("|cff00ff88[WAU]|r " .. tostring(msg))
end

-- Max item level WAU upgrades
local MAX_ILVL = 739

-- Slot name localization
local SLOT_NAMES = {
    [1]="Head",[2]="Neck",[3]="Shoulder",[4]="Shirt",[5]="Chest",[6]="Waist",
    [7]="Legs",[8]="Feet",[9]="Wrist",[10]="Hands",
    [11]="Ring 1",[12]="Ring 2",[13]="Trinket 1",[14]="Trinket 2",
    [15]="Back",[16]="Main Hand",[17]="Off Hand",[19]="Tabard",
}

-- Mapping item equip location → player slot
local EquipLocMap = {
    INVTYPE_HEAD=1, INVTYPE_NECK=2, INVTYPE_SHOULDER=3,
    INVTYPE_CHEST=5, INVTYPE_ROBE=5, INVTYPE_WAIST=6,
    INVTYPE_LEGS=7, INVTYPE_FEET=8, INVTYPE_WRIST=9, INVTYPE_HAND=10,
    INVTYPE_FINGER=11, INVTYPE_TRINKET=13, INVTYPE_CLOAK=15,
    INVTYPE_WEAPONMAINHAND=16, INVTYPE_WEAPONOFFHAND=17,
    INVTYPE_2HWEAPON=16,
}

local function GetILVL(link)
    return (link and GetDetailedItemLevelInfo(link)) or 0
end

-----------------------------------------
-- UNIQUE CHECK FOR REMIX RINGS/TRINKETS
-----------------------------------------

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

-----------------------------------------
-- MAIN EQUIP LOGIC
-----------------------------------------

local function EquipBetterItem(bag,slot,slotId,link,equipLoc, upgradedFlag)
    local newIL = GetILVL(link)
    if newIL > MAX_ILVL then return end

    -- Unique check applies to all Remix rings/trinkets
    if equipLoc == "INVTYPE_FINGER" or equipLoc == "INVTYPE_TRINKET" then
        if IsUniqueEquipped(link) then return end

        -- Determine which slot is weaker
        local s1, s2 = (equipLoc=="INVTYPE_FINGER") and 11 or 13,
                       (equipLoc=="INVTYPE_FINGER") and 12 or 14

        local il1 = GetILVL(GetInventoryItemLink("player", s1))
        local il2 = GetILVL(GetInventoryItemLink("player", s2))
        local target = (il1 <= il2) and s1 or s2

        local oldIL = (target == s1) and il1 or il2
        if newIL <= oldIL then return end

        C_Container.PickupContainerItem(bag,slot)
        EquipCursorItem(target)

        upgradedFlag.value = true
        local displayName = L[SLOT_NAMES[target]] or SLOT_NAMES[target]
        Print(L["UPGRADED_SLOT"]:format(displayName))
        return
    end

    -- Normal items
    local currIL = GetILVL(GetInventoryItemLink("player",slotId))
    if newIL > currIL then
        C_Container.PickupContainerItem(bag,slot)
        EquipCursorItem(slotId)

        upgradedFlag.value = true
        local displayName = L[SLOT_NAMES[slotId]] or SLOT_NAMES[slotId]
        Print(L["UPGRADED_SLOT"]:format(displayName))
    end
end

-----------------------------------------
-- FULL BAG SCAN
-----------------------------------------

function WAU_ScanAndEquip(mode)
    if InCombatLockdown() then 
        Print(L["CANNOT_UPGRADE_COMBAT"]) 
        return 
    end

    local upgradedFlag = { value = false }

    for bag=0,4 do
        for slot=1,C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag,slot)
            if link then
                local _,_,_,_,_,_,_,_,equipLoc = GetItemInfo(link)
                local slotId = EquipLocMap[equipLoc]

                if slotId and not (WoWAutoUpgradeDB.blockedSlots and WoWAutoUpgradeDB.blockedSlots[slotId]) then
                    EquipBetterItem(bag,slot,slotId,link,equipLoc, upgradedFlag)
                end
            end
        end
    end

    -- Only show message once on manual scans
    if mode == "manual" and not upgradedFlag.value then
        Print(L["NO_UPGRADES_FOUND"])
    end
end

-----------------------------------------
-- SLASH COMMANDS (/wau)
-----------------------------------------

SLASH_WAU1 = "/wau"
SlashCmdList["WAU"] = function(msg)
    msg = msg and msg:lower() or ""

    -- Manuelles Scannen
    if msg == "scan" then
        WAU_ScanAndEquip("manual")
        return  -- WICHTIG
    end

    -- Auto-Modus AN
    if msg == "on" then
        WoWAutoUpgradeDB.auto = true
        Print(L["AUTO_ON"])
        return  -- WICHTIG
    end

    -- Auto-Modus AUS
    if msg == "off" then
        WoWAutoUpgradeDB.auto = false
        Print(L["AUTO_OFF"])
        return  -- WICHTIG
    end

    -- Wenn kein Parameter → Einstellungsfenster öffnen
    if WAU_Category then
        Settings.OpenToCategory(WAU_Category)
    else
        Print("WAU: No settings panel registered.")
    end
end

-----------------------------------------
-- EVENT HANDLER
-----------------------------------------

local WAU_LoginBlockUntil = 0

local f=CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("BAG_UPDATE_DELAYED")

f:SetScript("OnEvent", function(_,event)
    WoWAutoUpgradeDB.blockedSlots = WoWAutoUpgradeDB.blockedSlots or {}

    if event=="PLAYER_LOGIN" then

        -----------------------------------------
        -- Version + Interface über GetBuildInfo()
        -- 100% zuverlässig in Retail
        -----------------------------------------
local version = C_AddOns.GetAddOnMetadata("WAU", "Version") or "?"
local _, _, _, iface = GetBuildInfo()

local msg = string.format(
    "Version |cffffff00%s|r (Interface |cff33ccff%s|r)", version, iface)
    Print(msg)

        -- Prevent auto-scan for 3 sec after login
        WAU_LoginBlockUntil = GetTime() + 3

    elseif event=="BAG_UPDATE_DELAYED" 
       and WoWAutoUpgradeDB.auto 
       and GetTime() > WAU_LoginBlockUntil then

        WAU_ScanAndEquip("auto")
    end
end)
