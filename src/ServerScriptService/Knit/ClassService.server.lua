-- src/ServerScriptService/Knit/ClassService.server.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit             = require(ReplicatedStorage.Knit.Knit)  -- your Knit entrypoint
local ClassService     = Knit.CreateService { Name = "ClassService", Client = {} }

function ClassService:KnitInit()
    print("[ClassService] :KnitInit")

    -- pull in DataService now that Knit is up
    self.DataService = self:GetService("DataService")

    -- require the single big ClassDefinitions.lua module
    local ok, defs = pcall(require, ReplicatedStorage.SharedModules.ClassDefinitions)
    assert(ok and defs, "[ClassService] ❌ Failed to load ClassDefinitions.lua")
    self.ClassDefs = defs
end

function ClassService:KnitStart()
    print("[ClassService] :KnitStart – found classes:")

    -- build a simple list of keys to print
    local names = {}
    for className in pairs(self.ClassDefs) do
        table.insert(names, className)
    end

    -- print them in one go
    print("\t" .. table.concat(names, ", "))
end

-- Server API: assign a class to a player
function ClassService:SelectClass(player, className)
    if not self.ClassDefs[className] then
        warn("[ClassService] Invalid class name:", className)
        return
    end

    -- store it however you need, e.g. in DataService
    self.DataService:SetPlayerClass(player, className)
    print(("[ClassService] %s selected %s"):format(player.Name, className))
end

-- expose to client
function ClassService.Client:SelectClass(player, className)
    return ClassService.SelectClass(self, player, className)
end

return ClassService