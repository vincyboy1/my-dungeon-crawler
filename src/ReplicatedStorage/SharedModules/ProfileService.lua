-- DataService.server.lua
-- Handles player data loading, saving, and basic getters/setters

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit    = require(ReplicatedStorage.Knit)

-- Adjust this require path if you placed ProfileService somewhere else
local ProfileService = require(ReplicatedStorage.SharedModules.ProfileService)

local DEFAULT_DATA = {
    Gold               = 0,
    TotalRunsPlayed    = 0,
    BestDungeonLevel   = 0,
    ClassesUnlocked    = { Warrior = true, Ranger = true, Mage = true },
    EvolvedUnlocked    = {},
    VestigesUnlocked   = {},
    Cosmetics          = {},
}

local DataService = Knit.CreateService {
    Name = "DataService",
}

function DataService:KnitStart()
    print("[DataService] Starting up…")

    -- Create (or open) the data store
    self.ProfileStore = ProfileService.GetProfileStore(
        "DungeonCrawlerData",  -- DataStore name
        DEFAULT_DATA
    )
    self.Profiles = {}

    Players.PlayerAdded:Connect(function(player)
        print("[DataService] Player joined:", player.Name)

        local key = "Player_" .. player.UserId
        local profile = self.ProfileStore:LoadProfileAsync(key, "ForceLoad")
        if not profile then
            warn("[DataService] ❌ Could not load profile for", player.Name)
            player:Kick("Data load error. Please rejoin.")
            return
        end

        profile:ListenToRelease(function()
            player:Kick(
                "[DataService] Your data was loaded in another session."
            )
        end)

        -- Fill in any new fields from DEFAULT_DATA
        profile:Reconcile()

        self.Profiles[player] = profile
        print("[DataService] ✅ Loaded profile for", player.Name, profile.Data)

        profile:ListenToDeath(function()
            print("[DataService] Profile released for", player.Name)
            self.Profiles[player] = nil
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        print("[DataService] Player leaving:", player.Name)
        local profile = self.Profiles[player]
        if profile then
            profile:Release()
            print("[DataService] Profile saved and released for", player.Name)
        end
    end)
end

-- Returns the raw data table for a player, or nil if not loaded
function DataService:GetData(player)
    local profile = self.Profiles[player]
    if profile then
        return profile.Data
    else
        warn("[DataService] GetData called for untracked player:", player.Name)
        return nil
    end
end

-- Convenience API: add gold
function DataService:AddGold(player, amount)
    local data = self:GetData(player)
    if data then
        data.Gold = data.Gold + amount
        print(string.format(
            "[DataService] %s now has %d Gold (+%d)",
            player.Name, data.Gold, amount
        ))
    end
end

-- Unlock an evolved class permanently
function DataService:UnlockClass(player, className)
    local data = self:GetData(player)
    if data and not data.EvolvedUnlocked[className] then
        data.EvolvedUnlocked[className] = true
        print(string.format(
            "[DataService] %s unlocked evolved class: %s",
            player.Name, className
        ))
    end
end

-- Record a completed run
function DataService:RecordRun(player, dungeonLevel, goldEarned)
    local data = self:GetData(player)
    if not data then return end

    data.TotalRunsPlayed = data.TotalRunsPlayed + 1
    if dungeonLevel > data.BestDungeonLevel then
        data.BestDungeonLevel = dungeonLevel
        print(string.format(
            "[DataService] %s set new BestDungeonLevel: %d",
            player.Name, dungeonLevel
        ))
    end

    data.Gold = data.Gold + goldEarned
    print(string.format(
        "[DataService] %s completed run level %d, earned %d Gold",
        player.Name, dungeonLevel, goldEarned
    ))
end

return DataService