local nakamaMedia, _A, nakama = ...
local player, target, roster, enemies

-- fetch spell names and store them in locals for performance optimization
-- offensive
local crusaderStrike = _A.GetSpellInfo(1135395)
local judgmentOfLight = _A.GetSpellInfo(1120271)
-- aura
local devotionAura = _A.GetSpellInfo(1100465)
-- heal / bubble
local holyLight = _A.GetSpellInfo(1100635)
local divineProtection = _A.GetSpellInfo(1100498)
-- buff
local blessingOfMight = _A.GetSpellInfo(1119740)
-- seals
local sealOfRighteousness = _A.GetSpellInfo(1121084)
-- utility
local hammerOfJustice = _A.GetSpellInfo(1100853)
local purify = _A.GetSpellInfo(1101152)
-- generic
local drink = _A.GetSpellInfo(430)
local eat = _A.GetSpellInfo(433)

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

    -- check if we can cast Devotion Aura
    if player:SpellReady(devotionAura)
        -- cancel if we have buff already
        and not player:Buff(devotionAura) then
        -- cast Devotion Aura
        return player:Cast(devotionAura)
    end

    -- check if we can cast Divine Protection
    if player:SpellReady(divineProtection)
        -- cancel if hp % > 20
        and player:Health() < 21 then
        -- cast Holy Light on player
        return player:Cast(divineProtection)
    end

    -- check if we can cast Holy Light
    if player:SpellReady(holyLight)
        -- cancel if moving
        and not player:Moving()
        -- cancel if hp % > 40
        and player:Health() < 40 then
        -- cast Holy Light on player
        return player:Cast(holyLight)
    end

    -- check if we can cast Seal of Righteousness
    if player:SpellReady(sealOfRighteousness)
        -- cancel if we have buff already
        and not player:Buff(sealOfRighteousness) then
        -- cast Seal of Righteousness on player
        return player:Cast(sealOfRighteousness)
    end

    -- check if we can and need to cast purify
    if player:DebuffType("Poison || Disease")
        and player:SpellReady(purify)
        and player:Mana() > 75
        and player:LastcastSeen(purify) > 5 then
        return player:Cast(purify)
    end

        -- improved Hammer of Justice
    -- now takes all possible targets into consideration
    if player:SpellReady(hammerOfJustice) then
        enemies = _A.OM:Get("EnemyCombat")

        for _, enemy in pairs(enemies) do
            if enemy:IscastingAnySpell() then
                local _, total, ischanneled = enemy:CastingDelta()

                if not ischanneled then
                    if target:CastingPercent() >= 60
                        and total >= 0.275
                        and enemy:SpellRange(hammerOfJustice) then
                        return enemy:Cast(hammerOfJustice)
                    end
                end

                if ischanneled then
                    if enemy:ChannelingPercent() >= 15
                        and total >= 0.575
                        and enemy:SpellRange(hammerOfJustice) then
                        return enemy:Cast(hammerOfJustice)
                    end
                end
            end
        end
    end


    -- check if we have a target thats not dead or a friend
    if target and not (target:Dead() or target:Friend()) then
        -- check if we can cast Judgement of Light
        if player:SpellReady(judgmentOfLight)
            -- cancel if target not in range
            and target:SpellRange(judgmentOfLight)
            -- cancel if target not in los
            and target:Los() then
            -- cast Judgement of Light on target
            return target:Cast(judgmentOfLight) and player:timeout(judgmentOfLight, 0.25)
        end

        -- check if we can cast Crusader Strike
        if player:SpellReady(crusaderStrike)
            -- cancel if target not in range
            and target:SpellRange(crusaderStrike)
            -- cancel if target not in 130° cone in front
            and _A.UnitIsFacing(player.guid, target.guid, 130) then
            -- cast Crusader Strike on target
            return target:Cast(crusaderStrike) and player:timeout(crusaderStrike, 0.25)
        end
    end
end

local function outCombat()
    player = _A.Object("player")

    if not player then
        return true
    end

    -- cancel if casting
    if player:IscastingAnySpell()
        -- cancel if stunned or silenced
        -- racial implementation for dispel soon
        or player:State("stun || silence")
        -- cancel if mounted
        or player:Mounted()
        -- cancel if eating or drinking
        or (player:BuffAny(drink) or player:BuffAny(eat)) then
        -- reset loop
        return true
    end

    -- check if we can cast Devotion Aura
    if player:SpellReady(devotionAura)
        -- cancel if casting
        and not player:IscastingAnySpell()
        -- cancel if we have buff already
        and not player:Buff(devotionAura) then
        -- cast Devotion Aura
        return player:Cast(devotionAura)
    end

    -- check if we can and need to cast purify
    if player:DebuffType("Poison || Disease")
        and player:SpellReady(purify)
        and player:Mana() > 75
        and player:LastcastSeen(purify) > 5 then
        return player:Cast(purify)
    end

    -- check if we can cast Holy Light
    if player:SpellReady(holyLight)
        -- cancel if casting
        and not player:IscastingAnySpell()
        -- cancel if moving
        and not player:Moving()
        -- cancel if hp % > 40
        and player:Health() < 40 then
        -- cast Holy Light on player
        return player:Cast(holyLight)
    end

    -- check if we can cast Seal of Righteousness
    if player:SpellReady(sealOfRighteousness)
        -- cancel if casting
        and not player:IscastingAnySpell()
        -- cancel if we have buff already
        and not player:Buff(sealOfRighteousness) then
        -- cast Seal of Righteousness on player
        return player:Cast(sealOfRighteousness)
    end

    -- check if we can cast Blessing of Might
    if player:SpellReady(blessingOfMight) then
        -- if we are in group
        if player:Ingroup() then
            -- fetch roster
            roster = _A.OM:Get("Roster")

            -- for each mate in our roster
            for _, mate in pairs(roster) do
                if mate:Isplayer()
                    -- cancel if mate has any Blessing of Might buff
                    and not mate:BuffAny(blessingOfMight)
                    -- cancel if not in spellrange
                    and mate:SpellRange(blessingOfMight)
                    -- cancel if not los
                    and mate:Los() then
                    -- cast Blessing of Might on mate
                    return mate:Cast(blessingOfMight)
                end
            end
        else
            -- cancel if we have buff already
            if not player:BuffAny(blessingOfMight) then
                -- cast Blessing of Might on player
                return player:Cast(blessingOfMight)
            end
        end
    end
end



local spellIds_Loc = {}

local blacklist = {}

_A.CR:Add("Paladin", {
    name = "GentlePally - Leveling",
    ic = inCombat,
    ooc = outCombat,
    use_lua_engine = true,
    gui = gui,
    gui_st = { title = "GentlePally - Rotation Settings", color = "F48CBA", width = "315", height = "370" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    -- ids = spellIds_Loc,
    -- blacklist = blacklist,
    -- pooling = false,
    load = exeOnLoad,
    unload = exeOnUnload,
})
