-- RangedAttacks.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local AbilityManager = require(ReplicatedStorage.Modules.CombatModules.AbilityManager)

local projectileConfigs = {
	MagicBolt = { speed = 45, moveName = "BasicAttackMage", lifetime = 5, maxRange = 30, damageType = "Magic" },
	Arrow = { speed = 120, moveName = "BasicAttackRanger", lifetime = 5, maxRange = 50, damageType = "Physical", baseMultiplier = 0.5, maxMultiplier = 2.0 },
	LightningArrow = { speed = 100, moveName = "LightningArrow", lifetime = 5, maxRange = 30, damageType = "Physical" },
}

local function GetRandomSoundFromPool(pool)
	if not pool or #pool == 0 then
		return nil
	elseif #pool == 1 then
		return pool[1]
	end
	local index = math.random(1, #pool)
	return pool[index]
end

local rangerRangedHitSounds = {"rbxassetid://RangerArrowHit1", "rbxassetid://RangerArrowHit2"}

local function TriggerRangedHitFeedback(player, hitPart)
	local soundId = GetRandomSoundFromPool(rangerRangedHitSounds)
	if soundId then
		local torso = hitPart.Parent:FindFirstChild("Torso") or 
			hitPart.Parent:FindFirstChild("UpperTorso") or 
			hitPart.Parent:FindFirstChild("HumanoidRootPart")
		if torso then
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			sound.Volume = 0.5
			sound.Parent = torso
			sound:Play()
			Debris:AddItem(sound, sound.TimeLength + 0.5)
		end
	end
	local hitFeedbackEvent = ReplicatedStorage.Remotes:FindFirstChild("HitFeedbackEvent")
	if hitFeedbackEvent then
		hitFeedbackEvent:FireClient(player, 0.2, 0.1)
	end
end

local function disableMovingEffects(projectile)
	local movingAttachment = projectile:FindFirstChild("Moving")
	if movingAttachment then
		for _, emitter in ipairs(movingAttachment:GetChildren()) do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
			end
		end
	end
end

local function embedArrow(projectile, hitPart)
	if not projectile or not hitPart then return end
	projectile.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = projectile
	weld.Part1 = hitPart
	weld.Parent = projectile
end

local function playImpactEffects(projectile)
	local impactAttachment = projectile:FindFirstChild("Impact")
	if impactAttachment then
		for _, emitter in ipairs(impactAttachment:GetChildren()) do
			if emitter:IsA("ParticleEmitter") then
				local emitCount = emitter:GetAttribute("EmitCount") or 20
				emitter.Enabled = true
				emitter:Emit(emitCount)
				local lifetime = emitter.Lifetime.Max or 1
				task.delay(lifetime, function()
					emitter.Enabled = false
				end)
			end
		end
	end
end

local function handleProjectile(player, projectileName, targetPosition, chargeTime)
	local config = projectileConfigs[projectileName]
	if not config then
		warn("[ProjectileServer] Configuration not found for:", projectileName)
		return
	end

	local projectileTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("NewProjectiles"):FindFirstChild(projectileName)
	if not projectileTemplate then
		warn("[ProjectileServer] Projectile not found:", projectileName)
		return
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local startPosition = character.HumanoidRootPart.Position
	local direction = (targetPosition - startPosition).Unit
	local projectile = projectileTemplate:Clone()
	projectile:SetAttribute("HasHit", false)

	local minTime = 0.1
	local maxTime = 4.0
	local levels = 5
	local elapsedTime = math.clamp(chargeTime, minTime, maxTime)
	local ratio = (elapsedTime - minTime) / (maxTime - minTime)
	local discreteLevel = math.floor(ratio * (levels - 1) + 1 + 0.5)
	local stepSize = (config.maxMultiplier - config.baseMultiplier) / (levels - 1)
	local finalMultiplier = config.baseMultiplier + (discreteLevel - 1) * stepSize

	projectile:SetAttribute("DamageMultiplier", finalMultiplier)
	projectile.CFrame = CFrame.new(startPosition, startPosition + direction)
	projectile.Parent = workspace

	local traveledDistance = 0
	local isArrow = (projectileName == "Arrow" or projectileName == "LightningArrow")

	if isArrow then
		local trail = Instance.new("Trail")
		trail.Attachment0 = projectile:FindFirstChild("end")
		trail.Attachment1 = projectile:FindFirstChild("end3")
		trail.Lifetime = 0.1
		trail.Parent = projectile
	else
		local movingAttachment = projectile:FindFirstChild("Moving")
		if movingAttachment then
			for _, emitter in ipairs(movingAttachment:GetChildren()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = true
				end
			end
		end
	end

	if projectileName == "LightningArrow" then
		local lightningAttachment = projectile:FindFirstChild("LightningImpact")
		if lightningAttachment then
			for _, emitter in ipairs(lightningAttachment:GetChildren()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = true
				end
			end
		end
	end

	local connection
	local startTime = tick()

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not projectile or not projectile.Parent then
			connection:Disconnect()
			return
		end
		if projectile:GetAttribute("HasHit") then
			return
		end

		local moveDistance = config.speed * deltaTime
		traveledDistance = traveledDistance + moveDistance

		if traveledDistance > config.maxRange then
			projectile:Destroy()
			connection:Disconnect()
			return
		end

		-- Updated collision detection using GetPartBoundsInBox
		local regionSize = projectile.Size
		local regionCFrame = projectile.CFrame
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
		overlapParams.FilterDescendantsInstances = {projectile}
		local hitParts = workspace:GetPartBoundsInBox(regionCFrame, regionSize, overlapParams)
		for _, part in ipairs(hitParts) do
			if part and part:IsA("BasePart") and part ~= projectile then
				local humanoid = part.Parent:FindFirstChild("Humanoid")
				if part:IsDescendantOf(character) then
					continue
				end
				if part.Parent:GetAttribute("IsAlly") then
					continue
				end

				projectile:SetAttribute("HasHit", true)
				local moveData = AbilityManager.moveDamages[config.moveName]
				local baseDamage = (moveData and moveData.baseDamage) or 0
				local damageValue = baseDamage * finalMultiplier

				AbilityManager.applyMoveDamage(humanoid, config.moveName, player, config.damageType, damageValue)

				if isArrow then
					embedArrow(projectile, part)
					TriggerRangedHitFeedback(player, part)
				else
					disableMovingEffects(projectile)
					playImpactEffects(projectile)
				end

				if projectileName == "LightningArrow" then
					playImpactEffects(projectile)
				end

				task.delay(2, function()
					if projectile and projectile.Parent then
						projectile:Destroy()
					end
				end)
				connection:Disconnect()
				return
			end
		end

		if tick() - startTime > config.lifetime then
			projectile:Destroy()
			connection:Disconnect()
		end
	end)
end

local FireProjectileEvent = ReplicatedStorage.Remotes:WaitForChild("FireProjectileNew")
FireProjectileEvent.OnServerEvent:Connect(handleProjectile)