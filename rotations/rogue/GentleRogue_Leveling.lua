--------------------------------------------------------------------------------
-- GentleRogue - Leveling
-- Author: Gentleman
-- Design: Light → Heavy order, no early exits blocking ranged spells,
-- zero redundant API calls, per-tick caching only.
--------------------------------------------------------------------------------
local nakama, _A, nakama = ...
local apepDir = _A.GetApepDirectory()
_A.require(apepDir .. "\\nakama\\modules\\nakamaLoot.lua")

-- Static data (resolved once)
local playerGUID = _A.Cache.Utils.playerGUID or _A.UnitGUID("player")

local spellLib = {
    SinisterStrike = _A.GetSpellInfo(1101752),
    SliceAndDice   = _A.GetSpellInfo(1105171),
    Eviscerate     = _A.GetSpellInfo(1102098),
    Evasion        = _A.GetSpellInfo(1105277),
    Throw          = _A.GetSpellInfo(2764),
}

local gui = {
    { type = "checkbox", cw = 10, ch = 10, text = "Enable Auto Loot", key = "auto_loot", default = true },
}

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------
local function exeOnLoad()
    if _A.UIErrorsFrame then _A.UIErrorsFrame:Hide() end
    _A.Sound_EnableErrorSpeech = 0
    nakama.addLootListener()
end

local function exeOnUnload()
    nakama.deleteLootListener()
end

--------------------------------------------------------------------------------
-- Combat rotation
-- Core logic ordered Light → Heavy but allows ranged fallback.
--------------------------------------------------------------------------------
local function inCombat()
    local player = _A.Object("player")
    if not player then return true end
    if player:IscastingAnySpell() or player:Mounted() or player:State("stun || silence") then
        return true
    end

    -- Defensive checks: costly but critical, done once per tick
    if player:SpellReady(spellLib.Evasion) then
        if player:Area_rangeCombatenemies(7) >= 3 or player:Health() < 20 then
            return player:Cast(spellLib.Evasion)
        end
    end

    -- Target validation (light check)
    local target = _A.Object("target")
    if not target or target:Dead() or target:Friend() then return true end

    -- Cache all runtime data locally
    local combo = player:Combo()
    local targetGUID = target.guid

    if player:SpellReady(spellLib.SliceAndDice) then
        if (not player:Buff(spellLib.SliceAndDice) or player:BuffRefreshable(spellLib.SliceAndDice)) and combo > 1 then
            return target:Cast(spellLib.SliceAndDice)
        end
    end

    local melee = target:SpellRange(spellLib.SinisterStrike)
    local facing = _A.UnitIsFacing(playerGUID, targetGUID, 130)

    -- If in melee range and facing, execute builder/finisher logic
    if melee and facing then
        -- Builder: cheap → heavy
        if combo < 5 and player:SpellReady(spellLib.SinisterStrike) then
            return target:Cast(spellLib.SinisterStrike)
        end

        -- Finisher: evaluated only when combo threshold reached
        if (combo == 5 or (combo > 2 and target:Ttd() < 5))
            and player:SpellReady(spellLib.Eviscerate) then
            return target:Cast(spellLib.Eviscerate)
        end
    end

    -- Ranged fallback: only executes when melee unreachable or invalid
    if player:SpellReady(spellLib.Throw) then
        local range = target:Range(2)
        -- Range check is lightweight numeric comparison; LoS & Infront are mid-cost
        if range > 7 and range < 30 and target:Infront() and target:Los() then
            return target:Cast(spellLib.Throw)
        end
    end
end

--------------------------------------------------------------------------------
-- Out-of-combat loop (keeps overhead minimal)
--------------------------------------------------------------------------------
local function outCombat()
    local player = _A.Object("player")
    if player and player:Ui("auto_loot") then
        nakama.autoLoot()
    end
end

--------------------------------------------------------------------------------
-- Routine registration
--------------------------------------------------------------------------------
_A.CR:Add("Rogue", {
    name = "GentleRogue - Leveling",
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
