local nakamaMedia, _A, nakama = ...
local player, target, roster, enemies

-- fetch spell names and store them in locals for performance optimization
-- offensive
local crusaderStrike = _A.GetSpellInfo(1135395)
local judgmentOfLight = _A.GetSpellInfo(1120271)
local consecration = _A.GetSpellInfo(1126573)
-- aura
local retributionAura = _A.GetSpellInfo(1107294)
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
local gui = {
    key = "gentlepally_config",
    title = "GentlePally - Leveling Settings",
    width = 320,
    height = 200,
    profiles = true,
    config = {
        { type = "header", text = "General Settings" },
        { type = "checkbox", text = "Enable AoE", key = "aoe_enabled", default = true },
        { type = "spinner", text = "Min Enemies for AoE", key = "aoe_threshold", default = 2, min = 1, max = 10, step = 1 },
    { type = "spinner", text = "Min Mana % for Consecration", key = "consecration_mana", default = 50, min = 0, max = 100, step = 5 },
    { type = "spinner", text = "Consecration cast delay (s)", key = "consecration_delay", default = 0.25, min = 0, max = 2, step = 0.05 },
        { type = "combo", text = "Aura to Maintain", key = "aura_type", default = "devotion", list = {
            { key = "devotion", text = "Devotion Aura" },
            { key = "retribution", text = "Retribution Aura" },
        } },
        { type = "spacer" },
        { type = "header", text = "Defensives" },
        { type = "spinner", text = "Divine Protection HP %", key = "dp_hp", default = 20, min = 5, max = 100, step = 5 },
    }
}

-- Plugin GUI registration removed to avoid duplicate menus
-- Settings are accessible via Combat Routines Settings panel only

-- Read UI values directly from player:ui (no Interface:Fetch)
local function UiGet(key, default)
    if not (_A and _A.Object and type(_A.Object) == "function") then return default end
    local pl = _A.Object("player")
    if not (pl and type(pl.ui) == "function") then return default end
    -- spinner suffix first
    local ok_spin, v_spin = pcall(pl.ui, pl, key .. "_spin")
    if ok_spin and v_spin ~= nil then return v_spin end
    -- checkbox suffix
    local ok_check, v_check = pcall(pl.ui, pl, key .. "_check")
    if ok_check and v_check ~= nil then return v_check end
    -- exact key
    local ok_exact, v_exact = pcall(pl.ui, pl, key)
    if ok_exact and v_exact ~= nil then return v_exact end
    return default
end

local function GetPreferredAura()
    local sel = UiGet("aura_type", "devotion")
    -- Debug: show raw aura variables
    -- (useful to detect nil/failed GetSpellInfo)
    if sel == "retribution" then
        if not retributionAura or type(retributionAura) ~= "string" then
            print("[GentlePally] Warning: retributionAura not available (GetSpellInfo failed?). Falling back to Devotion.")
            return devotionAura
        end
        return retributionAura
    end
    -- default: devotion
    if not devotionAura or type(devotionAura) ~= "string" then
        print("[GentlePally] Warning: devotionAura not available (GetSpellInfo failed?)")
    end
    return devotionAura
end

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

    -- check if we can cast the preferred Aura
    do
    local sel = UiGet("aura_type", "devotion")
        local aura = GetPreferredAura()
        -- Debug: show selected config and chosen aura
        if aura and player:SpellReady(aura) and not player:Buff(aura) then
            return player:Cast(aura)
        end
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

    -- AoE: Consecration when multiple enemies are nearby (fall back to target for single-target)
    do
    local aoe_enabled = UiGet("aoe_enabled", true)
    local threshold = UiGet("aoe_threshold", 2)
    local mana_req = UiGet("consecration_mana", 50)
    local delay_req = UiGet("consecration_delay", 0.25)

        if aoe_enabled and player:SpellReady(consecration) and not player:Moving() and player:Mana() >= mana_req then
            local enemies = _A.OM:Get("EnemyCombat")
            local cnt = 0
            if enemies and type(enemies) == "table" then
                for _, e in pairs(enemies) do
                    if e and not e:Dead() then
                        cnt = cnt + 1
                    end
                end
            end

            -- If OM returned no enemies, but we have a valid hostile target in range, treat as 1
            if cnt == 0 and target and not target:Dead() and not target:Friend() then
                local ok, inrange = pcall(function() return target:SpellRange(consecration) end)
                if ok and inrange then
                    cnt = 1
                end
            end

            -- Cast if enough enemies meet threshold
            if cnt >= threshold then
                return player:Cast(consecration) and player:timeout(consecration, delay_req)
            end
        end
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

    -- check if we can cast the preferred Aura
    do
        local aura = GetPreferredAura()
        if aura and player:SpellReady(aura) and not player:IscastingAnySpell() and not player:Buff(aura) then
            return player:Cast(aura)
        end
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
    gui = gui.config,
    gui_st = { title = "GentlePally - Rotation Settings", color = "F48CBA", width = "315", height = "370" },
    wow_ver = "3.3.5",
    apep_ver = "1.1",
    -- ids = spellIds_Loc,
    -- blacklist = blacklist,
    -- pooling = false,
    load = exeOnLoad,
    unload = exeOnUnload,
})
