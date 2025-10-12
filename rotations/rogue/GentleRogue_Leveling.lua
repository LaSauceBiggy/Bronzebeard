local nakamaMedia, _A, nakama = ...
local player, target, targetGUID, facing, enemies
local playerGUID = _A.Cache.Utils.playerGUID or _A.UnitGUID("player")
-- empty pp blacklist table for initalization
local ppBlackList = {}
-- initalize lastPP target
local lastppTarget = nil

-- spell block
--> cp builder
local sinisterStrike = _A.GetSpellInfo(1101752)
--> finisher
local eviscerate = _A.GetSpellInfo(1102098)
--> generic
local throw = _A.GetSpellInfo(2764)
--> pick pocket
local pickPocket = _A.GetSpellInfo(1100921)

-- to do: gui settings and modifiers
local gui = {}

local function exeOnLoad()
    _A.UIErrorsFrame:Hide()
    _A.Sound_EnableErrorSpeech = 0
end

local function exeOnUnload()

end

local function inCombat()
    player = _A.Object("player")

    -- early reset loop if player does not exist
    if not player then
        return true
    end

    -- reset loop if casting (slam or item for example)
    if player:IscastingAnySpell()
        -- reset loop if mounted
        or player:Mounted() then
        return true
    end

    -- reset loop if stunned or silenced
    -- racial implementation for dispel soon
    if player:State("stun || silence") then
        return true
    end

    target = _A.Object("target")

    -- check if we have a target thats not dead or a friend
    if target then
        targetGUID = target.guid

        if target:Alive() and target:Enemy() then
            facing = _A.UnitIsFacing(playerGUID, targetGUID, 130)

            if player:SpellReady(sinisterStrike)
                and player:Combo() < 5
                and target:SpellRange(sinisterStrike)
                and facing then
                return target:Cast(sinisterStrike)
            end

            if player:SpellReady(eviscerate)
                and player:Combo() == 5
                and target:SpellRange(sinisterStrike)
                and facing then
                return target:Cast(eviscerate)
            end
        end
    end
end

local function outCombat()
    player = _A.Object("player")

    if not player then
        return true
    end

    -- check if we have a target thats not dead or a friend
    if target then
        targetGUID = target.guid

        if target:Alive() and target:Enemy() then
            facing = _A.UnitIsFacing(playerGUID, targetGUID, 130)
        end
    end
end

_A.CR:Add("Rogue", {
    name = "GentleRogue - Leveling",
    ic = inCombat,
    ooc = outCombat,
    use_lua_engine = true,
    gui = gui,
    gui_st = { title = "GentleRogue - Rotation Settings", color = "FFF468", width = "315", height = "370" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    -- ids = spellIds_Loc,
    -- blacklist = blacklist,
    -- pooling = false,
    load = exeOnLoad,
    unload = exeOnUnload,
})
