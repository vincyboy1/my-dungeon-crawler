local PartyManager = {}

-- Function to get all ally players
function PartyManager.getAllies()
	return game.Players:GetPlayers()
end

-- Utility: Apply a skill effect to all allies
function PartyManager.applyToAllies(effectFunction)
	for _, player in ipairs(PartyManager.getAllies()) do
		effectFunction(player)
	end
end

-- Utility: Check if a target is an NPC
function PartyManager.isNPC(target)
	return not game.Players:GetPlayerFromCharacter(target)
end

-- Utility: Apply a skill effect to all non-NPC characters (players)
function PartyManager.applyToNonNPCs(effectFunction)
	for _, player in ipairs(PartyManager.getAllies()) do
		effectFunction(player)
	end
end

-- Utility: Apply a skill effect to a specific target if it's not an NPC
function PartyManager.applyIfNonNPC(target, effectFunction)
	if not PartyManager.isNPC(target) then
		effectFunction(target)
	end
end

-- Utility: Check if two players are allies
function PartyManager.isPlayerAlly(player, target)
	if not player or not target then return false end
	if target:GetAttribute("IsAlly") then
		return true -- Wisp is marked as an ally
	end

	return true -- Default: consider everyone allies
end

return PartyManager