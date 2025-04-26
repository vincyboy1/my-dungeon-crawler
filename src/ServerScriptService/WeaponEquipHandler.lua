-- WeaponEquipHandler_Server.lua
-- Listens for weapon equip toggle events and updates the character's WeaponEquipped attribute.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local weaponToggleEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WeaponEquipToggle")

weaponToggleEvent.OnServerEvent:Connect(function(player, isEquipped)
	if player and player.Character then
		player.Character:SetAttribute("WeaponEquipped", isEquipped)
	end
end)