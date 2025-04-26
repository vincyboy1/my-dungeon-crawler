-- ServerScriptService/CombatService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityManager = require(ReplicatedStorage.Modules.CombatModules.AbilityManager)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AttackHit = Remotes:WaitForChild("AttackHit")

AttackHit.OnServerEvent:Connect(function(player, data)
	-- data = { target = Model, moveName = string, damageType = string }
	local targetModel = data.target
	local moveName = data.moveName
	local damageType = data.damageType

	if typeof(moveName) ~= "string" then return end
	if not AbilityManager.canCast(player, moveName) then return end

	local humanoid = targetModel and targetModel:FindFirstChild("Humanoid")
	if humanoid then
		-- Apply ability damage or healing via the unified manager
		AbilityManager.applyAbility(humanoid, moveName, player, damageType)
	end
end)

return {}