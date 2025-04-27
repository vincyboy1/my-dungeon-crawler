-- src/StarterPlayer/StarterPlayerScripts/ClassController.client.lua

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit.Knit)
local ClassController = Knit.CreateController { Name = "ClassController" }

function ClassController:KnitStart()
    print("[ClassController] :KnitStart")
    -- now it’s safe to grab the service
    local ClassService = Knit.GetService("ClassService")
    local player = Players.LocalPlayer

    -- Example: hook into chat for testing
    player.Chatted:Connect(function(msg)
        local chosen = msg:match("^/class%s+(%w+)")
        if chosen then
            print("[ClassController] Requesting class:", chosen)
            ClassService:SelectClass(chosen)
        end
    end)
end

return ClassController