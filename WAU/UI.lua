local L = LibStub("AceLocale-3.0"):GetLocale("WAU")

function WAU_InitOptionsPanel()
    ----------------------------------------------------------
    -- Hauptpanel
    ----------------------------------------------------------
    local panel = CreateFrame("Frame", "WAUOptionsPanel", UIParent)
    panel.name = L["ADDON_NAME"]

    ----------------------------------------------------------
    -- Titel
    ----------------------------------------------------------
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L["CONFIG_TITLE"])

    ----------------------------------------------------------
    -- Auto-Modus Checkbox
    ----------------------------------------------------------
    local autoCB = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    autoCB:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -28)

    autoCB.text = autoCB:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    autoCB.text:SetPoint("LEFT", autoCB, "RIGHT", 6, 0)
    autoCB.text:SetText(L["AUTO_ON"] .. " / " .. L["AUTO_OFF"])

    autoCB:SetChecked(WoWAutoUpgradeDB.auto == true)
    autoCB:SetScript("OnClick", function(self)
        WoWAutoUpgradeDB.auto = self:GetChecked() and true or false
    end)

    ----------------------------------------------------------
    -- Slot-Blocker Titel
    ----------------------------------------------------------
    local slotTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    slotTitle:SetPoint("TOPLEFT", autoCB, "BOTTOMLEFT", 0, -24)
    slotTitle:SetText(L["CONFIG_TITLE"] .. " – Slots")

    ----------------------------------------------------------
    -- Slot Checkboxes
    ----------------------------------------------------------
    local slots = {
        {1,  L["Head"]},      {2,  L["Neck"]},
        {3,  L["Shoulder"]},  {15, L["Back"]},
        {5,  L["Chest"]},     {6,  L["Waist"]},
        {7,  L["Legs"]},      {8,  L["Feet"]},
        {9,  L["Wrist"]},     {10, L["Hands"]},
        {11, L["Ring 1"]},    {12, L["Ring 2"]},
        {13, L["Trinket 1"]}, {14, L["Trinket 2"]},
        {16, L["Main Hand"]}, {17, L["Off Hand"]},
    }

    local col1, col2 = 20, 260
    local rowY = -160
    panel.checkboxes = {}

    for i, data in ipairs(slots) do
        local id, label = data[1], data[2]

        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cb.text = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        cb.text:SetText(label)

        if i % 2 == 1 then
            cb:SetPoint("TOPLEFT", col1, rowY)
        else
            cb:SetPoint("TOPLEFT", col2, rowY)
            rowY = rowY - 26
        end

        cb:SetChecked(WoWAutoUpgradeDB.blockedSlots[id] == true)
        cb:SetScript("OnClick", function(self)
            WoWAutoUpgradeDB.blockedSlots[id] = self:GetChecked() or nil
        end)

        panel.checkboxes[id] = cb
    end

    ----------------------------------------------------------
    -- Reload Button
    ----------------------------------------------------------
    local reloadBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reloadBtn:SetSize(160, 26)
    reloadBtn:SetPoint("BOTTOMLEFT", 20, 20)
    reloadBtn:SetText(L["BUTTON_APPLY"])
    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)

    ----------------------------------------------------------
    -- Registrierung (Dragonflight / 11.x API)
    ----------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)

    -- Für /wau speichern
    WAU_Category = category
end

----------------------------------------------------------
-- Initialisierung
----------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    WAU_InitOptionsPanel()
end)