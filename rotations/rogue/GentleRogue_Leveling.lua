--------------------------------------------------------------------------------
-- GentleRogue - Leveling
-- Author: Gentleman
-- Design: Light → Heavy order, no early exits blocking ranged spells,
-- zero redundant API calls, per-tick caching only.
--------------------------------------------------------------------------------
local nakama, _A, nakama = ...
local apepDir = _A.GetApepDirectory()
_A.require(apepDir .. "\\nakama\\rogue\\spells.lua")
_A.require(apepDir .. "\\nakama\\modules\\nakamaLoot.lua")
_A.require(apepDir .. "\\nakama\\modules\\potions.lua")
local spellLib = nakama.spellBook.Rogue

-- Static data (resolved once)
local playerGUID = _A.Cache.Utils.playerGUID or _A.UnitGUID("player")

local gui = {
    {
        type = "section",
        dummy = true,
        contentHeight = 18
    },
    {
        type = "spacer",
        size = 1,
    },
    {
        type = "header",
        text = "GentleRogue - Leveling" .. "|r",
        size = 16,
        align = "CENTER"
    },
    {
        type = "section",
        size = 14,
        text = "Potions",
        align = "center",
        contentHeight = 40,
        expanded = false,
        height = 20,
    },
    { type = "spacer" },
    {
        type = "section",
        size = 14,
        text = "QOL",
        align = "center",
        contentHeight = 40,
        expanded = false,
        height = 20,
    },

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

local function pauseCast()
    if player:IscastingAnySpell() then
        return true
    end
end

local function pauseStateOrMounted()
    if player:Mounted() or player:State("stun || silence") then
        return true
    end
end

local function defensives()
    if player:SpellReady(spellLib.Evasion) then
        if player:Health() < 20 and player:Area_rangeCombatenemies(7) > 0 then
            return player:Cast(spellLib.Evasion)
        end
    end
end

local function sliceAndDice()
    if player:SpellReady(spellLib.SliceAndDice) then
        if player:Combo() > 1
            and (not player:Buff(spellLib.SliceAndDice) or player:BuffRefreshable(spellLib.SliceAndDice)) then
            return target:Cast(spellLib.SliceAndDice)
        end
    end
end

local function main()
    if target:SpellRange(spellLib.SinisterStrike) and _A.UnitIsFacing(player.guid, target.guid, 130) then
        if (player:Combo() == 5 or (player:Combo() > 2 and target:Ttd() < 5))
            and player:SpellReady(spellLib.Eviscerate) then
            return target:Cast(spellLib.Eviscerate)
        end

        if player:Combo() < 5 and player:SpellReady(spellLib.SinisterStrike) then
            return target:Cast(spellLib.SinisterStrike)
        end
    end
end

local function throw()
    if target and player:SpellReady(spellLib.Throw) then
        local range = target:Range(2)
        if range > 7 and range < 30 and target:Infront() and target:Los() then
            return target:Cast(spellLib.Throw)
        end
    end
end

--------------------------------------------------------------------------------
-- Combat rotation
-- Core logic ordered Light → Heavy but allows ranged fallback.
--------------------------------------------------------------------------------
local function inCombat()
    if not player then return true end

    if pauseCast() then
        return true
    end

    if pauseStateOrMounted() then
        return true
    end

    if defensives() then
        return true
    end

    if not target or target:Dead() or target:Friend() then return true end

    if sliceAndDice() then
        return true
    end

    if main() then
        return true
    end

    if throw() then
        return true
    end
end

--------------------------------------------------------------------------------
-- Out-of-combat loop (keeps overhead minimal)
--------------------------------------------------------------------------------
local function outCombat()
    if not player then return true end

    if player:Ui("auto_loot") and nakama.autoLoot() then
        return true
    end

    --[[     if nakama:useHealthPotion() then
        return true
    end ]]
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
    gui_st = { title = "Settings", color = "FFF468", width = "200", height = "200" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    load = exeOnLoad,
    unload = exeOnUnload,
})
