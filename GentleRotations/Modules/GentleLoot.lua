--------------------------------------------------------------------------------
-- GentleLoot - Optimized Loot Manager for Apep
-- Author: Gentleman / Refactored by GPT-5
--
-- Goals:
--   • Eliminate redundant Object Manager calls (O(n²) → O(n))
--   • Use hash-based blacklist for constant-time lookups
--   • Avoid unnecessary GC spikes
--   • Maintain full Apep API compliance (_A.* untouched)
--------------------------------------------------------------------------------

local gentleMedia, _A, gentle = ...

--------------------------------------------------------------------------------
-- ⚙️ Internal state
--------------------------------------------------------------------------------
-- lootBlackList: a hash-table { [guid] = true } for O(1) access
-- Note: we no longer rely on ipairs/pairs iteration for membership checks
gentle.lootBlackList = {}

--------------------------------------------------------------------------------
-- 🧩 Loot Listener Management
--------------------------------------------------------------------------------

-- Adds the event listener that clears blacklist on combat start
gentle.addLootListener = function()
    _A.Listener:Add("GentleLoot", { "PLAYER_REGEN_DISABLED" }, function(event)
        if event == "PLAYER_REGEN_DISABLED" then
            -- Rebuild as an empty table instead of setting {} (avoids GC accumulation)
            for k in pairs(gentle.lootBlackList) do
                gentle.lootBlackList[k] = nil
            end
        end
    end)
end

-- Removes the event listener safely
gentle.deleteLootListener = function()
    _A.Listener:Remove("GentleLoot")
end

--------------------------------------------------------------------------------
-- 💰 Auto Loot Routine
--------------------------------------------------------------------------------
-- Complexity: O(n) over visible corpses (no nested loops)
-- Safe to call from Out-of-Combat loop.
--------------------------------------------------------------------------------

gentle.autoLoot = function()
    -- Check for bag space before attempting loot
    if _A.BagSpace() <= 0 then
        return false
    end

    -- Retrieve the "Dead" object table once (no repeated OM:Get calls)
    local deadUnits = _A.OM:Get("Dead")
    if not deadUnits then
        return false
    end

    -- Local reference for blacklist (short lookup)
    local blacklist = gentle.lootBlackList

    -- Iterate all nearby corpses once per frame
    for _, corpse in pairs(deadUnits) do
        -- Ensure valid corpse, lootable, and within interaction distance (~4.5 yd)
        if corpse:Hasloot() and corpse:Distance() < 4.5 then
            local guid = corpse.guid

            -- Skip if blacklisted (O(1) lookup)
            if not blacklist[guid] then
                -- Interact with corpse (Apep core handles UI and latency)
                _A.InteractUnit(guid)

                -- Mark as looted
                blacklist[guid] = true

                -- Clear target to avoid auto-targeting loop issues
                _A.ClearTarget()

                -- Return early (one corpse per frame to reduce packet spikes)
                return true
            end
        end
    end
end

--------------------------------------------------------------------------------
-- ✅ Summary of Optimizations
--------------------------------------------------------------------------------
-- • O(1) blacklist lookups (hash instead of list search)
-- • No collectgarbage() calls → stable frame time
-- • Single OM:Get('Dead') per execution
-- • One InteractUnit() per frame → avoids lag spikes
-- • No memory churn (blacklist cleared in-place)
--------------------------------------------------------------------------------
