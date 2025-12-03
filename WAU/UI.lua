local L = LibStub("AceLocale-3.0"):GetLocale("WAU")

function WAU_InitOptionsPanel()
    ----------------------------------------------------------------------
    -- MAIN PANEL
    ----------------------------------------------------------------------
    local panel = CreateFrame("Frame", "WAUOptionsPanel", UIParent)
    panel.name = L["ADDON_NAME"]

    ----------------------------------------------------------------------
    -- TITLE
    ----------------------------------------------------------------------
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -20)
    title:SetText("|cff00ff88WAU – Auto Upgrade|r")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetText(L["CONFIG_TITLE"])

    ----------------------------------------------------------------------
    -- AUTO MODE CHECKBOX (modern template + own label)
    ----------------------------------------------------------------------
    local autoToggle = CreateFrame("CheckButton", nil, panel, "SettingsCheckBoxTemplate")
    autoToggle:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -25)
    autoToggle:SetChecked(WoWAutoUpgradeDB.auto)

    local autoLabel = autoToggle:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    autoLabel:SetPoint("LEFT", autoToggle, "RIGHT", 8, 0)
    autoLabel:SetText(L["AUTO_ON"] .. " / " .. L["AUTO_OFF"])

    autoToggle:SetScript("OnClick", function(self)
        WoWAutoUpgradeDB.auto = self:GetChecked()
    end)

    -- Hover-Licht ausschalten
    if autoToggle.HoverBackground then
        autoToggle.HoverBackground:SetAlpha(0)
    end


   ----------------------------------------------------------------------
-- MAX ITEMLEVEL SLIDER + Live-Anzeige
----------------------------------------------------------------------
local sliderLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sliderLabel:SetPoint("TOPLEFT", autoToggle, "BOTTOMLEFT", 0, -40)
sliderLabel:SetText(L["MAX_ILVL"])

local slider = CreateFrame("Slider", "WAUMaxILvlSlider", panel, "MinimalSliderWithSteppersTemplate")
slider:SetPoint("TOPLEFT", sliderLabel, "BOTTOMLEFT", 0, -10)
slider:SetWidth(260)

-- echtes Slider-Objekt
local s = slider.Slider

s:SetMinMaxValues(200, 1000)
s:SetObeyStepOnDrag(true)
s:SetValueStep(1)
s:SetValue(WoWAutoUpgradeDB.maxItemLevel)

-- Live-Vorschau Text
local sliderValueText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
sliderValueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)
sliderValueText:SetText("Aktuell: " .. WoWAutoUpgradeDB.maxItemLevel)

-- Update-Funktion
s:HookScript("OnValueChanged", function(self, value)
    local v = math.floor(value)
    WoWAutoUpgradeDB.maxItemLevel = v
    sliderValueText:SetText("Aktuell: " .. v)
end)

-- Steppers aktivieren
if slider.LeftButton then slider.LeftButton:Enable() end
if slider.RightButton then slider.RightButton:Enable() end
if slider.Back then slider.Back:Enable() end
if slider.Forward then slider.Forward:Enable() end


    ----------------------------------------------------------------------
    -- SLOT HEADER
    ----------------------------------------------------------------------
    local slotHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    slotHeader:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -30)
    slotHeader:SetText(L["SLOT_SETTINGS"])

    ----------------------------------------------------------------------
    -- SLOT CHECKBOX GRID (modern template + own labels)
    ----------------------------------------------------------------------
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

    local yOffset = -10
    local ROW_HEIGHT = 28
    local LEFT_X = 0
    local RIGHT_X = 250

    for i, data in ipairs(slots) do
        local id, label = data[1], data[2]

        local cb = CreateFrame("CheckButton", nil, panel, "SettingsCheckBoxTemplate")
        cb:SetChecked(WoWAutoUpgradeDB.blockedSlots[id] == true)

        if i % 2 == 1 then
            cb:SetPoint("TOPLEFT", slotHeader, "BOTTOMLEFT", LEFT_X, yOffset)
        else
            cb:SetPoint("TOPLEFT", slotHeader, "BOTTOMLEFT", RIGHT_X, yOffset)
            yOffset = yOffset - ROW_HEIGHT
        end

        local lbl = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        lbl:SetPoint("LEFT", cb, "RIGHT", 8, 0)
        lbl:SetText(label)

        cb:SetScript("OnClick", function(self)
            WoWAutoUpgradeDB.blockedSlots[id] = self:GetChecked() or nil
        end)
        -- Hover-Licht für Slots ausschalten
        if cb.HoverBackground then
            cb.HoverBackground:SetAlpha(0)
        end
    end

    ----------------------------------------------------------------------
    -- APPLY BUTTON
    ----------------------------------------------------------------------
    local applyBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    applyBtn:SetSize(160, 32)
    applyBtn:SetPoint("BOTTOMLEFT", 20, 20)
    applyBtn:SetText(L["BUTTON_APPLY"])

    applyBtn:SetScript("OnClick", function()
        ReloadUI()
    end)

    ----------------------------------------------------------------------
    -- REGISTER SETTINGS
    ----------------------------------------------------------------------
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    WAU_Category = category
end

----------------------------------------------------------------------
-- INIT ON LOGIN
----------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    WAU_InitOptionsPanel()
end)
