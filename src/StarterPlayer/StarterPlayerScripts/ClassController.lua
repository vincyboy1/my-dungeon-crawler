-- src/StarterPlayer/StarterPlayerScripts/ClassController.lua
-- Adds camera follow after morph

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit              = require(ReplicatedStorage.Knit.Knit)

local ClassController = Knit.CreateController { Name = "ClassController" }

function ClassController:KnitInit()
    -- nothing needed here
end

function ClassController:KnitStart()
    local player       = Players.LocalPlayer
    local ClassService = Knit.GetService("ClassService")

    -- camera follow on each character spawn
    player.CharacterAdded:Connect(function(char)
        local cam = workspace.CurrentCamera
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            cam.CameraSubject = humanoid
        end
    end)

    -- existing GUI code…
    local gui = Instance.new("ScreenGui")
    gui.Name         = "ClassSelectorGui"
    gui.ResetOnSpawn = false
    gui.Parent       = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size               = UDim2.new(0, 220, 0, 30)
    frame.Position           = UDim2.new(0, 10, 0, 50)
    frame.BackgroundColor3   = Color3.new(0, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel    = 0

    local box = Instance.new("TextBox", frame)
    box.Size               = UDim2.new(0.7, 0, 1, 0)
    box.PlaceholderText    = "Enter class name"
    box.BackgroundTransparency = 0.5

    local btn = Instance.new("TextButton", frame)
    btn.Size               = UDim2.new(0.3, 0, 1, 0)
    btn.Position           = UDim2.new(0.7, 0, 0, 0)
    btn.Text               = "Select"
    btn.BackgroundTransparency = 0.5

    btn.MouseButton1Click:Connect(function()
        local className = box.Text:match("^%s*(.-)%s*$")
        if className ~= "" then
            ClassService:SelectClass(className)
                :andThen(function(success)
                    if success then
                        print("[ClassController] Selected:", className)
                    else
                        warn("[ClassController] Invalid class:", className)
                    end
                end)
                :catch(function(err)
                    warn("[ClassController] Error:", err)
                end)
        end
    end)
end

return ClassController
