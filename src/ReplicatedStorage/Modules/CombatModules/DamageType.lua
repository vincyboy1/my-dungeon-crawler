--------------------------------------------------
-- DamageType.lua
--
-- This module calculates and applies final damage based on:
--  • Base Damage value,
--  • Attacker’s bonuses (stored as attributes such as "PhysicalDamageBonus" or "MagicalDamageBonus"),
--  • Target's resistances (from "PhysicalResistance" or "MagicalResistance"),
--  • And a global damage multiplier.
--
-- Only three damage types are supported:
--   "Physical", "Magical", and "True".
--
-- True Damage ignores resistances.
--
-- Global crit is handled within this module: for a given ability cast,
-- a crit roll is computed once and applied to all targets.
--------------------------------------------------

local DamageType = {}

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CustomHealthSystem = require(ReplicatedStorage.Modules.CombatModules.CustomHealthSystem)
local NPCHealthSystem    = require(ReplicatedStorage.Modules.CombatModules.CustomHealthSystem.NPCHealthSystem)
local RunService         = game:GetService("RunService")
local os_clock           = os.clock

-- For logging/debugging; set to true if needed.
local DEBUG_MODE = false
local function debugLog(...)
	if DEBUG_MODE then
		print("[DamageType Debug]", ...)
	end
end

-- Helper: safely fetch an attribute from an instance.
local function getStat(entity, statName)
	return entity:GetAttribute(statName) or 0
end

--------------------------------------------------
-- Global Crit Cache
--------------------------------------------------
-- Ensures the crit roll is computed only once per attacker+ability for multi-target hits
--------------------------------------------------

local critCache = {}             -- [ "UserId:AbilityName" ] = { isCrit, multiplier, expiry }
local CRIT_CACHE_DURATION = 5    -- seconds

local function getCachedCrit(attacker, abilityName)
	local key = tostring(attacker.UserId) .. ":" .. abilityName
	local now = os_clock()

	local entry = critCache[key]
	if entry and entry.expiry > now then
		return entry.isCrit, entry.multiplier
	end

	local critChance   = getStat(attacker, "CriticalChance") / 100
	local isCrit       = (math.random() < critChance)
	local critMult     = isCrit and (getStat(attacker, "CriticalDamage") or 1) or 1

	critCache[key] = {
		isCrit    = isCrit,
		multiplier= critMult,
		expiry    = now + CRIT_CACHE_DURATION,
	}

	return isCrit, critMult
end

--------------------------------------------------
-- Final Damage Calculation
--------------------------------------------------

function DamageType.calculateFinalDamage(baseDamage, attacker, targetHumanoid, damageType, abilityName)
	local globalMul = getStat(attacker, "DamageMultiplier") or 1

	-- True Damage bypasses resistances
	if damageType == "True" then
		local bonus = getStat(attacker, "TrueDamageBonus")
		local raw   = baseDamage * (1 + bonus/100) * globalMul
		debugLog("True Damage:", raw)
		return raw
	end

	-- Determine bonus and resistances
	local bonusStat       = (damageType == "Physical") and "PhysicalDamageBonus" or "MagicalDamageBonus"
	local resistanceStat  = (damageType == "Physical") and "PhysicalResistance"   or "MagicalResistance"
	local vulnerability   = (damageType == "Physical") and "PhysicalVulnerability" or "MagicalVulnerability"

	local bonus      = getStat(attacker, bonusStat)
	local resistance = math.clamp(getStat(targetHumanoid, resistanceStat), 0, 100)
	local vuln       = math.clamp(getStat(targetHumanoid, vulnerability), 0, 100)

	local dmg = baseDamage
		* (1 + bonus/100)
		* (1 - resistance/100 + vuln/100)
		* globalMul

	-- Apply a single crit roll across all targets if abilityName is provided
	local critMul = 1
	if abilityName then
		local isCrit, cmult = getCachedCrit(attacker, abilityName)
		if isCrit then
			critMul = cmult
			debugLog("Crit! x"..critMul)
		end
	end

	return dmg * critMul
end

--------------------------------------------------
-- Shield Absorption
--------------------------------------------------

function DamageType.applyShield(targetHumanoid, damage)
	local player = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if player then
		local hs = CustomHealthSystem.GetInstance(player)
		if hs then
			return hs:ApplyShield(damage)
		end
	end
	return damage
end

--------------------------------------------------
-- Apply Damage to a Single Target
--------------------------------------------------

function DamageType.applyDamage(targetHumanoid, baseDamage, attacker, damageType, abilityName, wisp)
	if type(baseDamage) ~= "number" or baseDamage <= 0 then
		debugLog("Invalid baseDamage:", baseDamage)
		return 0
	end

	-- Validate damageType
	if damageType ~= "Physical" and damageType ~= "Magical" and damageType ~= "True" then
		warn("[DamageType] Invalid damageType:", damageType)
		return 0
	end

	-- Calculate final damage
	local final = DamageType.calculateFinalDamage(baseDamage, attacker, targetHumanoid, damageType, abilityName)

	-- Wisp absorption (optional)
	if wisp and wisp.Health and wisp.Health > 0 then
		local absorbed = final * 0.3
		wisp.Health = math.max(0, wisp.Health - absorbed)
		final = final - absorbed
		debugLog("Wisp absorbed:", absorbed)
	end

	-- Shield absorption
	final = DamageType.applyShield(targetHumanoid, final)
	if final <= 0 then
		debugLog("All damage absorbed by shield.")
		return 0
	end

	-- Apply to player or NPC
	local targetPlayer = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	if targetPlayer then
		local hs = CustomHealthSystem.GetInstance(targetPlayer)
		hs:TakeDamage(final)
	else
		local npcHS = NPCHealthSystem.GetInstance(targetHumanoid.Parent)
		if npcHS then
			npcHS:TakeDamage(final)
		else
			warn("[DamageType] No health instance for", targetHumanoid.Parent.Name)
			return 0
		end
	end

	-- Broadcast the damage event (for floating text, etc.)
	DamageType.DamageBroadcast:Fire(targetHumanoid, final, damageType, attacker)

	return final
end

--------------------------------------------------
-- Splash/AoE Damage (optional)
--------------------------------------------------

function DamageType.applySplashDamage(originHumanoid, damage, range, attacker, damageType, abilityName)
	local root = originHumanoid.Parent:FindFirstChild("HumanoidRootPart")
	if not root then return end

	for _, part in ipairs(workspace:GetPartBoundsInRadius(root.Position, range)) do
		local hum = part.Parent:FindFirstChild("Humanoid")
		if hum and hum ~= originHumanoid then
			local splash = damage * 0.5
			local dmg = DamageType.calculateFinalDamage(splash, attacker, hum, damageType, abilityName)
			local pl = Players:GetPlayerFromCharacter(hum.Parent)
			if pl then
				CustomHealthSystem.GetInstance(pl):TakeDamage(dmg)
			else
				local npcHS = NPCHealthSystem.GetInstance(hum.Parent)
				if npcHS then npcHS:TakeDamage(dmg) end
			end
		end
	end
end

--------------------------------------------------
-- Damage Broadcast Event
--------------------------------------------------

DamageType.DamageBroadcast = Instance.new("BindableEvent")

return DamageType
