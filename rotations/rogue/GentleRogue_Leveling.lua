--------------------------------------------------------------------------------
-- GentleRogue - Leveling
-- Author: Gentleman
--------------------------------------------------------------------------------
local nakama, _A, nakama = ...
local apepDir = _A.GetApepDirectory()
_A.require(apepDir .. "\\nakama\\modules\\nakamaLoot.lua")

-- Cache static values (avoid repeat _A.* calls)
local playerGUID = _A.Cache.Utils.playerGUID or _A.UnitGUID("player")

-- Spell constants (resolved once)
local spellLib = {
    SinisterStrike = _A.GetSpellInfo(1101752),
    Eviscerate     = _A.GetSpellInfo(1102098),
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
-- Combat loop
-- Avoids allocations, table walks, and excessive unit calls.
--------------------------------------------------------------------------------
local function inCombat()
    local player = _A.Object("player")
    if not player then return true end
    if player:IscastingAnySpell() or player:Mounted() or player:State("stun || silence") then return true end

    local target = _A.Object("target")
    if not target then return true end

    local targetGUID = target.guid

    if target:Dead() or target:Friend() then return true end

    local combo = player:Combo()

    -- Melee facing (fastest valid check)
    if _A.UnitIsFacing(playerGUID, targetGUID, 130) then
        -- Builder
        if combo < 5
            and player:SpellReady(spellLib.SinisterStrike)
            and target:SpellRange(spellLib.SinisterStrike) then
            return target:Cast(spellLib.SinisterStrike)
        end

        -- Finisher
        if combo == 5
            and player:SpellReady(spellLib.Eviscerate)
            and target:SpellRange(spellLib.Eviscerate) then
            return target:Cast(spellLib.Eviscerate)
        end
    end

    -- Optional ranged pull
    if player:SpellReady(spellLib.Throw) then
        local tarRange = target:Range(2)
        if tarRange > 7
            and tarRange < 30
            and target:Infront()
            and target:Los() then
            return target:Cast(spellLib.Throw)
        end
    end
end

--------------------------------------------------------------------------------
-- Out-of-combat loop
--------------------------------------------------------------------------------
local function outCombat()
    local player = _A.Object("player")
    if not player then return true end
    if player:Ui("auto_loot") then nakama.autoLoot() end
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
