--------------------------------------------------------------------------------
-- nakamaLoot - Module
-- Author: TheGentleman
--------------------------------------------------------------------------------
local nakama, _A, nakama = ...

-- Local blacklist cache (O(1) lookups)
nakama.lootBlackList = {}

--------------------------------------------------------------------------------
-- Listener: reset blacklist when entering combat
--------------------------------------------------------------------------------
function nakama.addLootListener()
    _A.Listener:Add("nakamaLoot", { "PLAYER_REGEN_DISABLED" }, function(event)
        if event == "PLAYER_REGEN_DISABLED" then
            for k in pairs(nakama.lootBlackList) do
                nakama.lootBlackList[k] = nil
            end
        end
    end)
end

--------------------------------------------------------------------------------
-- Listener removal
--------------------------------------------------------------------------------
function nakama.deleteLootListener()
    _A.Listener:Remove("nakamaLoot")
end

--------------------------------------------------------------------------------
-- Auto-loot routine
-- Runs O(n) over visible corpses
--------------------------------------------------------------------------------
function nakama.autoLoot()
    if _A.BagSpace() < 1 then return false end

    local corpses = _A.OM:Get("Dead")
    local blacklist = nakama.lootBlackList
    local now = _A.GetTime()

    for _, corpse in pairs(corpses) do
        if corpse:Hasloot() and corpse:Distance() < 4.5 then
            local guid = corpse.guid
            if not blacklist[guid] and player:delay("nakamaLoot", 0.5) then
                _A.InteractUnit(guid)
                blacklist[guid] = true
                _A.ClearTarget()
                return true
            end
        end
    end
end

_A.Core:WhenInGame(function()
    print("nakama - loot module loaded!")
end)
