--------------------------------------------------------------------------------
-- GentleRogue - Leveling Rotation
-- Author: Gentleman
-- Notes:
--  - Uses native Lua mode, no DSL.
--  - Prioritizes CPU efficiency, GC avoidance, and correct facing handling.
--  - Designed for Apep v1.1+ (WoW 3.3.5 client).
--------------------------------------------------------------------------------

local gentleMedia, _A, gentle = ...
local apepDir = _A.GetApepDirectory()
_A.require(apepDir .. "\\GentleRotations\\Modules\\GentleLoot.lua")

--------------------------------------------------------------------------------
-- ⚙️ Constants and Cache
--------------------------------------------------------------------------------
local playerGUID = _A.Cache.Utils.playerGUID or _A.UnitGUID("player")

-- Spell IDs are resolved once for efficiency.
-- _A.GetSpellInfo() returns the localized spell name (string) for casting.
local SPELL = {
    SINISTER_STRIKE = _A.GetSpellInfo(1101752),
    EVISCERATE      = _A.GetSpellInfo(1102098),
    THROW           = _A.GetSpellInfo(2764),
}

-- Minimal GUI stub for later use
local gui = {}

--------------------------------------------------------------------------------
-- 🧠 Lifecycle Functions
--------------------------------------------------------------------------------

local function exeOnLoad()
    -- Disable error sounds & messages (optional QoL)
    if _A.UIErrorsFrame then _A.UIErrorsFrame:Hide() end
    _A.Sound_EnableErrorSpeech = 0

    -- Initialize loot listener
    gentle.addLootListener()
end

local function exeOnUnload()
    -- Clean listener
    gentle.deleteLootListener()
end

--------------------------------------------------------------------------------
-- ⚔️ Combat Loop (Main Rotation)
--------------------------------------------------------------------------------
-- This function executes on every frame while in combat.
-- Complexity: O(1) per iteration (no nested loops or OM queries).
--------------------------------------------------------------------------------
local function inCombat()
    -- Get the player object once per tick
    local player = _A.Object("player")
    if not player then return true end

    -- Early exit: casting, mounted, or CCed (stun/silence)
    if player:IscastingAnySpell()
        or player:Mounted()
        or player:State("stun || silence") then
        return true
    end

    -- Get target object and ensure it’s a valid enemy
    local target = _A.Object("target")
    if not target or not target:Alive() or target:Friend() then
        return true
    end

    -- Cache GUIDs for facing checks (avoids multiple table lookups)
    local targetGUID = target.guid

    -- Ensure target is within facing cone (130° for melee)
    local facing = _A.UnitIsFacing(playerGUID, targetGUID, 130)
    if not facing then return true end

    -- Retrieve combo points (cheap accessor)
    local combo = player:Combo()

    -- === COMBO BUILDERS ===
    if combo < 5
        and player:SpellReady(SPELL.SINISTER_STRIKE)
        and target:SpellRange(SPELL.SINISTER_STRIKE) then
        return target:Cast(SPELL.SINISTER_STRIKE)
    end

    -- === FINISHERS ===
    if combo == 5
        and player:SpellReady(SPELL.EVISCERATE)
        and target:SpellRange(SPELL.EVISCERATE) then
        return target:Cast(SPELL.EVISCERATE)
    end

    -- === FALLBACK ===
    -- Optional: ranged pull if no melee range or combo
    if player:SpellReady(SPELL.THROW)
        and not target:SpellRange(SPELL.SINISTER_STRIKE) then
        return target:Cast(SPELL.THROW)
    end
end

--------------------------------------------------------------------------------
-- 🪣 Out-of-Combat Loop
--------------------------------------------------------------------------------
-- Handles autolooting and other non-combat tasks.
--------------------------------------------------------------------------------
local function outCombat()
    local player = _A.Object("player")
    if not player then return true end

    -- Safe auto-loot call (non-blocking)
    gentle.autoLoot()
end

--------------------------------------------------------------------------------
-- 🧩 Register Combat Routine
--------------------------------------------------------------------------------
_A.CR:Add("Rogue", {
    name = "GentleRogue - Leveling (Optimized)",
    ic = inCombat,
    ooc = outCombat,
    use_lua_engine = true,
    gui = gui,
    gui_st = { title = "GentleRogue - Rotation Settings", color = "FFF468", width = "315", height = "370" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    load = exeOnLoad,
    unload = exeOnUnload,
})
