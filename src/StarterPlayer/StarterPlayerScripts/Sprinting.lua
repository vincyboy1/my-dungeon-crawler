-- SprintInput_Local.lua
-- This script handles sprint input and fires sprint toggle events.
local userInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer

-- Wait for the server-created SprintToggle RemoteEvent on the player.
local sprintRemote = player:WaitForChild("SprintToggle")

local isSprinting = false

userInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftControl then
		isSprinting = true
		sprintRemote:FireServer(true) -- Notify server to start sprinting
	end
end)

userInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftControl then
		isSprinting = false
		sprintRemote:FireServer(false) -- Notify server to stop sprinting
	end
end)