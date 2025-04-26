local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CrowdControlHandler = require(ReplicatedStorage.Modules.CombatModules.CrowdControlHandler)

local applyCCEvent = ReplicatedStorage:WaitForChild("Remotes"):FindFirstChild("ApplyCrowdControl")

applyCCEvent.OnServerEvent:Connect(function(player, ccType, targetCharacter, duration, extraData)
	-- Ensure targetCharacter is valid and the player is authorized
	if not targetCharacter or not targetCharacter:FindFirstChild("Humanoid") then
		warn("[Server] Invalid target character for CC:", ccType)
		return
	end

	-- Check for conflicting CC effects
	if CrowdControlHandler.isAffectedByCC(targetCharacter, {"Stunned", "Ragdoll", "Silenced"}) then
		print(string.format("[Server] Cannot apply %s to %s due to conflicting CC.", ccType, targetCharacter.Name))
		return
	end

	print(string.format("[Server] Applying %s to %s for %d seconds.", ccType, targetCharacter.Name, duration))

	-- Apply the requested CC effect
	CrowdControlHandler.applyCC(ccType, targetCharacter, duration, extraData)
end)

