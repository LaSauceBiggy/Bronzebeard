local nakamaMedia, _A, nakama = ...
local player, target, enemies, count, facing
local rend = _A.GetSpellInfo(1100772)
local heroicStrike = _A.GetSpellInfo(1100078)

-- to do: gui settings and modifiers
local gui = {}

local function exeOnLoad()
    _A.UIErrorsFrame:Hide()
    _A.Sound_EnableErrorSpeech = 0
end

local function exeOnUnload() end

local function inCombat()
    player = _A.Object("player")

    if not player then
        return true
    end

    target = _A.Object("target")

    -- cancel if casting
    if player:IscastingAnySpell()
        -- cancel if stunned or silenced
        -- racial implementation for dispel soon
        or player:State("stun || silence")
        -- cancel if mounted
        or player:Mounted() then
        -- reset loop
        return true
    end

    if player:SpellReady(rend) then
        enemies = _A.OM:Get("EnemyCombat")
        count = 0

        for _, enemy in pairs(enemies) do
            facing = _A.UnitIsFacing(player.guid, enemy.guid, 130)

            if enemy:Debuff(rend) then
                count = count + 1
            end

            if count < 3 then
                if not enemy:Debuff(rend)
                    and enemy:Health() > 15
                    and enemy:SpellRange(rend) then
                    return enemy:Cast(rend)
                end
            end
        end
    end

    -- check if we have a target thats not dead or a friend
    if target and not (target:Dead() or target:Friend()) then
        facing = _A.UnitIsFacing(player.guid, target.guid, 130)
        if player:SpellReady(heroicStrike)
            and not player:CurrentSpell(heroicStrike) then
            if target:SpellRange(heroicStrike)
                and facing then
                return target:Cast(heroicStrike, true)
            end
        end
    end
end

local function outCombat()
    player = _A.Object("player")

    if not player then
        return true
    end
end

_A.CR:Add("Warrior", {
    name = "GentleWarri - Leveling",
    ic = inCombat,
    ooc = outCombat,
    use_lua_engine = true,
    gui = gui,
    gui_st = { title = "GentleWarri - Rotation Settings", color = "C69B6D", width = "315", height = "370" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    -- ids = spellIds_Loc,
    -- blacklist = blacklist,
    -- pooling = false,
    load = exeOnLoad,
    unload = exeOnUnload,
})
