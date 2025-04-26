local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsModule = require(game.ReplicatedStorage.Modules.AttributeModules.StatsModule)

-- Remote Event for stat modification
local modifyStatEvent = Instance.new("RemoteEvent", ReplicatedStorage)
modifyStatEvent.Name = "ModifyStatEvent"

-- Handle stat modification
modifyStatEvent.OnServerEvent:Connect(function(player, stat, value)
	if not stat or not value then
		warn("[ModifyStatEvent] Invalid stat or value received.")
		return
	end

	StatsModule.modifyStat(player, stat, value)
	print(string.format("[ModifyStatEvent] Increased %s by %d for player %s", stat, value, player.Name))
end)
