local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StatsModule = require(game.ReplicatedStorage.Modules.AttributeModules.StatsModule)

-- Create the RemoteEvent for mana updates
local manaUpdateEvent = Instance.new("RemoteEvent")
manaUpdateEvent.Name = "ManaUpdateEvent"
manaUpdateEvent.Parent = ReplicatedStorage

-- Function to send mana updates securely
local function sendManaUpdate(player)
	local stats = StatsModule.getStats(player)
	if stats then
		manaUpdateEvent:FireClient(player, stats.Mana, stats.MaxMana)
	end
end

-- Handle client request for mana updates
manaUpdateEvent.OnServerEvent:Connect(function(player)
	sendManaUpdate(player)
end)

-- Automatically send mana updates whenever a player's mana changes
function onManaChanged(player)
	sendManaUpdate(player)
end

-- Listen for players joining and initialize mana updates
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		-- Send the initial mana update
		sendManaUpdate(player)
	end)
end)

-- Securely listen for stat changes in `StatsModule`
StatsModule.updateStat = function(player, stat, value)
	if not player or not StatsModule.getStats(player) then return end
	local stats = StatsModule.getStats(player)

	if stats[stat] ~= nil then
		stats[stat] = value

		-- If Mana or MaxMana changes, notify the client
		if stat == "Mana" or stat == "MaxMana" then
			sendManaUpdate(player)
		end
	end
end
