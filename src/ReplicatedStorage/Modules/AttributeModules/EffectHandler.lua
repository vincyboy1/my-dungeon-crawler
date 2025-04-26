--------------------------------------------------
-- EffectHandler.lua
--
-- This unified module replaces the old VestigeHandler and StateHandler.
-- It uses instance attributes (via SetAttribute/GetAttribute) to store all
-- effect data and provides basic helper functions to modify, apply, and clear effects.
-- 
-- NOTE: This module provides a central API, but in a full game you would hook
-- its attribute changes into your damage, healing, or UI systems via GetAttributeChangedSignal.
--------------------------------------------------

local EffectHandler = {}

--------------------------------------------------
-- Default Effects Table (attributes for each effect)
--------------------------------------------------
EffectHandler.DefaultEffects = {
	-- Basic statuses
	PhysicalDamageBonus = 0,        -- Bonus flat physical damage
	MagicPowerBonus = 0,            -- Bonus magic power
	BleedDamageBonus = 0,           -- Bonus bleed damage
	BurnDamageBonus = 0,            -- Bonus burn damage
	CritChanceBonus = 0,            -- Bonus crit chance (in %)
	CritDamageBonus = 0,            -- Bonus crit damage (in %)
	DefenseModifier = 0,            -- Modifier to defense (in %)
	MovementSpeedModifier = 0,      -- Modifier to movement speed (in %)
	-- Other effects can be added here with default value of 0 or false for booleans
	ArmorPenetrationBonus = 0,
	SplashDamage = 0,
	MomentumPhysicalBonus = 0,
	CCBonusDamage = 0,
	MagicResistanceBonus = 0,
	FocusedMagicBonus = 0,
	SpellDOT = 0,
	MagicPenetration = 0,
	MagicResistanceReduction = 0,
	SpellKillDamageBonus = 0,
	TemporaryDamageReduction = 0,

	BleedDurationBonus = 0,
	BleedExecutionBonus = 0,
	BleedExecutionHeal = 0,
	InstantBleedProcBonus = 0,

	BurnProcChance = 0,
	BurnDurationBonus = 0,
	BurnDamageReduction = 0,
	BurnSpreadChance = 0,
	BurnStackBonus = 0,
	BurnKillBonus = 0,
	BurnExplosion = 0,

	CritMomentumBonus = 0,
	CritArmorReduction = 0,
	NextCritDamageBonus = 0,
	CritChainDamage = 0,
	LowHealthCritBonus = 0,
	CritCooldownReduction = 0,

	AllyHealingBonus = 0,
	HealingBonus = 0,
	HealingShieldOnHeal = 0,
	PassiveSelfHeal = 0,
	LowHealthHealingBonus = 0,
	HealingSpeedBonus = 0,
	OverhealShield = 0,
	DebuffRemovalBonus = 0,

	SlowEffect = 0,
	AreaSlowBonus = 0,

	StunChance = 0,
	ChainLightningBonus = 0,
	PostStunSpeedBonus = 0,
	StunDamageBonus = 0,
	ExtraChainTargets = 0,
	StunMagicBonus = 0,

	PoisonDamageBonus = 0,
	PoisonDurationBonus = 0,
	PoisonSlow = 0,
	PoisonDamageReduction = 0,
	PoisonSpread = 0,
	PoisonArmorReduction = 0,
	PoisonStunChance = 0,
	PoisonPool = 0,

	ShieldAbsorptionBonus = 0,
	ShieldDefenseBonus = 0,
	ReactiveShield = 0,
	ShieldCostReduction = 0,
	ShieldRegen = 0,
	ShieldDamageReduction = 0,
	DamageReflection = 0,
	ShieldExpireHeal = 0,

	ManaRegenBonus = 0,
	ManaOnHit = 0,
	AbilityCastSpeedBonus = 0,
	ManaRefundChance = 0,
	ExcessManaToShield = 0,
	SpellCooldownReduction = 0,
	ManaCostReduction = 0,

	MaxManaBonus = 0,
	PhysicalDefenseModifier = 0,

	HealthRegenBonus = 0,
	EmergencyHeal = 0,
	HealingManaRestore = 0,
	HealingReceivedBonus = 0,

	-- For Vitality vestiges:
	-- Additional effects can be added below:
}

--------------------------------------------------
-- Initialize all default effect attributes on a target instance.
-- target is typically a player’s character or a relevant instance.
function EffectHandler.initializeEffects(target)
	if not target or typeof(target) ~= "Instance" then return end
	for effect, defaultValue in pairs(EffectHandler.DefaultEffects) do
		-- Only set the attribute if it doesn't already exist.
		if target:GetAttribute(effect) == nil then
			target:SetAttribute(effect, defaultValue)
		end
	end
end

--------------------------------------------------
-- Apply (or update) a single effect on a target.
-- If duration is provided, resets to default after that many seconds.
function EffectHandler.applyEffect(target, effectName, value, duration)
	if not target or not effectName then return end
	EffectHandler.initializeEffects(target)
	target:SetAttribute(effectName, value)
	if duration then
		task.delay(duration, function()
			-- Reset to default value after duration expires.
			local defaultValue = EffectHandler.DefaultEffects[effectName]
			target:SetAttribute(effectName, defaultValue)
		end)
	end
end

--------------------------------------------------
-- Get the current value of an effect attribute on a target.
function EffectHandler.getEffect(target, effectName)
	if not target or not effectName then return nil end
	return target:GetAttribute(effectName)
end

--------------------------------------------------
-- Remove an effect by resetting it to its default.
function EffectHandler.removeEffect(target, effectName)
	if not target or not effectName then return end
	local defaultValue = EffectHandler.DefaultEffects[effectName]
	target:SetAttribute(effectName, defaultValue)
end

--------------------------------------------------
-- Modify a stat by adding a delta to the current effect.
-- The stat here is any effect attribute we wish to change.
function EffectHandler.modifyStat(target, statName, delta)
	if not target or not statName or type(delta) ~= "number" then return end
	EffectHandler.initializeEffects(target)
	local current = target:GetAttribute(statName) or 0
	target:SetAttribute(statName, current + delta)
end

--------------------------------------------------
-- Add to a stacked effect
function EffectHandler.addStack(target, effectName, stackAmount)
	stackAmount = stackAmount or 1
	EffectHandler.modifyStat(target, effectName, stackAmount)
end

--------------------------------------------------
-- Clear all effect attributes from the target, resetting them to defaults.
function EffectHandler.clearEffects(target)
	if not target then return end
	for effect, defaultValue in pairs(EffectHandler.DefaultEffects) do
		target:SetAttribute(effect, defaultValue)
	end
end

--------------------------------------------------
-- OPTIONAL: Hook into attribute changes via event listeners.
-- For example, you could do:
-- target:GetAttributeChangedSignal("SlowEffect"):Connect(function()
--    local newVal = target:GetAttribute("SlowEffect")
--    -- Update movement speed or UI accordingly.
-- end)
--------------------------------------------------

return EffectHandler