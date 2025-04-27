-- src/ReplicatedStorage/Knit/Controllers/ClassController.lua
local Players           = game:GetService("Players")
local TextChatService   = game:GetService("TextChatService")
local Knit              = require(script.Parent.Parent.Knit)

local ClassController = Knit.CreateController { Name = "ClassController" }

function ClassController:KnitStart()
    print("[ClassController] :KnitStart")
    local ClassService = Knit.GetService("ClassService")
    local player = Players.LocalPlayer

    player.Chatted:Connect(function(msg)
        self:_handleChat(msg, ClassService)
    end)

    TextChatService.OnIncomingMessage:Connect(function(message)
        self:_handleChat(message.Text, ClassService)
    end)
end

function ClassController:_handleChat(msg, ClassService)
    local chosen = msg:match("^/class%s+(.+)$")
    if chosen then
        print("[ClassController] Requesting class:", chosen)
        ClassService:SelectClass(chosen)
    end
end

return ClassController
