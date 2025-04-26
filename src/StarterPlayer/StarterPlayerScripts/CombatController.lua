-- StarterPlayerScripts/CombatController.lua
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AnimConfig = require(ReplicatedStorage.Modules.Combat.Animations)
local CombatUtils = require(ReplicatedStorage.Modules.Combat.CombatUtils)
local WeaponFactory = require(ReplicatedStorage.Modules.Combat.WeaponFactory)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()

-- Setup raycast params blacklist
local params = RaycastParams.new()
params.FilterDescendantsInstances = {character}
params.FilterType = Enum.RaycastFilterType.Blacklist

-- Create weapon based on player class attribute
local function getWeapon()
	local className = localPlayer:GetAttribute("Class")
	return WeaponFactory.new(className, localPlayer)
end

local currentWeapon = getWeapon()

-- On character respawn, recreate weapon
localPlayer.CharacterAdded:Connect(function(char)
	character = char
	currentWeapon = getWeapon()
	params.FilterDescendantsInstances = {char}
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		currentWeapon:Attack()
	end
end)