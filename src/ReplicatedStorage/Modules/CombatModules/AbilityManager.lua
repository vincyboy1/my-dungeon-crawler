--------------------------------------------------
-- AbilityManager.lua
--
-- This module unifies the handling of abilities.
-- It combines mana management, cooldown tracking,
-- ability validation, and dispatching of final damage
-- or healing.
--
-- All player stats (Mana, MaxMana, ManaRegen, etc.) are assumed
-- to be stored as instance attributes. This module reads and writes
-- these values directly.
--------------------------------------------------

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local os_clock   = os.clock
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityManager = {}

-- Helper: Safely get a numeric attribute from a player
local function getNumAttr(player, attrName)
	local v = player:GetAttribute(attrName)
	if type(v) == "number" then return v end
	if type(v) == "string" then
		local n = tonumber(v)
		if n then return n end
	end
	return 0
end

--------------------------------------------------
-- MOVE DEFINITIONS
--------------------------------------------------
local moveDefinitions = {
	-- Warrior Skills
	DestinedDeath        = { baseDamage = 25, scaling = { Physical = 2.0 }, effect = "Bleed",    duration = 7,  manaCost = 25, cooldown = 8,  minCooldown = 4 },
	BulwarkSlam          = { baseDamage = 50, scaling = { Physical = 1.8 },                      manaCost = 45, cooldown = 13, minCooldown = 8 },
	UnyieldingGuard      = { baseHealing = 10, scaling = { Health = 0.2 }, healingType = "Shield", manaCost = 30, cooldown = 10, minCooldown = 7 },

	-- Ranger Skills
	LightningMode        = { baseDamage = 0,                       manaCost = 25, cooldown = 10, minCooldown = 3 },
	SummonWisp           = { baseDamage = 0,                       manaCost = 45, cooldown = 15, minCooldown = 9 },
	ExplosiveTrap        = { baseDamage = 35, scaling = { Physical = 1.8 }, effect = "Burn",   duration = 8,  manaCost = 40, cooldown = 17, minCooldown = 9 },

	-- Mage Skills
	ElementalLock        = { baseDamage = 0,                       manaCost = 30, cooldown = 16, minCooldown = 5 },
	HexOfTheWithering    = {                             manaCost = 50, cooldown = 30, minCooldown = 15 },
	ShadowVeil           = { baseDamage = 0,                       manaCost = 60, cooldown = 15, minCooldown = 6 },

	-- Support Skills
	HealingLight         = { baseHealing = 2,  scaling = { Healing = 1.3 }, healingType = "Basic",    manaPerSecond = 9,  cooldown = 14, minCooldown = 8 },
	Haste                = { baseHealing = 0,                       manaCost = 40, cooldown = 20, minCooldown = 12 },
	Sanctuary            = { baseHealing = 5,  scaling = { Healing = 1.2 }, healingType = "Shield",    manaPerSecond = 15, cooldown = 14, minCooldown = 9 },

	-- Striker Skills
	ChainReaction        = { baseDamage = 15, scaling = { Physical = 1.7 },                      manaCost = 15, cooldown = 20, minCooldown = 8 },

	-- Universal Skills
	Fireball             = { baseDamage = 35, scaling = { Magic = 2.0, Burn = 1.0 }, effect = "Burn",   duration = 5,  manaCost = 20 },
	PoisonCloud          = { baseDamage = 4,  scaling = { Magic = 1.2, Poison = 1.4 }, effect = "Poison", duration = 7,  manaCost = 25 },
	BleedStrike          = { baseDamage = 30, scaling = { Physical = 1.2, Bleed = 1.2 }, effect = "Bleed", duration = 8,  manaCost = 15 },
	IceShard             = { baseDamage = 25, scaling = { Magic = 1.8, Ice = 1.0 },    effect = "Ice",     duration = 3,  manaCost = 35 },
	LightningBolt        = { baseDamage = 40, scaling = { Magic = 2.2, Lightning = 1.6 }, effect = "Lightning", duration = 2, manaCost = 40 },
	WindGust             = { baseDamage = 20, scaling = { Physical = 1.5 }},

	-- Basic Attacks
	BasicMeleeAttackWarrior = { baseDamage = 11, scaling = { Physical = 1.0 }},
	BasicMeleeAttackStriker = { baseDamage = 14, scaling = { Physical = 1.0 }},
	BasicAttackRanger       = { baseDamage = 9,  scaling = { Physical = 1.0 }},
	BasicMeleeAttackRanger  = { baseDamage = 2,  scaling = { Physical = 1.0 }},
	BasicAttackMage         = { baseDamage = 8,  scaling = { Magic = 1.0 }},
	BasicMeleeAttackMage    = { baseDamage = 2,  scaling = { Magic = 1.0 }},
	BasicAttackSupport      = { baseDamage = 5,  scaling = { Magic = 1.0 }},

	-- Advanced Basic Attacks
	IceBolt               = { baseDamage = 8,  scaling = { Magic = 0.5, Ice = 1.3 }, effect = "Ice", duration = 3 },
	Flamethrower          = { baseDamage = 0.7, scaling = { Magic = 0.2, Burn = 1.5 }, effect = "Burn", duration = 3 },
	PoisonPool            = { baseDamage = 3,  scaling = { Magic = 0.6, Poison = 1 }, effect = "Poison", duration = 2 },
	LightningStrike       = { baseDamage = 30, scaling = { Magic = 0.6, Lightning = 1.8 }, effect = "Lightning", duration = 2 },
	LightningArrow        = { baseDamage = 16, scaling = { Physical = 1.0, Lightning = 1.3 }, effect = "Lightning", duration = 3 },
	BasicHealSupport      = { baseHealing = 5, scaling = { Healing = 1.5 }, healingType = "Basic" },
	SanctuaryExplosion    = { baseDamage = 1, scaling = { Magic = 0.01 }},

	-- Status Effects
	Burn                  = { baseDamage = 2,  scaling = { Burn = 1 }},
	Poison                = { baseDamage = 1,  scaling = { Poison = 1 }},
	Bleed                 = { baseDamage = 3,  scaling = { Bleed = 1 }},
	Ice                   = { baseDamage = 3,  scaling = { Ice = 1 }},
	Lightning             = { baseDamage = 7,  scaling = { Lightning = 1 }},
}

AbilityManager.moveDefinitions = moveDefinitions

--------------------------------------------------
-- PLAYER INITIALIZATION & MANA REGENERATION
--------------------------------------------------

function AbilityManager.initializePlayer(player)
	if not player or not player:IsA("Player") then return end
	local maxMana = getNumAttr(player, "MaxMana")
	player:SetAttribute("Mana", maxMana)
	print("[AbilityManager] Initialized mana for", player.Name, "to", maxMana)
end

function AbilityManager.startManaRegen()
	RunService.Heartbeat:Connect(function(deltaTime)
		for _, player in ipairs(Players:GetPlayers()) do
			local currentMana = getNumAttr(player, "Mana")
			local maxMana = getNumAttr(player, "MaxMana")
			local regenRate = getNumAttr(player, "ManaRegen")
			if currentMana < maxMana then
				local newMana = math.min(currentMana + (regenRate * deltaTime), maxMana)
				player:SetAttribute("Mana", newMana)
			end
		end
	end)
end

--------------------------------------------------
-- COOLDOWN MANAGEMENT
--------------------------------------------------

local function getCooldownKey(player)
	return tostring(player.UserId)
end

function AbilityManager.startCooldown(player, abilityName, duration)
	local key = getCooldownKey(player)
	AbilityManager.cooldowns = AbilityManager.cooldowns or {}
	AbilityManager.cooldowns[key] = AbilityManager.cooldowns[key] or {}
	if AbilityManager.cooldowns[key][abilityName] then
		warn(abilityName .. " cooldown already active for:", player.Name)
		return
	end
	AbilityManager.cooldowns[key][abilityName] = os_clock() + duration
	task.delay(duration, function()
		if AbilityManager.cooldowns[key] then
			AbilityManager.cooldowns[key][abilityName] = nil
		end
	end)
end

function AbilityManager.isOnCooldown(player, abilityName)
	local key = getCooldownKey(player)
	if AbilityManager.cooldowns
		and AbilityManager.cooldowns[key]
		and AbilityManager.cooldowns[key][abilityName] then
		if os_clock() < AbilityManager.cooldowns[key][abilityName] then
			return true
		else
			AbilityManager.cooldowns[key][abilityName] = nil
			return false
		end
	end
	return false
end

--------------------------------------------------
-- MANA DEDUCTION & DRAIN
--------------------------------------------------

function AbilityManager.deductMana(player, cost)
	if not player then return false end
	local currentMana = getNumAttr(player, "Mana")
	local manaReduction = getNumAttr(player, "VestigeManaCostReduction")
	local adjustedCost = math.max(cost - manaReduction, 0)
	if currentMana < adjustedCost then return false end
	player:SetAttribute("Mana", currentMana - adjustedCost)
	local refundChance = getNumAttr(player, "VestigeManaRefundChance")
	if math.random(1,100) <= refundChance then
		local refundAmount = math.floor(adjustedCost * 0.5)
		local newMana = math.min(getNumAttr(player, "Mana") + refundAmount, getNumAttr(player, "MaxMana"))
		player:SetAttribute("Mana", newMana)
	end
	return true
end

function AbilityManager.startManaDrain(player, moveName, manaPerSecond, onStopCallback)
	-- (unchanged)
end

function AbilityManager.stopManaDrain(player, moveName)
	-- (unchanged)
end

--------------------------------------------------
-- ABILITY CASTING & DISPATCH
--------------------------------------------------

local function calculateMoveEffect(moveName, player, isHealing)
	local moveData = moveDefinitions[moveName]
	if not moveData then return 0 end
	local baseEffect = isHealing and (moveData.baseHealing or 0) or (moveData.baseDamage or 0)
	local total = baseEffect
	if moveData.scaling then
		for stat, mult in pairs(moveData.scaling) do
			total = total + getNumAttr(player, stat) * mult
		end
	end
	return total
end

function AbilityManager.getMoveDamage(moveName, player)
	return calculateMoveEffect(moveName, player, false)
end

function AbilityManager.canCast(player, moveName)
	local moveData = moveDefinitions[moveName]
	if not moveData then return false end

	-- Cooldown check
	if moveData.cooldown and AbilityManager.isOnCooldown(player, moveName) then
		return false
	end

	-- Mana check
	if moveData.manaCost and not AbilityManager.deductMana(player, moveData.manaCost) then
		return false
	end

	return true
end

function AbilityManager.applyAbility(targetHumanoid, moveName, player, damageType, overrideDamage)
	if not targetHumanoid or not player then return end

	-- DEBUG: verify moveData lookup
	local moveData = moveDefinitions[moveName]
	print("[AbilityManager] moveData for", moveName, moveData and "FOUND" or "nil")
	if not moveData then return end

	local effectValue = overrideDamage or calculateMoveEffect(moveName, player, moveData.baseHealing ~= nil)

	if moveData.cooldown then
		AbilityManager.startCooldown(player, moveName, moveData.cooldown)
	end

	if moveData.baseHealing then
		local HealingType = require(ReplicatedStorage.Modules.CombatModules.HealingType)
		HealingType.applyHealing(targetHumanoid, effectValue, player)
	else
		local DamageType = require(ReplicatedStorage.Modules.CombatModules.DamageType)
		DamageType.applyDamage(targetHumanoid, effectValue, player, damageType or "Physical", moveName)
	end
end

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------
AbilityManager.startManaRegen()
for _, p in ipairs(Players:GetPlayers()) do
	AbilityManager.initializePlayer(p)
end
Players.PlayerAdded:Connect(AbilityManager.initializePlayer)

return AbilityManager
