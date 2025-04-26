local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CustomHealthSystem = require(ReplicatedStorage.Modules.CombatModules.CustomHealthSystem)

-- Look for (or create) the Remotes folder in ReplicatedStorage.
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

-- Look for (or create) the HealthUpdate RemoteEvent inside Remotes.
local healthUpdateEvent = remotesFolder:FindFirstChild("HealthUpdate")
if not healthUpdateEvent then
	healthUpdateEvent = Instance.new("RemoteEvent")
	healthUpdateEvent.Name = "HealthUpdate"
	healthUpdateEvent.Parent = remotesFolder
end

local function setupHealthRelayForPlayer(player)
	-- Wait until the custom health instance is attached.
	while not CustomHealthSystem.GetInstance(player) do
		wait(0.1)
	end
	local instance = CustomHealthSystem.GetInstance(player)
	if instance then
		-- When the health system updates, fire the event with the full status.
		instance.HealthChanged.Event:Connect(function(status)
			-- status is a table from GetStatus(), which includes Health, MaxHealth, and ShieldHealth.
			healthUpdateEvent:FireClient(player, status)
		end)
		-- Immediately send the current status so the GUI starts correctly.
		healthUpdateEvent:FireClient(player, instance:GetStatus())
	else
		print("[HealthUpdateRelay] No custom health instance found for", player.Name)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		wait(1)  -- Allow time for the ClassFramework to attach the custom health instance.
		setupHealthRelayForPlayer(player)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		wait(1)
		setupHealthRelayForPlayer(player)
	else
		player.CharacterAdded:Connect(function(character)
			wait(1)
			setupHealthRelayForPlayer(player)
		end)
	end
end