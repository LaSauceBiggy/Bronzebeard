local nakamaMedia, _A, nakama = ...
nakama.lootBlackList = {}

nakama.addLootListener = function()
    _A.Listener:Add(
        "GentleLoot",
        { "PLAYER_REGEN_DISABLED" },
        function(event, ...)
            if event == "PLAYER_REGEN_DISABLED" then
                nakama.lootBlackList = {}
                collectgarbage()
            end
        end)
end

nakama.deleteLootListener = function ()
    _A.Listener:Remove("GentleLoot")
end

nakama.autoLoot = function()
    local ded = _A.OM:Get("Dead")

    for _, corpse in pairs(ded) do
        if corpse:Hasloot() and corpse:Distance() < 4.5 then
            local guid = corpse.guid
            local isBlacklisted = false

            -- Check if this corpse is already in blacklist
            for _, badID in ipairs(nakama.lootBlackList) do
                if badID == guid then
                    isBlacklisted = true
                    break
                end
            end

            -- Only loot if not blacklisted
            if not isBlacklisted then
                _A.InteractUnit(guid)
                table.insert(nakama.lootBlackList, guid)
                _A.ClearTarget()
                return true
            end
        end
    end
end
