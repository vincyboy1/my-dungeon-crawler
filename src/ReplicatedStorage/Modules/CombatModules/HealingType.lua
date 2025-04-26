local HealingType = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StatsModule = require(game:GetService("ReplicatedStorage").Modules.AttributeModules.StatsModule)
local PartyManager = require(game:GetService("ReplicatedStorage").Modules.CombatModules.PartyManager)
local NPCPartyManager = require(game:GetService("ReplicatedStorage").Modules.CombatModules.PartyManager.NPCPartyManager)
local CrowdControlHandler = require(game:GetService("ReplicatedStorage").Modules.CombatModules.CrowdControlHandler)
local StateHandler = require(game:GetService("ReplicatedStorage").Modules.AttributeModules.StateHandler)
local CustomHealthSystem = require(game:GetService("ReplicatedStorage").Modules.CombatModules.CustomHealthSystem)
local NPCHealthSystem = require(game:GetService("ReplicatedStorage").Modules.CombatModules.CustomHealthSystem.NPCHealthSystem)

-- Healing Types
HealingType.Types = {
	Basic = "Basic",         -- Instant healing
	Regen = "Regen",         -- Over time healing
	Shield = "Shield",       -- Temporary shield (absorptive, expires)
	BonusHealth = "BonusHealth",   -- Permanent bonus health (acts like a permanent shield, until taken as damage)
	Lifesteal = "Lifesteal"  -- Converts damage dealt into healing for the attacker
}

HealingType.HealingBroadcast = Instance.new("BindableEvent")
HealingType.ShieldBroadcast = Instance.new("BindableEvent")

-- Enable debug logging if needed.
local DEBUG_MODE = true
local function debugLog(...)
	if DEBUG_MODE then
		print("[HealingType Debug]", ...)
	end
end

--------------------------------------------------
-- Basic Healing: Instantly restores health.
--------------------------------------------------
function HealingType.applyHealing(targetHumanoid, healingAmount, sourcePlayer)
	if typeof(healingAmount) ~= "number" or healingAmount <= 0 then
		warn("[HealingType] Invalid healing amount:", healingAmount)
		return
	end
	local playerStats = StatsModule.getStats(sourcePlayer) or {}
	local healingMultiplier = playerStats.HealingMultiplier or 1
	local finalHealing = healingAmount * healingMultiplier

	local stats = StatsModule.getStats(sourcePlayer)
	local allyHealingBonus = stats and stats.AllyHealing or 0
	if allyHealingBonus > 0 then
		local allyBonus = (allyHealingBonus / 100) * finalHealing
		PartyManager.applyToAllies(function(ally)
			if ally.Character and ally.Character:FindFirstChild("Humanoid") and ally ~= sourcePlayer then
				HealingType.applyHealing(ally.Character:FindFirstChild("Humanoid"), allyBonus, sourcePlayer)
			end
		end)
		NPCPartyManager.applyToAllAlliedNPCs(function(npc)
			local npcHumanoid = npc:FindFirstChildOfClass("Humanoid")
			if npcHumanoid then
				HealingType.applyHealing(npcHumanoid, allyBonus, sourcePlayer)
			end
		end)
	end

	local healthInstance
	local player = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if player then
		healthInstance = CustomHealthSystem.GetInstance(player)
	else
		healthInstance = NPCHealthSystem.GetInstance(targetHumanoid.Parent)
	end

	if healthInstance then
		healthInstance:Heal(finalHealing)
	else
		warn("[HealingType] No health instance found for", targetHumanoid.Parent.Name)
	end

	CrowdControlHandler.clearAllCC(targetHumanoid.Parent)

	local speedBoost = playerStats.VestigeSpeedOnAbilityCast or 0
	if speedBoost > 0 then
		local newSpeed = targetHumanoid.WalkSpeed + speedBoost
		targetHumanoid.WalkSpeed = newSpeed
		task.delay(3, function()
			if targetHumanoid then
				targetHumanoid.WalkSpeed = targetHumanoid.WalkSpeed - speedBoost
			end
		end)
	end

	local shieldOnOverheal = stats and stats.ShieldOnOverheal or 0
	if player then
		healthInstance = CustomHealthSystem.GetInstance(player)
	else
		healthInstance = NPCHealthSystem.GetInstance(targetHumanoid.Parent)
	end
	if healthInstance then
		local overheal = (healthInstance.Health + finalHealing) - healthInstance.MaxHealth
		if shieldOnOverheal > 0 and overheal > 0 then
			local shieldAmount = (shieldOnOverheal / 100) * overheal
			HealingType.applyShield(targetHumanoid, shieldAmount, sourcePlayer)
		end
	end

	debugLog(sourcePlayer and sourcePlayer.Name or "Unknown", "healed", targetHumanoid.Parent.Name, "for", finalHealing)
	HealingType.HealingBroadcast:Fire(targetHumanoid, finalHealing, sourcePlayer)
end

--------------------------------------------------
-- Temporary Shield: Absorbs damage for a limited duration.
--------------------------------------------------
function HealingType.applyShield(targetHumanoid, shieldAmount, sourcePlayer)
	if typeof(shieldAmount) ~= "number" or shieldAmount <= 0 then
		warn("[HealingType] Invalid shield amount:", shieldAmount)
		return
	end
	local playerStats = StatsModule.getStats(sourcePlayer) or {}
	local shieldMultiplier = playerStats.ShieldMultiplier or 1
	local shieldAbsorption = playerStats.DamageAbsorptionMultiplier or 0
	local shieldReflectDamage = playerStats.ReflectDamageMultiplier or 0

	local finalShield = shieldAmount * shieldMultiplier
	if shieldAbsorption > 0 then
		finalShield = finalShield * (1 + (shieldAbsorption / 100))
	end

	local healthInstance
	local player = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if player then
		healthInstance = CustomHealthSystem.GetInstance(player)
	else
		healthInstance = NPCHealthSystem.GetInstance(targetHumanoid.Parent)
	end

	if healthInstance then
		local currentShield = healthInstance.ShieldHealth or 0
		local maxShield = healthInstance.MaxHealth
		local newShieldTotal = math.min(currentShield + finalShield, maxShield)
		healthInstance.ShieldHealth = newShieldTotal
		healthInstance.HealthChanged:Fire(healthInstance:GetStatus())
		if shieldReflectDamage > 0 then
			healthInstance.ReflectDamage = shieldReflectDamage
			task.delay(5, function() healthInstance.ReflectDamage = 0 end)
		end
		debugLog(sourcePlayer and sourcePlayer.Name or "Unknown", "applied", finalShield, "shield to", targetHumanoid.Parent.Name, "(Capped at", maxShield, ")")
		if HealingType.ShieldBroadcast then
			HealingType.ShieldBroadcast:Fire(targetHumanoid, finalShield, sourcePlayer)
		end
	else
		warn("[HealingType] No health instance found for", targetHumanoid.Parent.Name)
	end
end

--------------------------------------------------
-- Regen (Over Time Healing): Gradually restores health.
-- Renamed from applyRegeneration for consistency.
--------------------------------------------------
function HealingType.applyRegen(targetHumanoid, totalHealing, duration, sourcePlayer)
	if typeof(totalHealing) ~= "number" or totalHealing <= 0 or duration <= 0 then
		warn("[HealingType] Invalid regeneration parameters.")
		return
	end
	local ticks = math.floor(duration)
	local healingPerTick = totalHealing / ticks
	for i = 1, ticks do
		task.delay(i, function()
			if targetHumanoid then
				HealingType.applyHealing(targetHumanoid, healingPerTick, sourcePlayer)
			end
		end)
	end
	debugLog(sourcePlayer and sourcePlayer.Name or "Unknown", "applied regen for", totalHealing, "over", duration, "seconds.")
end

--------------------------------------------------
-- Lifesteal: Heals the attacker based on damage dealt.
-- LifestealPercentage is defined as a percentage value (e.g. 1 means 1%).
-- Instead of a standalone function call, we now subscribe to the global DamageBroadcast.
--------------------------------------------------
-- Existing function remains in case manual invocation is desired.
function HealingType.applyLifesteal(damageDealt, sourcePlayer, targetHumanoid)
	if not sourcePlayer or typeof(damageDealt) ~= "number" or damageDealt <= 0 then
		warn("[HealingType] Invalid lifesteal parameters.")
		return
	end
	local playerStats = StatsModule.getStats(sourcePlayer) or {}
	local lifestealPercentage = playerStats.LifestealPercentage or 0
	if lifestealPercentage <= 0 then
		debugLog(sourcePlayer.Name, "has no LifestealPercentage stat.")
		return
	end
	local healAmount = damageDealt * (lifestealPercentage / 100)
	if healAmount > 0 then
		local playerHumanoid = sourcePlayer.Character and sourcePlayer.Character:FindFirstChild("Humanoid")
		if playerHumanoid then
			HealingType.applyHealing(playerHumanoid, healAmount, sourcePlayer)
			debugLog(sourcePlayer.Name, "healed for", healAmount, "via lifesteal from", targetHumanoid.Parent and targetHumanoid.Parent.Name or "unknown target")
		end
	end
end

--------------------------------------------------
-- BonusHealth: Permanently increases a health buffer.
-- This bonus remains until it is damaged and is capped at around 500% of the target’s Max Health.
--------------------------------------------------
function HealingType.applyBonusHealth(targetHumanoid, bonusAmount, sourcePlayer)
	if typeof(bonusAmount) ~= "number" or bonusAmount <= 0 then
		warn("[HealingType] Invalid bonus health amount:", bonusAmount)
		return
	end

	local healthInstance
	local player = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if player then
		healthInstance = CustomHealthSystem.GetInstance(player)
	else
		healthInstance = NPCHealthSystem.GetInstance(targetHumanoid.Parent)
	end

	if healthInstance then
		healthInstance.BonusHealth = (healthInstance.BonusHealth or 0) + bonusAmount
		healthInstance.HealthChanged:Fire(healthInstance:GetStatus())
		debugLog(sourcePlayer and sourcePlayer.Name or "Unknown", "applied bonus health of", bonusAmount, "to", targetHumanoid.Parent.Name)
	else
		warn("[HealingType] No health instance found for", targetHumanoid.Parent.Name)
	end
end

--------------------------------------------------
-- Lifesteal Auto-Listener:
-- This subscribes to DamageType's DamageBroadcast so lifesteal is applied automatically.
--------------------------------------------------
local DamageType = require(game:GetService("ReplicatedStorage").Modules.CombatModules.DamageType)
DamageType.DamageBroadcast.Event:Connect(function(targetHumanoid, damageDealt, damageType, sourcePlayer)
	-- Only apply lifesteal for valid damage events.
	if sourcePlayer and damageDealt and damageDealt > 0 then
		local playerStats = StatsModule.getStats(sourcePlayer) or {}
		local lifestealPercentage = playerStats.LifestealPercentage or 0
		if lifestealPercentage > 0 then
			local healAmount = damageDealt * (lifestealPercentage / 100)
			local playerHumanoid = sourcePlayer.Character and sourcePlayer.Character:FindFirstChild("Humanoid")
			if playerHumanoid then
				HealingType.applyHealing(playerHumanoid, healAmount, sourcePlayer)
				debugLog(sourcePlayer.Name, "automatically healed for", healAmount, "via lifesteal (damage broadcast).")
			end
		end
	end
end)

return HealingType