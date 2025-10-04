local nakamaMedia, _A, nakama = ...
local player, target

local gui = {}

local function crusaderStrike()
    local cS = _A.GetSpellInfo(1135395)

    if not player:SpellReady(cS) then return false end
    if player:IscastingAnySpell() then return false end
    if player:State("stun || silence") then return false end
    if not target then return false end
    if target:Dead() then return false end
    if target:Friend() then return false end
    if not target:SpellRange(cS) then return false end
    local isFacingTarget = _A.UnitIsFacing(player.guid, target.guid, 130)
    if not isFacingTarget then return false end
    if not target:SpellRange(cS) then return false end
    if not target:Los() then return false end

    return target:Cast(cS)
end

local exeOnLoad = function() end

local exeOnUnload = function() end

local inCombat = function()
    player = _A.Object("player")

    if not player then
        return false
    end

    target = _A.Object("target")

    if crusaderStrike() then
        return true
    end
end

local outCombat = function()
    player = _A.Object("player")

    if not player then
        return false
    end

    target = _A.Object("target")
end

local spellIds_Loc = {}

local blacklist = {}

_A.CR:Add("Paladin", {
    name = "Nakama - Leveling (PVE)",
    ic = inCombat,
    ooc = outCombat,
    use_lua_engine = true,
    gui = gui,
    gui_st = { title = "CR Settings", color = "87CEFA", width = "315", height = "370" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    -- ids = spellIds_Loc,
    -- blacklist = blacklist,
    -- pooling = false,
    load = exeOnLoad,
    unload = exeOnUnload,
})
