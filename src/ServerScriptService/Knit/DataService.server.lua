-- src/ServerScriptService/Knit/DataService.server.lua

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1) Load Knit from your Knit folder
local Knit = require(ReplicatedStorage.Knit.Knit)
print("[DataService] Knit loaded:", Knit)

-- 2) Load the ProfileService you placed under SharedModules
local ProfileService = require(ReplicatedStorage.SharedModules.ProfileService)
print("[DataService] ProfileService loaded:", ProfileService)

-- 3) Define your default template
local DEFAULT_DATA = {
    Gold               = 0,
    TotalRunsPlayed    = 0,
    BestDungeonLevel   = 0,
    ClassesUnlocked    = { Warrior = true, Ranger = true, Mage = true },
    EvolvedUnlocked    = {},
    VestigesUnlocked   = {},
    Cosmetics          = {},
}

-- 4) Create the Knit service at load time
local DataService = Knit.CreateService { Name = "DataService" }

-- 5) Initialize your ProfileStore *before* Knit.Start()
function DataService:KnitInit()
    print("[DataService] :KnitInit — creating ProfileStore")
    -- use lowercase .new
    self.ProfileStore = ProfileService.new("DungeonCrawlerData", DEFAULT_DATA)
    print("[DataService] ProfileStore instance →", self.ProfileStore)
    self.Profiles = {}
end

-- 6) Wire up join/leave in KnitStart
function DataService:KnitStart()
    print("[DataService] :KnitStart — hooking PlayerAdded/Removing")

    Players.PlayerAdded:Connect(function(player)
        local key = "Player_" .. player.UserId
        print("[DataService] Starting session for", key)

        -- use StartSessionAsync, not LoadProfileAsync
        local profile = self.ProfileStore:StartSessionAsync(key)
        if not profile then
            warn("[DataService] ❌ Could not start session for", player.Name)
            player:Kick("Data load error.")
            return
        end

        -- fill in any missing defaults
        profile:Reconcile()
        print("[DataService] Profile reconciled for", player.Name, "▶", profile.Data)

        -- clean up if session ends elsewhere
        profile.OnSessionEnd:Connect(function()
            print("[DataService] Session ended for", player.Name)
            self.Profiles[player] = nil
        end)

        -- store for PlayerRemoving
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
