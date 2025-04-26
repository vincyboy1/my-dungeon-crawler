-- StarterPlayerScripts/BasicClickAttack.lua
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local player      = Players.LocalPlayer
local remotes     = ReplicatedStorage:WaitForChild("Remotes")
local attackEvent = remotes:WaitForChild("AttackRequest")

print("[BasicClickAttack] ? client script loaded for", player.Name)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		print("[BasicClickAttack] ? click detected")
		local class       = player:GetAttribute("Class") or "Warrior"
		local abilityName = "BasicMeleeAttack" .. class
		print("[BasicClickAttack]   firing ability:", abilityName)
		attackEvent:FireServer(abilityName)
	end
end)
