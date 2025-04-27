-- src/StarterPlayer/StarterPlayerScripts/ClassController.client.lua
local Players           = game:GetService("Players")
local TextChatService  = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit.Knit)
local ClassController = Knit.CreateController { Name = "ClassController" }

function ClassController:KnitStart()
    print("[ClassController] :KnitStart")
    local ClassService = Knit.GetService("ClassService")
    local player = Players.LocalPlayer

    -- Legacy chat event
    player.Chatted:Connect(function(msg)
        self:_handleChat(msg, ClassService)
    end)

    -- New TextChatService event
    TextChatService.OnIncomingMessage:Connect(function(message)
        -- message.Text is the chat string
        self:_handleChat(message.Text, ClassService)
    end)
end

-- parse and dispatch
function ClassController:_handleChat(msg, ClassService)
    -- Pattern breakdown: 
    --  ^           : start of the string 
    --  /class      : literal “/class” 
    --  %s+         : one or more spaces 
    --  (%w+)       : capture one or more “word” chars (letters, digits, underscore)
    local chosen = msg:match("^/class%s+(%w+)")
    if chosen then
        print("[ClassController] Requesting class:", chosen)
        ClassService:SelectClass(chosen)
    end
end

return ClassController