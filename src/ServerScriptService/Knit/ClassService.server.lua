-- src/ServerScriptService/Knit/ClassService.server.lua

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit        = require(ReplicatedStorage.Knit.Knit)
local DataService = Knit.GetService("DataService")

-- *** Correct path here: ***
local ClassDefs   = require(ReplicatedStorage.SharedModules.ClassDefinitions)

local ClassService = Knit.CreateService {
    Name = "ClassService",
    Client = {}
}

function ClassService:KnitInit()
    print("[ClassService] :KnitInit")
    self.PlayerClasses = {}
end

function ClassService:SelectClass(player, className)
    if not ClassDefs[className] then
        warn("[ClassService] Invalid class:", className)
        return
    end
    self.PlayerClasses[player] = className
    print(("[ClassService] %s selected class %s"):format(player.Name, className))
end

function ClassService.Client:SelectClass(player, className)
    return self.Server:SelectClass(player, className)
end

function ClassService:GetPlayerClass(player)
    return self.PlayerClasses[player] or "Warrior"
end

return ClassService