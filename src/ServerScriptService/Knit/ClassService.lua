-- src/ServerScriptService/Knit/ClassService.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit.Knit)  -- load the KnitServer module

local ClassService = Knit.CreateService {
    Name = "ClassService",
    Client = {}
}

function ClassService:KnitInit()
    print("[ClassService] :KnitInit")

    -- grab your DataService via the static API
    self.DataService = Knit.GetService("DataService")

    -- load your class definitions module
    local ok, defs = pcall(require, ReplicatedStorage.SharedModules.ClassDefinitions)
    assert(ok and defs, "[ClassService] ❌ Failed to load ClassDefinitions.lua")
    self.ClassDefs = defs
end

function ClassService:KnitStart()
    print("[ClassService] :KnitStart – found classes:")
    local names = {}
    for className in pairs(self.ClassDefs) do
        table.insert(names, className)
    end
    print("\t" .. table.concat(names, ", "))
end

-- server‐side API
function ClassService:SelectClass(player, className)
    if not self.ClassDefs[className] then
        warn("[ClassService] Invalid class name:", className)
        return
    end
    self.DataService:SetPlayerClass(player, className)
    print(("[ClassService] %s selected %s"):format(player.Name, className))
end

-- expose to the client
function ClassService.Client:SelectClass(player, className)
    return ClassService.SelectClass(self, player, className)
end

return ClassService