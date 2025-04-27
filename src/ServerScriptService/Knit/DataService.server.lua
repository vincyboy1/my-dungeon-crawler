-- src/ServerScriptService/Knit/DataService.server.lua

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1) Require Knit
local Knit = require(ReplicatedStorage.Knit.Knit)
print("[DataService] Knit loaded:", Knit)

-- 2) Require your toolbox‐imported ProfileService
local ProfileService = require(ReplicatedStorage.SharedModules.ProfileService)
print("[DataService] ProfileService loaded:", ProfileService)

-- 3) Your data template
local DEFAULT_DATA = {
    Gold               = 0,
    TotalRunsPlayed    = 0,
    BestDungeonLevel   = 0,
    ClassesUnlocked    = { Warrior = true, Ranger = true, Mage = true },
    EvolvedUnlocked    = {},
    VestigesUnlocked   = {},
    Cosmetics          = {},
}

-- 4) Create the service at module load (before Knit.Start)
local DataService = Knit.CreateService { Name = "DataService" }

-- 5) In KnitInit, call ProfileService.New (uppercase “N”!) to make the store
function DataService:KnitInit()
    print("[DataService] :KnitInit — creating ProfileStore")
    self.ProfileStore = ProfileService.New("DungeonCrawlerData", DEFAULT_DATA)
    print("[DataService] ProfileStore instance →", self.ProfileStore)
    self.Profiles = {}
end

-- 6) In KnitStart, wire up StartSessionAsync / EndSession
function DataService:KnitStart()
    print("[DataService] :KnitStart — hooking PlayerAdded/Removing")

    Players.PlayerAdded:Connect(function(player)
        local key = "Player_" .. player.UserId
        print("[DataService] Starting session for", key)

        -- Use StartSessionAsync (not LoadProfileAsync)
        local profile = self.ProfileStore:StartSessionAsync(key)
        if not profile then
            warn("[DataService] ❌ Could not start session for", player.Name)
            player:Kick("Data load error.")
            return
        end

        -- Reconcile fills in any missing defaults
        profile:Reconcile()
        print("[DataService] Profile reconciled for", player.Name, "▶", profile.Data)

        -- Clean up when session ends elsewhere
        profile.OnSessionEnd:Connect(function()
            print("[DataService] Session ended for", player.Name)
            self.Profiles[player] = nil
        end)

        -- Keep it for PlayerRemoving
        self.Profiles[player] = profile
        print("[DataService] ✅ Session stored for", player.Name)
    end)

    Players.PlayerRemoving:Connect(function(player)
        local profile = self.Profiles[player]
        if profile then
            print("[DataService] Ending session for", player.Name)
            profile:EndSession()
        end
    end)
end

return DataService