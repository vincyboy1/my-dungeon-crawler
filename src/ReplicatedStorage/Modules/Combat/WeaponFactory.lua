-- ReplicatedStorage/Modules/Combat/WeaponFactory.lua
local CombatUtils = require(game:GetService("ReplicatedStorage").Modules.Combat.CombatUtils)
local AnimationConfig = require(game:GetService("ReplicatedStorage").Modules.Combat.Animations)
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local AbilityManager = require(game:GetService("ReplicatedStorage").Modules.CombatModules.AbilityManager)

local WeaponFactory = {}
WeaponFactory.__index = WeaponFactory

function WeaponFactory.new(className, player)
	local self = setmetatable({ player = player, className = className }, WeaponFactory)

	if className == "Warrior" or className == "Striker" or className == "Support" then
		self.combo = CombatUtils.ComboManager.new(5, 0.5)
	elseif className == "Ranger" then
		local FastCast = require(game:GetService("ReplicatedStorage").Modules.Combat.FastCast)
		self.cast = FastCast.new()
	elseif className == "Mage" then
		self.combo = CombatUtils.ComboManager.new(3, 0.5)
	end

	return self
end

function WeaponFactory:Attack()
	local class = self.className
	local player = self.player
	local moveName

	if class == "Warrior" or class == "Striker" or class == "Support" then
		local count = self.combo:TryAdvance()
		moveName = "BasicMeleeAttack" .. class
		-- play combo-specific animation if desired
	elseif class == "Ranger" then
		moveName = "BasicAttackRanger"
	elseif class == "Mage" then
		local count = self.combo:TryAdvance()
		if count == 1 then
			moveName = "BasicAttackMage"
		else
			moveName = "BasicMeleeAttackMage"
		end
	else
		return
	end

	-- Play animation
	local animId = AnimationConfig[class][moveName:match("Attack(.*)") or "attack1"]
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid and animId then
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		humanoid:LoadAnimation(animation):Play()
	end

	-- Detect hit
	task.delay(0.2, function()
		if not player.Character then return end
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {player.Character}
		params.FilterType = Enum.RaycastFilterType.Blacklist
		local result = CombatUtils.Raycast(root.Position, root.CFrame.LookVector * 5, params)
		if result and result.Instance then
			local targetModel = result.Instance:FindFirstAncestorOfClass("Model")
			if targetModel and targetModel:FindFirstChild("Humanoid") then
				Remotes.AttackHit:FireServer({
					target = targetModel,
					moveName = moveName,
					damageType = "Physical"
				})
			end
		end
	end)
end

return WeaponFactory