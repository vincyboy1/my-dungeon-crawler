-- DataService.server.lua
-- Handles player data loading/saving with ProfileService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 1) Require Knit from the right module
local Knit = require(ReplicatedStorage.Knit.Knit)
print("[DataService] Knit loaded:", Knit)

-- 2) Require ProfileService (adjust path if you placed it elsewhere)
local ProfileService = require(ReplicatedStorage.SharedModules.ProfileService)
print("[DataService] ProfileService loaded:", ProfileService)

local DEFAULT_DATA = {
    Gold             = 0,
    TotalRunsPlayed  = 0,
    BestDungeonLevel = 0,
    ClassesUnlocked  = { Warrior = true, Ranger = true, Mage = true },
    EvolvedUnlocked  = {},
    VestigesUnlocked = {},
    Cosmetics        = {},
}

local DataService = Knit.CreateService { Name = "DataService" }

function DataService:KnitStart()
    print("[DataService] :KnitStart() called")

    self.ProfileStore = ProfileService.GetProfileStore(
        "DungeonCrawlerData",
        DEFAULT_DATA
    )
    self.Profiles = {}

    -- Load on join
    Players.PlayerAdded:Connect(function(player)
        print("[DataService] PlayerAdded:", player.Name)

        local key = "Player_" .. player.UserId
        local profile = self.ProfileStore:LoadProfileAsync(key, "ForceLoad")
        if not profile then
            warn("[DataService] ❌ failed to load profile for", player.Name)
            player:Kick("Data load error.")
            return
        end

        profile:ListenToRelease(function()
            player:Kick("Your profile was loaded elsewhere.")
        end)

        profile:Reconcile()
        self.Profiles[player] = profile
        print("[DataService] ✅ Profile loaded for", player.Name, profile.Data)

        profile:ListenToDeath(function()
            print("[DataService] Profile released for", player.Name)
            self.Profiles[player] = nil
        end)
    end)

    -- Save on leave
    Players.PlayerRemoving:Connect(function(player)
        print("[DataService] PlayerRemoving:", player.Name)
        local profile = self.Profiles[player]
        if profile then
            profile:Release()
            print("[DataService] Profile saved & released for", player.Name)
        end
    end)
end

-- Returns player's data table
function DataService:GetData(player)
    local profile = self.Profiles[player]
    if not profile then
        warn("[DataService] GetData(): no profile for", player.Name)
        return
    end
    return profile.Data
end

-- Example API calls with prints:
function DataService:AddGold(player, amount)
    local data = self:GetData(player)
    if not data then return end
    data.Gold += amount
    print(string.format(
        "[DataService] %s now has %d Gold (+%d)",
        player.Name, data.Gold, amount
    ))
end

function DataService:RecordRun(player, level, gold)
    local data = self:GetData(player)
    if not data then return end

    data.TotalRunsPlayed += 1
    if level > data.BestDungeonLevel then
        data.BestDungeonLevel = level
        print(string.format(
            "[DataService] %s set new best level: %d",
            player.Name, level
        ))
    end

    data.Gold += gold
    print(string.format(
        "[DataService] %s completed level %d, earned %d Gold",
        player.Name, level, gold
    ))
end

return DataService