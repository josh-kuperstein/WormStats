-- Worm Stats :: options window
--
-- Opened with /ws or /ws config. Tick a stat to show it on the line, and use
-- the arrows to move it left or right. Everything here is per character.

local WS = WormStats

local ROW_H = 22

local window

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

function WS.BuildOptionsWindow()
    if window then return end
    local keys = WS.ALL_KEYS

    window = CreateFrame("Frame", "WormStatsConfig", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(320, 90 + #keys * ROW_H)
    window:SetPoint("CENTER")
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetFrameStrata("DIALOG")
    window:Hide()
    tinsert(UISpecialFrames, "WormStatsConfig")   -- Escape closes it

    local title = window.TitleText or window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    if not window.TitleText then title:SetPoint("TOP", 0, -5) end
    title:SetText("Worm Stats - " .. (UnitName("player") or ""))

    window.rows = {}
    for i = 1, #keys do
        local row = CreateFrame("Frame", nil, window)
        row:SetSize(290, ROW_H)
        row:SetPoint("TOPLEFT", 14, -30 - (i - 1) * ROW_H)

        row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.check:SetSize(22, 22)
        row.check:SetPoint("LEFT")

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
        row.label:SetWidth(200)
        row.label:SetJustifyH("LEFT")

        row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.up:SetSize(24, 20)
        row.up:SetPoint("RIGHT", -28, 0)
        row.up:SetText("^")

        row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.down:SetSize(24, 20)
        row.down:SetPoint("RIGHT")
        row.down:SetText("v")

        window.rows[i] = row
    end

    local lock = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    lock:SetSize(22, 22)
    lock:SetPoint("BOTTOMLEFT", 14, 12)
    lock.text = lock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lock.text:SetPoint("LEFT", lock, "RIGHT", 4, 0)
    lock.text:SetText("Lock position (unlock to drag)")
    lock:SetScript("OnClick", function(self)
        WormStatsCharDB.locked = self:GetChecked()
        WS.ApplyLayout()
    end)
    window.lock = lock
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

function WS.RefreshOptions()
    if not window or not window:IsShown() then return end
    local db = WormStatsCharDB

    for i, row in ipairs(window.rows) do
        local key = db.order[i]
        local stat = WS.STATS[key]
        row.label:SetText(string.format("|cffffd100%s|r  %s", stat.label, stat.name))
        row.check:SetChecked(db.enabled[key] and true or false)
        row.check:SetScript("OnClick", function(self)
            db.enabled[key] = self:GetChecked() or nil
            WS.Render()
        end)
        row.up:SetEnabled(i > 1)
        row.up:SetScript("OnClick", function()
            db.order[i], db.order[i - 1] = db.order[i - 1], db.order[i]
            WS.RefreshOptions(); WS.Render()
        end)
        row.down:SetEnabled(i < #db.order)
        row.down:SetScript("OnClick", function()
            db.order[i], db.order[i + 1] = db.order[i + 1], db.order[i]
            WS.RefreshOptions(); WS.Render()
        end)
    end
    window.lock:SetChecked(db.locked)
end

function WS.ToggleOptions()
    if not window then WS.BuildOptionsWindow() end
    if window:IsShown() then
        window:Hide()
    else
        window:Show()
        WS.RefreshOptions()
    end
end
