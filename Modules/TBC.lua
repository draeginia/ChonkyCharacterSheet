local addonName, ns = ...
local CCS = ns.CCS

local module = {
    Name = "TBC Module",
    CompatibleVersions = { CCS.TBC },
    OnInitialize = function(self)
        --print(self.Name .. " initialized for TBC")
    end,
}

CCS.Modules[module.Name] = module

-- Event handler for TBC
function CCS.TBCEventHandler(event, ...)
    local arg1, arg2, arg3 = ...

    if event == "BOSS_KILL" then
        --module:OnBossKill(arg1)
    elseif event == "LOOT_READY" then
        --module:OnLootReady()
    elseif event == "PLAYER_LEAVE_COMBAT" then
        --module:OnLeaveCombat()
    end
end

---------------------------
-- Module methods
---------------------------
function module:Initialize() 
    -- Optional setup for the TBC module
    --print("[CCS] TBC initialized")

end