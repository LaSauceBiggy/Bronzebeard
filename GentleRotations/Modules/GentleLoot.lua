--------------------------------------------------------------------------------
-- GentleLoot - Module
-- Author: Gentleman
--------------------------------------------------------------------------------
local gentleMedia, _A, gentle = ...

-- Local blacklist cache (O(1) lookups)
gentle.lootBlackList = {}

--------------------------------------------------------------------------------
-- Listener: reset blacklist when entering combat
--------------------------------------------------------------------------------
function gentle.addLootListener()
    _A.Listener:Add("GentleLoot", { "PLAYER_REGEN_DISABLED" }, function(event)
        if event == "PLAYER_REGEN_DISABLED" then
            for k in pairs(gentle.lootBlackList) do
                gentle.lootBlackList[k] = nil
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- Listener removal
--------------------------------------------------------------------------------
function gentle.deleteLootListener()
    _A.Listener:Remove("GentleLoot")
end

--------------------------------------------------------------------------------
-- Auto-loot routine
-- Runs O(n) over visible corpses, single interact per frame
--------------------------------------------------------------------------------
function gentle.autoLoot()
    if _A.BagSpace() < 1 then return false end

    local corpses = _A.OM:Get("Dead")
    if not corpses then return false end

    local blacklist = gentle.lootBlackList

    for _, corpse in pairs(corpses) do
        if corpse:Hasloot() and corpse:Distance() < 4.5 then
            local guid = corpse.guid
            if not blacklist[guid] then
                _A.InteractUnit(guid)
                blacklist[guid] = true
                _A.ClearTarget()
                return true
            end
        end
    end
end
