-- Worm Stats :: core
-- A single configurable line of character stats, chosen and ordered per
-- character.
--
--   /ws                    open or close the options window
--   /ws config             same
--   /ws lock | unlock      lock the line in place, or unlock it to drag
--   /ws scale <n>          scale the line (0.5 to 3)
--   /ws font <n>           font size (8 to 40)
--   /ws reset              restore this character's defaults

local ADDON_NAME = ...

WormStats = WormStats or {}
local WS = WormStats

---------------------------------------------------------------------------
-- Tunables
---------------------------------------------------------------------------

local RENDER_DELAY = 0.1   -- seconds to coalesce a burst of events into one redraw

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

function WS.Print(msg)
    print("|cffc77b4aWorm Stats|r: " .. msg)
end
local Print = WS.Print

local function Pct(v)
    if not v then return nil end
    if math.abs(v - math.floor(v + 0.5)) < 0.005 then
        return string.format("%d%%", math.floor(v + 0.5))
    end
    return string.format("%.2f%%", v)
end

local function Int(v)
    if not v then return nil end
    return string.format("%d", math.floor(v + 0.5))
end

-- Spell schools: 2 holy, 3 fire, 4 nature, 5 frost, 6 shadow, 7 arcane
local SCHOOLS = { 2, 3, 4, 5, 6, 7 }

local function BestOverSchools(fn)
    if not fn then return nil end
    local best
    for _, s in ipairs(SCHOOLS) do
        local v = fn(s)
        if v and (not best or v > best) then best = v end
    end
    return best
end

local function CountBuffs()
    local n = 0
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 255 do
            if not C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL") then break end
            n = i
        end
    elseif UnitBuff then
        for i = 1, 255 do
            if not UnitBuff("player", i) then break end
            n = i
        end
    end
    return n
end

---------------------------------------------------------------------------
-- Stat registry. Each getter returns display text; errors show as "?".
---------------------------------------------------------------------------

WS.STATS = {
    buffs = { label = "BUFFS", name = "Buff count", get = function() return tostring(CountBuffs()) end },

    spellhit = { label = "HIT", name = "Spell hit", get = function()
        if GetSpellHitModifier then
            local v = GetSpellHitModifier()
            if v then return Pct(v) end
        end
        if GetCombatRatingBonus and CR_HIT_SPELL then return Pct(GetCombatRatingBonus(CR_HIT_SPELL)) end
    end },

    meleehit = { label = "HIT", name = "Melee hit", get = function()
        if GetHitModifier then
            local v = GetHitModifier()
            if v then return Pct(v) end
        end
        if GetCombatRatingBonus and CR_HIT_MELEE then return Pct(GetCombatRatingBonus(CR_HIT_MELEE)) end
    end },

    spellcrit = { label = "CRIT", name = "Spell crit (best school)", get = function()
        return Pct(BestOverSchools(GetSpellCritChance))
    end },

    meleecrit = { label = "CRIT", name = "Melee crit", get = function()
        return GetCritChance and Pct(GetCritChance())
    end },

    sp = { label = "SP", name = "Spell power (best school)", get = function()
        return Int(BestOverSchools(GetSpellBonusDamage))
    end },

    shadow = { label = "SHADOW", name = "Shadow spell power", get = function()
        return GetSpellBonusDamage and Int(GetSpellBonusDamage(6))
    end },

    fire = { label = "FIRE", name = "Fire spell power", get = function()
        return GetSpellBonusDamage and Int(GetSpellBonusDamage(3))
    end },

    haste = { label = "HASTE", name = "Haste", get = function()
        return GetHaste and Pct(GetHaste())
    end },

    mp5 = { label = "MP5", name = "Mana regen while casting (per 5s)", get = function()
        if not GetManaRegen then return nil end
        local _, casting = GetManaRegen()
        return casting and Int(casting * 5)
    end },

    ap = { label = "AP", name = "Melee attack power", get = function()
        local base, pos, neg = UnitAttackPower("player")
        return Int(base + pos + neg)
    end },

    dmg = { label = "DMG", name = "Physical damage modifier", get = function()
        local mult = select(7, UnitDamage("player"))
        return mult and Pct(mult * 100)
    end },

    int = { label = "INT", name = "Intellect", get = function() return Int(select(2, UnitStat("player", 4))) end },
    spi = { label = "SPI", name = "Spirit", get = function() return Int(select(2, UnitStat("player", 5))) end },
    sta = { label = "STA", name = "Stamina", get = function() return Int(select(2, UnitStat("player", 3))) end },

    heal = { label = "HEAL", name = "Healing power", get = function()
        return GetSpellBonusHealing and Int(GetSpellBonusHealing())
    end },

    rap = { label = "RAP", name = "Ranged attack power", get = function()
        local base, pos, neg = UnitRangedAttackPower("player")
        return Int(base + pos + neg)
    end },

    rangedcrit = { label = "RCRIT", name = "Ranged crit", get = function()
        return GetRangedCritChance and Pct(GetRangedCritChance())
    end },

    armor = { label = "ARMOR", name = "Armor", get = function() return Int(select(2, UnitArmor("player"))) end },

    dodge = { label = "DODGE", name = "Dodge", get = function() return GetDodgeChance and Pct(GetDodgeChance()) end },
    parry = { label = "PARRY", name = "Parry", get = function() return GetParryChance and Pct(GetParryChance()) end },
    block = { label = "BLOCK", name = "Block", get = function() return GetBlockChance and Pct(GetBlockChance()) end },

    str = { label = "STR", name = "Strength", get = function() return Int(select(2, UnitStat("player", 1))) end },
    agi = { label = "AGI", name = "Agility", get = function() return Int(select(2, UnitStat("player", 2))) end },
}
local STATS = WS.STATS

-- Registry order = order new stats get appended in for existing characters.
WS.ALL_KEYS = { "buffs", "spellhit", "spellcrit", "sp", "shadow", "fire", "haste", "mp5",
                "meleehit", "meleecrit", "ap", "dmg", "int", "spi", "sta",
                "heal", "rap", "rangedcrit", "armor", "dodge", "parry", "block", "str", "agi" }

WS.DEFAULT_ENABLED = { buffs = true, spellhit = true, spellcrit = true, sp = true, haste = true }

---------------------------------------------------------------------------
-- Saved variables
---------------------------------------------------------------------------

function WS.InitDB(reset)
    if reset or type(WormStatsCharDB) ~= "table" then WormStatsCharDB = {} end
    local db = WormStatsCharDB

    db.order    = db.order or {}
    db.enabled  = db.enabled or CopyTable(WS.DEFAULT_ENABLED)
    db.point    = db.point or { "BOTTOM", "BOTTOM", 0, 8 }
    db.scale    = db.scale or 1
    db.fontSize = db.fontSize or 16
    db.spacing  = db.spacing or "   "
    if db.locked == nil then db.locked = true end

    -- Drop unknown keys, append any stats added since this character's last save.
    local seen, clean = {}, {}
    for _, k in ipairs(db.order) do
        if STATS[k] and not seen[k] then clean[#clean + 1] = k; seen[k] = true end
    end
    for _, k in ipairs(WS.ALL_KEYS) do
        if not seen[k] then clean[#clean + 1] = k end
    end
    db.order = clean
end

---------------------------------------------------------------------------
-- Display
---------------------------------------------------------------------------

local line = CreateFrame("Frame", "WormStatsFrame", UIParent)
line:SetSize(200, 24)
line:SetMovable(true)
line:SetClampedToScreen(true)

line.bg = line:CreateTexture(nil, "BACKGROUND")
line.bg:SetAllPoints()
line.bg:SetColorTexture(0, 0.6, 1, 0.25)

line.text = line:CreateFontString(nil, "OVERLAY")
line.text:SetPoint("CENTER")
line.text:SetJustifyH("CENTER")
line.text:SetTextColor(1, 1, 1)

line:RegisterForDrag("LeftButton")
line:SetScript("OnDragStart", function(self)
    if not WormStatsCharDB.locked then self:StartMoving() end
end)
line:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    WormStatsCharDB.point = { point, relPoint, x, y }
end)

function WS.ApplyLayout()
    local db = WormStatsCharDB
    line:ClearAllPoints()
    local p = db.point
    line:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    line:SetScale(db.scale)
    line.text:SetFont(STANDARD_TEXT_FONT, db.fontSize, "OUTLINE")
    line:EnableMouse(not db.locked)
    line.bg:SetShown(not db.locked)
end

-- Report each failing stat once per session so a "?" comes with a reason.
local reported = {}

function WS.Render()
    local db = WormStatsCharDB
    if not db then return end
    local parts = {}
    for _, k in ipairs(db.order) do
        if db.enabled[k] then
            local ok, v = pcall(STATS[k].get)
            if not ok and not reported[k] then
                reported[k] = true
                Print(STATS[k].name .. " failed: " .. tostring(v))
            end
            parts[#parts + 1] = STATS[k].label .. " " .. ((ok and v) or "?")
        end
    end
    line.text:SetText(table.concat(parts, db.spacing))
    line:SetWidth(math.max(line.text:GetStringWidth() + 16, 60))
    line:SetHeight(line.text:GetStringHeight() + 8)
end

-- Coalesce bursts of events into one redraw.
local pending = false
local function RequestRender()
    if pending then return end
    pending = true
    C_Timer.After(RENDER_DELAY, function() pending = false; WS.Render() end)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local f = CreateFrame("Frame")

-- Not every event exists on every client build; register defensively, but
-- say so when one is missing, since its stats would silently stop updating.
local function TryEvent(name, unit)
    local ok, err
    if unit then
        ok, err = pcall(f.RegisterUnitEvent, f, name, unit)
    else
        ok, err = pcall(f.RegisterEvent, f, name)
    end
    if not ok then
        Print("could not register " .. name .. ": " .. tostring(err))
    end
end

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then return end
        f:UnregisterEvent("ADDON_LOADED")

        WS.InitDB()
        WS.ApplyLayout()

        TryEvent("PLAYER_ENTERING_WORLD")
        TryEvent("PLAYER_EQUIPMENT_CHANGED")
        TryEvent("PLAYER_LEVEL_UP")
        TryEvent("COMBAT_RATING_UPDATE")
        TryEvent("SPELL_POWER_CHANGED")
        TryEvent("PLAYER_DAMAGE_DONE_MODS")
        TryEvent("UNIT_AURA", "player")
        TryEvent("UNIT_STATS", "player")
        TryEvent("UNIT_ATTACK_POWER", "player")
        TryEvent("UNIT_RANGED_ATTACK_POWER", "player")
        TryEvent("UNIT_RANGEDDAMAGE", "player")
        TryEvent("UNIT_RESISTANCES", "player")
        TryEvent("UNIT_DAMAGE", "player")
        TryEvent("UNIT_ATTACK_SPEED", "player")
        TryEvent("UNIT_SPELL_HASTE", "player")
        TryEvent("UNIT_MAXPOWER", "player")
        return
    end

    RequestRender()
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

SLASH_WORMSTATS1 = "/wormstats"
SLASH_WORMSTATS2 = "/ws"

SlashCmdList.WORMSTATS = function(input)
    local db = WormStatsCharDB
    local cmd, arg = (input or ""):match("^(%S*)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()

    if cmd == "" or cmd == "config" or cmd == "options" then
        WS.ToggleOptions()

    elseif cmd == "lock" or cmd == "unlock" then
        db.locked = (cmd == "lock")
        WS.ApplyLayout()
        WS.RefreshOptions()

    elseif cmd == "scale" and tonumber(arg) then
        db.scale = math.min(math.max(tonumber(arg), 0.5), 3)
        WS.ApplyLayout(); WS.Render()

    elseif cmd == "font" and tonumber(arg) then
        db.fontSize = math.min(math.max(math.floor(tonumber(arg)), 8), 40)
        WS.ApplyLayout(); WS.Render()

    elseif cmd == "reset" then
        WS.InitDB(true)
        WS.ApplyLayout(); WS.Render()
        WS.RefreshOptions()

    else
        Print("/ws [config | lock | unlock | scale <n> | font <n> | reset]")
    end
end
