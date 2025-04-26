-- ServerScriptService/AttackHandler.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local remotes           = ReplicatedStorage:WaitForChild("Remotes")
local attackEvent       = remotes:WaitForChild("AttackRequest")
local AbilityManager    = require(ReplicatedStorage.Modules.CombatModules.AbilityManager)

print("[AttackHandler] ? server handler loaded (AbilityManager version)")

attackEvent.OnServerEvent:Connect(function(player, abilityName)
	print("[AttackHandler] ?? request from", player.Name, "ability:", abilityName)

	local char = player.Character
	if not char then
		warn("[AttackHandler]   no character for player")
		return
	end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[AttackHandler]   no HumanoidRootPart")
		return
	end

	-- Slash area parameters
	local slashDistance = 5
	local slashWidth    = 4
	local slashHeight   = 5

	-- Build a box in front of the player
	local forwardCF = hrp.CFrame * CFrame.new(0, 0, -slashDistance/2)
	local boxSize   = Vector3.new(slashWidth, slashHeight, slashDistance)
	print(string.format("[AttackHandler]   box center=%s size=%s", tostring(forwardCF), tostring(boxSize)))

	local params = OverlapParams.new()
	params.FilterType                 = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { char }

	-- Gather all parts in that box
	local parts = Workspace:GetPartBoundsInBox(forwardCF, boxSize, params)
	print("[AttackHandler]   parts found:", #parts)

	-- Deduplicate and apply the move via AbilityManager to each Humanoid
	local hitHumanoids = {}
	for _, part in ipairs(parts) do
		local model    = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		if humanoid and not hitHumanoids[humanoid] then
			hitHumanoids[humanoid] = true
			print("[AttackHandler]   applying", abilityName, "to", model.Name)
			-- This will handle cooldowns, scaling, resistances, crits, shield, etc.
			AbilityManager.applyAbility(humanoid, abilityName, player, "Physical")
		end
	end

	if next(hitHumanoids) == nil then
		print("[AttackHandler]   no humanoids hit")
	end
end)
