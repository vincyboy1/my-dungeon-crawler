local StatsModule = {}

-- Table to securely store stats for Players & NPCs
local entityStats = {}

-- Validate entity instance (Players & NPCs)
local function validateEntity(entity)
	return entity and typeof(entity) == "Instance" and (entity:IsA("Player") or entity:IsA("Model"))
end

-- Initialize stats (for both Players & NPCs)
function StatsModule.initializeStats(entity, baseStats)
	if not validateEntity(entity) then return end

	if entityStats[entity] then
		warn(string.format("[StatsModule] Stats already initialized for entity: %s", entity.Name))
		return
	end

	local stats = {}
	for stat, value in pairs(baseStats) do
		stats[stat] = value
	end

	-- **NPCs Start with 0 Mana**
	if not entity:IsA("Player") then
		stats.Mana = 0
	else
		stats.Mana = stats.MaxMana -- Players start with full mana
	end

	entityStats[entity] = stats
end

-- Retrieve stats
function StatsModule.getStats(entity)
	if not validateEntity(entity) then return nil end
	return entityStats[entity]
end

-- Update stats (Server-only)
function StatsModule.updateStat(entity, stat, value)
	if not validateEntity(entity) or not entityStats[entity] then return end

	if not entityStats[entity][stat] then
		warn(string.format("[StatsModule] Attempted to update an invalid stat: %s for entity: %s", stat, entity.Name))
		return
	end

	entityStats[entity][stat] = value
	print(string.format("[StatsModule] Updated stat %s for entity %s to %s", stat, entity.Name, value))
end

-- Modify stats (Safe from Exploits)
function StatsModule.modifyStat(entity, stat, modifier)
	if not validateEntity(entity) or not entityStats[entity] then return end

	if not entityStats[entity][stat] then
		warn(string.format("[StatsModule] Attempted to modify an invalid stat: %s for entity: %s", stat, entity.Name))
		return
	end

	entityStats[entity][stat] = entityStats[entity][stat] + modifier
	print(string.format("[StatsModule] Modified stat %s for entity %s by %s (New value: %s)", stat, entity.Name, modifier, entityStats[entity][stat]))
end

-- Cleanup when an entity is removed
function StatsModule.clearStats(entity)
	if not validateEntity(entity) then return end

	if entityStats[entity] then
		entityStats[entity] = nil
		print(string.format("[StatsModule] Cleared stats for entity: %s", entity.Name))
	end
end

-- Cleanup on Player Leave
game.Players.PlayerRemoving:Connect(function(player)
	StatsModule.clearStats(player)
end)

return StatsModule