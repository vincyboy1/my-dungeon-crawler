-- HexOfTheWithering_Keybind.lua (LocalScript)
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CastHexEvent = Remotes:WaitForChild("CastHexOfTheWithering")

-- Retrieve move data for HexOfTheWithering from the DamageHandler module.
local DamageHandler = require(ReplicatedStorage.Modules.CombatModules.DamageHandler)
local moveData = DamageHandler.moveDamages["HexOfTheWithering"]
local COOLDOWN_TIME = moveData and moveData.baseCooldown or 40

local isOnCooldown = false

-- Placeholder targeting function (replace with your own targeting logic)
local function getTargetEnemy()
	local mouse = player:GetMouse()
	local target = mouse.Target
	if target and target.Parent and target.Parent:FindFirstChild("Humanoid") then
		return target.Parent
	end
	return nil
end

-- Listen for the "R" key press to activate the skill.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R then
		if isOnCooldown then
			print("[HexOfTheWithering] Skill is on cooldown.")
			return
		end

		local target = getTargetEnemy()
		if target then
			print("[HexOfTheWithering] Casting on target: " .. target.Name)
			CastHexEvent:FireServer(target)
			isOnCooldown = true
			-- Use the dynamic cooldown from moveData.
			task.delay(COOLDOWN_TIME, function()
				isOnCooldown = false
				print("[HexOfTheWithering] Cooldown finished.")
			end)
		else
			print("[HexOfTheWithering] No valid target found.")
		end
	end
end)