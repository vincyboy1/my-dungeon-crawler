-- ServerScriptService/Knit/DataService.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1) Require Knit from the correct path
local Knit = require(ReplicatedStorage.Knit.Knit)
print("[DataService] Knit loaded:", Knit)

-- 2) Require your ProfileService
local ProfileService = require(ReplicatedStorage.SharedModules.ProfileService)
print("[DataService] ProfileService loaded:", ProfileService)

-- 3) Default template
local DEFAULT_DATA = {
    Gold               = 0,
    TotalRunsPlayed    = 0,
    BestDungeonLevel   = 0,
    ClassesUnlocked    = { Warrior = true, Ranger = true, Mage = true },
    EvolvedUnlocked    = {},
    VestigesUnlocked   = {},
    Cosmetics          = {},
}

-- 4) Create the service (this must happen *before* Knit.Start)
local DataService = Knit.CreateService {
    Name = "DataService",
}

function DataService:KnitStart()
    print("[DataService] :KnitStart() called")

    -- 5) Create the store using the API your module provides
    self.ProfileStore = ProfileService.GetProfileStore(
        "DungeonCrawlerData",
        DEFAULT_DATA
    )
    print("[DataService] ProfileStore created:", self.ProfileStore)

    self.Profiles = {}

    -- 6) Load on player join
    Players.PlayerAdded:Connect(function(player)
        print("[DataService] PlayerAdded:", player.Name)
        local key = "Player_" .. player.UserId
        print("[DataService] Loading profile for key:", key)

        -- Use the LoadProfileAsync call your version supports
        local profile = self.ProfileStore:LoadProfileAsync(key, "ForceLoad")
        if not profile then
            warn("[DataService] ❌ Failed to load profile for", player.Name)
            player:Kick("Data load error. Please rejoin.")
            return
        end

        print("[DataService] Profile loaded, reconciling data")
        profile:Reconcile()

        -- If another server grabs it, we’ll get released
        profile:ListenToRelease(function()
            player:Kick("Your profile was loaded elsewhere.")
        end)

        -- Store it for later
        self.Profiles[player] = profile
        print("[DataService] ✅ Profile stored for", player.Name, profile.Data)
    end)

    -- 7) Save on leave
    Players.PlayerRemoving:Connect(function(player)
        print("[DataService] PlayerRemoving:", player.Name)
        local profile = self.Profiles[player]
        if profile then
            print("[DataService] Releasing profile for", player.Name)
            profile:Release()
        end
    end)
end

return DataService