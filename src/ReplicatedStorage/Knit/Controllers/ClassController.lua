-- src/ReplicatedStorage/Knit/Controllers/ClassController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit.KnitClient)

local ClassController = Knit.CreateController { Name = "ClassController" }

function ClassController:KnitStart()
    print("[ClassController] :KnitStart")
    local ClassService = Knit.GetService("ClassService")
    local player = Players.LocalPlayer

    -- log every chat
    player.Chatted:Connect(function(msg)
        print("[ClassController] Got chat:", msg)
        -- match "/class <classname>"
        local chosen = msg:match("^/class%s+(.+)$")
        print("[ClassController] pattern result:", chosen)
        if chosen then
            print("[ClassController] Requesting class:", chosen)
            ClassService:SelectClass(chosen)
        end
    end)

    -- listen for confirmation
    ClassService.ClassSelected:Connect(function(plr, className)
        if plr == player then
            print("[ClassController] Class selection confirmed:", className)
            -- TODO: apply client-side effects (e.g. equip gear, update UI)
        end
    end)
end

return ClassController
