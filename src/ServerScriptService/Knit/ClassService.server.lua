-- src/ServerScriptService/Knit/ClassService.server.lua

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage.Knit.Knit)
local DataService = Knit.GetService("DataService")

-- Replace with your actual class definitions module
local ClassDefs = require(ReplicatedStorage.SharedModules.ClassDefinitions)

local ClassService = Knit.CreateService {
    Name = "ClassService",
    Client = {}
}

function ClassService:KnitInit()
    print("[ClassService] :KnitInit")
    -- table to hold each player’s selected class
    self.PlayerClasses = {}
end

function ClassService:SelectClass(player, className)
    if not ClassDefs[className] then
        warn("[ClassService] Invalid class:", className, "by", player.Name)
        return
    end

    self.PlayerClasses[player] = className
    print(string.format(
        "[ClassService] %s selected class %s",
        player.Name, className
    ))
end

-- RPC wrapper so clients can call it
function ClassService.Client:SelectClass(player, className)
    return self.Server:SelectClass(player, className)
end

-- Helper to retrieve a player’s class (defaults to Warrior)
function ClassService:GetPlayerClass(player)
    return self.PlayerClasses[player] or "Warrior"
end

return ClassService