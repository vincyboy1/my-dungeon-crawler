local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Players = game:GetService("Players")
local CustomHealthSystem = require(ReplicatedStorage.Modules.CombatModules.CustomHealthSystem)
local NPCHealthSystem = require(ReplicatedStorage.Modules.CombatModules.CustomHealthSystem.NPCHealthSystem)
local DamageType = require(ReplicatedStorage.Modules.CombatModules.DamageType)

local Status = {}

local AbilityManager = require(ReplicatedStorage.Modules.CombatModules.AbilityManager)
local CrowdControlHandler = require(ReplicatedStorage.Modules.CombatModules.CrowdControlHandler)
local StatsModule = require(ReplicatedStorage.Modules.AttributeModules.StatsModule)
local NPCStatsModule = require(ReplicatedStorage.Modules.AttributeModules.StatsModule.NPCStatsModule)
local StateHandler = require(ReplicatedStorage.Modules.AttributeModules.StateHandler)

-- Table to store active DOT stacks for each target.
local activeStatuses = {}
-- Auxiliary table to track active tick loops.
local activeTicks = {}
-- Table for persistent particle emitters.
local activeParticleEffects = {}

--------------------------------------------------
-- Helper Functions for Stats (Player vs. NPC)
--------------------------------------------------
local function getEntityStat(entity, stat)
	local player = Players:GetPlayerFromCharacter(entity.Parent)
	if player then
		local stats = StatsModule.getStats(player)
		return stats and stats[stat] or 0
	else
		local stats = NPCStatsModule.getStats(entity.Parent)
		return stats and stats[stat] or 0
	end
end

local function updateEntityStat(entity, stat, value)
	local player = Players:GetPlayerFromCharacter(entity.Parent)
	if player then
		StatsModule.updateStat(player, stat, value)
	else
		NPCStatsModule.updateStat(entity.Parent, stat, value)
	end
end

--------------------------------------------------
-- Particle Effect Helpers
--------------------------------------------------
local function startParticleEffect(targetHumanoid, effectType)
	activeParticleEffects[targetHumanoid] = activeParticleEffects[targetHumanoid] or {}
	if activeParticleEffects[targetHumanoid][effectType] then return end
	local statusesFolder = Assets:FindFirstChild("Statuses")
	if not statusesFolder or not statusesFolder:IsA("Folder") then
		return
	end
	local effectFolder = statusesFolder:FindFirstChild(effectType)
	if not effectFolder or not effectFolder:IsA("Folder") then
		warn(string.format("[Status] No effect folder found for: %s in Statuses.", effectType))
		return
	end
	local character = targetHumanoid.Parent
	if not character then
		warn("[Status] Target has no parent character.")
		return
	end
	local bodyParts = {
		Head = character:FindFirstChild("Head"),
		Torso = character:FindFirstChild("Torso"),
		["Left Arm"] = character:FindFirstChild("Left Arm"),
		["Right Arm"] = character:FindFirstChild("Right Arm"),
		["Left Leg"] = character:FindFirstChild("Left Leg"),
		["Right Leg"] = character:FindFirstChild("Right Leg"),
	}
	local emitters = {}
	for partName, bodyPart in pairs(bodyParts) do
		if bodyPart then
			for _, emitterTemplate in ipairs(effectFolder:GetChildren()) do
				if emitterTemplate:IsA("ParticleEmitter") then
					local particleEmitter = emitterTemplate:Clone()
					particleEmitter.Enabled = true
					particleEmitter.Parent = bodyPart
					table.insert(emitters, particleEmitter)
				end
			end
		end
	end
	activeParticleEffects[targetHumanoid][effectType] = emitters
end

local function stopParticleEffect(targetHumanoid, effectType)
	if activeParticleEffects[targetHumanoid] and activeParticleEffects[targetHumanoid][effectType] then
		for _, emitter in ipairs(activeParticleEffects[targetHumanoid][effectType]) do
			if emitter and emitter.Parent then emitter:Destroy() end
		end
		activeParticleEffects[targetHumanoid][effectType] = nil
	end
end

--------------------------------------------------
-- Utility Functions
--------------------------------------------------
local function getHealthInstance(targetHumanoid)
	local player = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	return player and CustomHealthSystem.GetInstance(player) or NPCHealthSystem.GetInstance(targetHumanoid.Parent)
end

--------------------------------------------------
-- DOT Effect Stacking Handler
--------------------------------------------------
local function applyStackingEffect(targetHumanoid, effectName, sourcePlayer, newStacks, tickFunc)
	activeStatuses[targetHumanoid] = activeStatuses[targetHumanoid] or {}
	activeTicks[targetHumanoid] = activeTicks[targetHumanoid] or {}
	if activeStatuses[targetHumanoid][effectName] then
		activeStatuses[targetHumanoid][effectName] = activeStatuses[targetHumanoid][effectName] + newStacks
		if not activeTicks[targetHumanoid][effectName] then tickFunc() end
	else
		activeStatuses[targetHumanoid][effectName] = newStacks
		startParticleEffect(targetHumanoid, effectName)
		tickFunc()
	end
end

--------------------------------------------------
-- DOT Effect Functions (Using DamageType.applyDamage)
--------------------------------------------------
function Status.applyBurn(targetHumanoid, sourcePlayer, newStacks)
	local effectName = "Burn"
	if not targetHumanoid or not targetHumanoid.Parent then
		warn("[applyBurn] Invalid target.") return
	end
	local baseDamage = AbilityManager.getMoveDamage("Burn", sourcePlayer)
	local extraTickChance = StateHandler.getStateValue(sourcePlayer, "ExtraBurnTickChance") or 0
	local burnResistReduction = StateHandler.getStateValue(sourcePlayer, "MagicResistanceReduction") or 0
	if burnResistReduction > 0 then
		local currentResist = getEntityStat(targetHumanoid, "MagicResistance")
		local newResist = math.max(0, currentResist - burnResistReduction)
		updateEntityStat(targetHumanoid, "MagicResistance", newResist)
		print(string.format("[Burn] Reduced Magic Resistance of %s by %.2f%%", targetHumanoid.Parent.Name, burnResistReduction))
	end
	local function tick()
		activeTicks[targetHumanoid] = activeTicks[targetHumanoid] or {}
		activeTicks[targetHumanoid][effectName] = true
		if not targetHumanoid or not targetHumanoid.Parent then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local healthInstance = getHealthInstance(targetHumanoid)
		if not healthInstance or healthInstance.Health <= 0 then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local currentStacks = activeStatuses[targetHumanoid] and activeStatuses[targetHumanoid][effectName] or 0
		if currentStacks <= 0 then
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Burn] Burn expired on " .. targetHumanoid.Parent.Name) return
		end
		local tickDamage = baseDamage
		if math.random(1, 100) <= extraTickChance then
			tickDamage = tickDamage * 1.2
			print(string.format("[Burn] Extra tick proc! %.2f damage dealt to %s", tickDamage, targetHumanoid.Parent.Name))
		end
		local consumptionRate = math.floor(currentStacks / 5) + 1
		local totalTickDamage = tickDamage * consumptionRate
		DamageType.applyDamage(targetHumanoid, totalTickDamage, sourcePlayer, "Burn")
		print(string.format("[Burn] Consumed %d stacks. %d stacks remaining on %s", consumptionRate, (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate, targetHumanoid.Parent.Name))
		activeStatuses[targetHumanoid][effectName] = (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate
		if activeStatuses[targetHumanoid][effectName] and activeStatuses[targetHumanoid][effectName] > 0 then
			task.delay(1, tick)
		else
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Burn] Burn expired on " .. targetHumanoid.Parent.Name)
		end
	end
	applyStackingEffect(targetHumanoid, effectName, sourcePlayer, newStacks, tick)
end

function Status.applyPoison(targetHumanoid, sourcePlayer, newStacks)
	local effectName = "Poison"
	if not targetHumanoid or not targetHumanoid.Parent then
		warn("[applyPoison] Invalid target.") return
	end
	local baseDamage = AbilityManager.getMoveDamage("Poison", sourcePlayer)
	local poisonTrueDamage = StateHandler.getStateValue(sourcePlayer, "PoisonTrueDamage") or 0
	local poisonVulnerability = StateHandler.getStateValue(targetHumanoid, "PoisonVulnerability") or 0
	if poisonVulnerability > 0 then
		local currentVulnerability = getEntityStat(targetHumanoid, "PoisonVulnerability")
		updateEntityStat(targetHumanoid, "PoisonVulnerability", currentVulnerability + poisonVulnerability)
	end
	local function tick()
		activeTicks[targetHumanoid] = activeTicks[targetHumanoid] or {}
		activeTicks[targetHumanoid][effectName] = true
		if not targetHumanoid or not targetHumanoid.Parent then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local healthInstance = getHealthInstance(targetHumanoid)
		if not healthInstance or healthInstance.Health <= 0 then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local currentStacks = activeStatuses[targetHumanoid] and activeStatuses[targetHumanoid][effectName] or 0
		if currentStacks <= 0 then
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Poison] Poison expired on " .. targetHumanoid.Parent.Name) return
		end
		local currentHealth = healthInstance.Health
		local healthBasedDamage = currentHealth * 0.10
		local tickDamage = baseDamage + healthBasedDamage
		if poisonTrueDamage > 0 then tickDamage = tickDamage + poisonTrueDamage end
		local consumptionRate = math.floor(currentStacks / 5) + 1
		local totalTickDamage = tickDamage * consumptionRate
		DamageType.applyDamage(targetHumanoid, totalTickDamage, sourcePlayer, "Poison")
		print(string.format("[Poison] Consumed %d stacks. %d stacks remaining on %s", consumptionRate, (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate, targetHumanoid.Parent.Name))
		activeStatuses[targetHumanoid][effectName] = (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate
		if activeStatuses[targetHumanoid][effectName] and activeStatuses[targetHumanoid][effectName] > 0 then
			task.delay(1, tick)
		else
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Poison] Poison expired on " .. targetHumanoid.Parent.Name)
		end
	end
	applyStackingEffect(targetHumanoid, effectName, sourcePlayer, newStacks, tick)
end

function Status.applyBleed(targetHumanoid, sourcePlayer, newStacks)
	local effectName = "Bleed"
	if not targetHumanoid or not targetHumanoid.Parent then
		warn("[applyBleed] Invalid target.") return
	end
	local baseDamage = AbilityManager.getMoveDamage("Bleed", sourcePlayer)
	local instantProcChance = StateHandler.getStateValue(sourcePlayer, "InstantBleedProcChance") or 0
	local bonusDamageToBleeding = StateHandler.getStateValue(sourcePlayer, "BonusPhysicalDamageToBleeding") or 0
	local antiHeal = StateHandler.getStateValue(sourcePlayer, "AntiHealOnBleed") or false

	-- Delay the first tick so that DOT damage doesn't immediately overlap the move's initial damage.
	local firstTick = true

	local function tick()
		activeTicks[targetHumanoid] = activeTicks[targetHumanoid] or {}
		activeTicks[targetHumanoid][effectName] = true
		if not targetHumanoid or not targetHumanoid.Parent then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local healthInstance = getHealthInstance(targetHumanoid)
		if not healthInstance or healthInstance.Health <= 0 then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local currentStacks = activeStatuses[targetHumanoid] and activeStatuses[targetHumanoid][effectName] or 0
		if currentStacks <= 0 then
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Bleed] Bleed expired on " .. targetHumanoid.Parent.Name) return
		end

		-- On the very first tick, delay the DOT application by 1 second.
		if firstTick then
			firstTick = false
			task.delay(1, tick)
			return
		end

		if math.random(1, 100) <= instantProcChance then
			local instantDamage = baseDamage * 0.2
			DamageType.applyDamage(targetHumanoid, instantDamage, sourcePlayer, "Bleed")
			print(string.format("[Bleed] Instant proc: %.2f extra damage applied to %s", instantDamage, targetHumanoid.Parent.Name))
		end
		local tickDamage = baseDamage
		local consumptionRate = math.floor(currentStacks / 5) + 1
		local totalTickDamage = tickDamage * consumptionRate
		DamageType.applyDamage(targetHumanoid, totalTickDamage, sourcePlayer, "Bleed")
		print(string.format("[Bleed] Consumed %d stacks. %d stacks remaining on %s", consumptionRate, (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate, targetHumanoid.Parent.Name))
		activeStatuses[targetHumanoid][effectName] = (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate
		if antiHeal then
			StateHandler.applyState(targetHumanoid, "HealingBlocked", true, newStacks)
			print("[Bleed] " .. targetHumanoid.Parent.Name .. " cannot heal while bleeding!")
		end
		if bonusDamageToBleeding > 0 then
			local bonusDamage = tickDamage * (bonusDamageToBleeding / 100)
			DamageType.applyDamage(targetHumanoid, bonusDamage, sourcePlayer, "Bleed")
			print(string.format("[Bleed] Bonus damage %.2f applied to %s", bonusDamage, targetHumanoid.Parent.Name))
		end
		if activeStatuses[targetHumanoid][effectName] and activeStatuses[targetHumanoid][effectName] > 0 then
			task.delay(1, tick)
		else
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Bleed] Bleed expired on " .. targetHumanoid.Parent.Name)
		end
	end
	applyStackingEffect(targetHumanoid, effectName, sourcePlayer, newStacks, tick)
end

function Status.applyIce(targetHumanoid, sourcePlayer, newStacks)
	local effectName = "Ice"
	if not targetHumanoid or not targetHumanoid.Parent then
		warn("[applyIce] Invalid target.") return
	end
	local damage = AbilityManager.getMoveDamage("Ice", sourcePlayer)
	local slowDurationIncrease = StateHandler.getStateValue(sourcePlayer, "SlowDurationIncrease") or 0
	local frozenZoneEffect = StateHandler.getStateValue(sourcePlayer, "FrozenZoneEffect") or 0
	local magicResistReduction = StateHandler.getStateValue(sourcePlayer, "MagicResistanceReduction") or 0
	local function tick()
		activeTicks[targetHumanoid] = activeTicks[targetHumanoid] or {}
		activeTicks[targetHumanoid][effectName] = true
		if not targetHumanoid or not targetHumanoid.Parent then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local healthInstance = getHealthInstance(targetHumanoid)
		if not healthInstance or healthInstance.Health <= 0 then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local currentStacks = activeStatuses[targetHumanoid] and activeStatuses[targetHumanoid][effectName] or 0
		if currentStacks <= 0 then
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Ice] Ice expired on " .. targetHumanoid.Parent.Name) return
		end
		local tickDamage = damage
		if magicResistReduction > 0 then
			local currentResist = getEntityStat(targetHumanoid, "MagicResistance")
			updateEntityStat(targetHumanoid, "MagicResistance", math.max(0, currentResist - magicResistReduction))
		end
		local consumptionRate = math.floor(currentStacks / 5) + 1
		local totalTickDamage = tickDamage * consumptionRate
		DamageType.applyDamage(targetHumanoid, totalTickDamage, sourcePlayer, "Ice")
		print(string.format("[Ice] Consumed %d stacks. %d stacks remaining on %s", consumptionRate, (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate, targetHumanoid.Parent.Name))
		activeStatuses[targetHumanoid][effectName] = (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate
		CrowdControlHandler.applyCC("Slowed", targetHumanoid, newStacks + slowDurationIncrease, sourcePlayer)
		if frozenZoneEffect > 0 and targetHumanoid.Parent.PrimaryPart then
			for _, nearbyPart in ipairs(workspace:GetPartBoundsInRadius(targetHumanoid.Parent.PrimaryPart.Position, 6)) do
				local nearbyHumanoid = nearbyPart.Parent:FindFirstChild("Humanoid")
				if nearbyHumanoid and nearbyHumanoid ~= targetHumanoid then
					local bonusZoneDamage = tickDamage * (frozenZoneEffect / 100) * consumptionRate
					DamageType.applyDamage(nearbyHumanoid, bonusZoneDamage, sourcePlayer, "Ice")
					print(string.format("[Ice] %.2f Frozen Zone bonus damage applied to %s", bonusZoneDamage, nearbyHumanoid.Parent.Name))
				end
			end
		end
		if activeStatuses[targetHumanoid][effectName] and activeStatuses[targetHumanoid][effectName] > 0 then
			task.delay(1, tick)
		else
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Ice] Ice expired on " .. targetHumanoid.Parent.Name)
		end
	end
	applyStackingEffect(targetHumanoid, effectName, sourcePlayer, newStacks, tick)
end

function Status.applyLightning(targetHumanoid, sourcePlayer, newStacks)
	local effectName = "Lightning"
	if not targetHumanoid or not targetHumanoid.Parent then
		warn("[applyLightning] Invalid target.") return
	end
	local baseDamage = AbilityManager.getMoveDamage("Lightning", sourcePlayer)
	local chainExtraTargets = StateHandler.getStateValue(sourcePlayer, "ChainExtraTargets") or 0
	local stunMagicPowerBonus = StateHandler.getStateValue(sourcePlayer, "StunMagicPowerBonus") or 0
	local lightningInfiniteChain = StateHandler.getStateValue(sourcePlayer, "LightningInfiniteChain") or false
	local antiHealOnStun = StateHandler.getStateValue(sourcePlayer, "AntiHealOnStun") or false
	targetHumanoid:SetAttribute("SpeedModifier", -10)
	task.delay(newStacks, function()
		if targetHumanoid then targetHumanoid:SetAttribute("SpeedModifier", 0) end
	end)
	local stunChance = 10
	if math.random(1, 100) <= stunChance then
		CrowdControlHandler.applyCC("Stunned", targetHumanoid, newStacks * 0.9, sourcePlayer)
		if antiHealOnStun then
			StateHandler.applyState(targetHumanoid, "HealingBlocked", true, newStacks)
			print("[Lightning] " .. targetHumanoid.Parent.Name .. " is blocked from healing!")
		end
	end
	local function tick()
		activeTicks[targetHumanoid] = activeTicks[targetHumanoid] or {}
		activeTicks[targetHumanoid][effectName] = true
		if not targetHumanoid or not targetHumanoid.Parent then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local healthInstance = getHealthInstance(targetHumanoid)
		if not healthInstance or healthInstance.Health <= 0 then
			activeTicks[targetHumanoid][effectName] = false; return
		end
		local currentStacks = activeStatuses[targetHumanoid] and activeStatuses[targetHumanoid][effectName] or 0
		if currentStacks <= 0 then
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
			print("[Lightning] Lightning expired on " .. targetHumanoid.Parent.Name) return
		end
		local damage = baseDamage
		if stunMagicPowerBonus > 0 and StateHandler.hasState(targetHumanoid, "Stunned") then
			damage = damage * (1 + (stunMagicPowerBonus / 100))
		end
		local consumptionRate = math.floor(currentStacks / 5) + 1
		local totalTickDamage = damage * consumptionRate
		DamageType.applyDamage(targetHumanoid, totalTickDamage, sourcePlayer, "Lightning")
		activeStatuses[targetHumanoid][effectName] = (activeStatuses[targetHumanoid][effectName] or 0) - consumptionRate
		if chainExtraTargets > 0 or lightningInfiniteChain then
			local maxTargets = lightningInfiniteChain and 999 or chainExtraTargets
			local hitTargets = {}
			if targetHumanoid.Parent.PrimaryPart then
				for _, nearbyPart in ipairs(workspace:GetPartBoundsInRadius(targetHumanoid.Parent.PrimaryPart.Position, 6)) do
					local nearbyHumanoid = nearbyPart.Parent:FindFirstChild("Humanoid")
					if nearbyHumanoid and nearbyHumanoid ~= targetHumanoid and not hitTargets[nearbyHumanoid] then
						DamageType.applyDamage(nearbyHumanoid, damage * 0.75, sourcePlayer, "Lightning")
						hitTargets[nearbyHumanoid] = true
						print(string.format("[Lightning] Chain hit %s for %.2f damage!", nearbyHumanoid.Parent.Name, damage * 0.75))
						if #hitTargets >= maxTargets then break end
					end
				end
			end
		end
		if activeStatuses[targetHumanoid][effectName] and activeStatuses[targetHumanoid][effectName] > 0 then
			task.delay(1, tick)
		else
			activeStatuses[targetHumanoid][effectName] = nil; activeTicks[targetHumanoid][effectName] = false
			stopParticleEffect(targetHumanoid, effectName)
		end
	end
	applyStackingEffect(targetHumanoid, effectName, sourcePlayer, newStacks, tick)
end

function Status.handleEffectType(targetHumanoid, effectType, damage, duration, sourcePlayer)
	if effectType == "Burn" then
		Status.applyBurn(targetHumanoid, sourcePlayer, duration)
	elseif effectType == "Poison" then
		Status.applyPoison(targetHumanoid, sourcePlayer, duration)
	elseif effectType == "Bleed" then
		Status.applyBleed(targetHumanoid, sourcePlayer, duration)
	elseif effectType == "Ice" then
		Status.applyIce(targetHumanoid, sourcePlayer, duration)
	elseif effectType == "Lightning" then
		Status.applyLightning(targetHumanoid, sourcePlayer, duration)
	else
		print("Effect type not recognized:", effectType)
	end
end

-- Break circular dependency by initializing DamageType with this module.
DamageType.init(Status)

return Status