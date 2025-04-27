-- src/ServerScriptService/Knit/ClassService.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit.KnitServer)

local ClassService = Knit.CreateService {
    Name = "ClassService",
    Client = {
        ClassSelected = Knit.CreateSignal()
    }
}

function ClassService:KnitInit()
    print("[ClassService] :KnitInit")
    -- load your single definitions module
    local defs = require(ReplicatedStorage.SharedModules.ClassDefinitions)
    self.classDefs = defs

    -- collect names
    self.available = {}
    for name,_ in pairs(defs) do
        table.insert(self.available, name)
    end
    table.sort(self.available)
end

function ClassService:KnitStart()
    print("[ClassService] :KnitStart – found classes:")
    for _,name in ipairs(self.available) do
        print("   ", name)
    end
end

-- called from client
function ClassService:SelectClass(player, className)
    if not table.find(self.available, className) then
        warn("[ClassService] invalid class:", className)
        return
    end
    print("[ClassService] Player", player.Name, "selected class:", className)

    -- record it in their profile
    local dataService = self:GetService("DataService")
    local profile = dataService:GetProfile(player)
    profile.Data.SelectedClass = className

    -- notify the client
    self.Client.ClassSelected:Fire(player, className)
end

return ClassService