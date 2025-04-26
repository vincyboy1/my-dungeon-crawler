local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
remotes.Name = "Remotes"
local Players = game:GetService("Players")
local ClassFramework = require(script.Parent:WaitForChild("ClassFramework"))

local classSelectionEvent = remotes:FindFirstChild("ClassSelectionEvent")
if not classSelectionEvent then
	classSelectionEvent = Instance.new("RemoteEvent")
	classSelectionEvent.Name = "ClassSelectionEvent"
	classSelectionEvent.Parent = remotes
end

classSelectionEvent.OnServerEvent:Connect(function(player, className)
	if not ClassFramework.BaseStats[className] then
		warn(player.Name .. " attempted to select an invalid class: " .. tostring(className))
		return
	end
	player:SetAttribute("Class", className)
	local success, errorMsg = pcall(function()
		ClassFramework:EquipBaseCharacter(player, className)
	end)
	if not success then
		warn("Failed to assign class to " .. player.Name .. ": " .. errorMsg)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Class", nil)
end)