local nakamaMedia, _A, nakama = ...
local player, playerGUID, target, targetGUID
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

    playerGUID = player.guid
    target = _A.Object("target")

    -- cancel if casting (slam or item for example)
    if player:IscastingAnySpell()
        -- cancel if stunned or silenced
        -- racial implementation for dispel soon
        or player:State("stun || silence")
        -- cancel if mounted
        or player:Mounted() then
        -- reset loop
        return
    end

    if player:SpellReady(rend) then
        local enemies = _A.OM:Get("EnemyCombat")
        local enemyCount = #enemies

        -- Calculate maxCount: 50% of enemies (rounded up), min 1, max 3
        local maxCount = math.min(math.max(1, math.ceil(enemyCount * 0.5)), 3)
        local count = 0

        for _, enemy in pairs(enemies) do
            if enemy:Distance() < 8 then
                local hasRend = enemy:Debuff(rend)

                if hasRend then
                    count = count + 1
                end

                if count < maxCount then
                    local facing = _A.UnitIsFacing(playerGUID, enemy.guid, 130)
                    -- Apply Rend if not yet applied
                    if not hasRend and enemy:Health() > 15 and enemy:SpellRange(rend) and facing then
                        return enemy:Cast(rend)
                    end
                end
            end
        end
    end

    -- check if we have a target thats not dead or a friend
    if target then
        targetGUID = target.guid

        if target:Alive() and target:Enemy() then
            local facing = _A.UnitIsFacing(playerGUID, targetGUID, 130)

            if player:SpellReady(heroicStrike)
                and target:SpellRange(heroicStrike)
                and facing then
                return target:Cast(heroicStrike)
            end
        end
    end
end

local function outCombat()
    player = _A.Object("player")

    if not player then
        return true
    end

    playerGUID = player.guid
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
