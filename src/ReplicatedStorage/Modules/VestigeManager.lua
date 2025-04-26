--------------------------------------------------
-- VestigeManager.lua
--
-- This module defines vestige categories, rarity weights,
-- and vestige mappings. Vestige mappings now use the new
-- unified EffectHandler (see EffectHandler.lua) to apply
-- stat modifications and effects according to our revised
-- vestige descriptions.
--------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectHandler = require(ReplicatedStorage.Modules.AttributeModules.EffectHandler)
local PlayerStatsManager = require(ReplicatedStorage.Modules.AttributeModules.StatsModule)

local VestigeManager = {}

-- Map classes to vestige categories
VestigeManager.ClassVestigeCategories = {
	Warrior  = {"Physical", "Bleed", "Crit", "Shields", "Mana", "Vitality"},
	Striker  = {"Physical", "Bleed", "Crit", "Mana", "Vitality"},
	Mage     = {"Magic", "Crit", "Ice", "Lightning", "Burn", "Mana", "Vitality"},
	Ranger   = {"Physical", "Burn", "Lightning", "Crit", "Mana", "Vitality"},
	Support  = {"Magic", "Healing", "Shields", "Mana", "Vitality"},
}

-- Define rarity weights: minor vestiges use lower numbers, major vestiges use a higher rarity value.
VestigeManager.RarityWeights = {
	[1]  = 60,  -- Minor vestiges (typically +1 bonus)
	[2]  = 40,  -- Some Minor variants (e.g. crit-related)
	[4]  = 25,  -- In some categories (Bleed, Burn, Ice, Lightning, Poison, Shields)
	[11] = 10,  -- Major vestiges (typically +3 bonus)
}

-- Returns a random vestige from a category based on weighted rarity.
function VestigeManager.GetRandomVestige(category)
	local vestiges = VestigeManager.Categories[category]
	if not vestiges then return nil end

	local weightedList = {}
	for _, vestige in ipairs(vestiges) do
		local weight = VestigeManager.RarityWeights[vestige.Rarity] or 0
		for _ = 1, weight do
			table.insert(weightedList, vestige)
		end
	end

	if #weightedList == 0 then return nil end
	return weightedList[math.random(#weightedList)]
end

-- Vestige definitions (updated names and descriptions).
-- Each vestige function calls EffectHandler methods to apply the appropriate effect,
-- for example by modifying a stat attribute or setting an effect flag.
VestigeManager.Categories = {
	Physical = {
		{
			Name = "Brutal Force",
			Rarity = 1,
			Apply = function(player)
				-- +10 Physical Damage bonus; -2% Movement Speed
				EffectHandler.modifyStat(player, "PhysicalDamageBonus", 10)
				EffectHandler.modifyStat(player, "MovementSpeedModifier", -2)
			end,
		},
		{
			Name = "Reckless Strike",
			Rarity = 1,
			Apply = function(player)
				-- +5% Physical Damage bonus; also increases damage taken by 2% and reduces Defense by 2%
				EffectHandler.modifyStat(player, "PhysicalDamageBonus", 5)
				EffectHandler.modifyStat(player, "IncomingDamageMultiplier", 2)
				EffectHandler.modifyStat(player, "DefenseModifier", -2)
			end,
		},
		{
			Name = "Wounding Strike",
			Rarity = 1,
			Apply = function(player)
				-- Physical attacks deal +5% damage to enemies with any debuff.
				EffectHandler.applyEffect(player, "BonusDamageToDebuffed", 1)
			end,
		},
		{
			Name = "Combat Reflexes",
			Rarity = 1,
			Apply = function(player)
				-- Every 10 seconds, next attack deals 20% increased damage.
				EffectHandler.applyEffect(player, "CombatReflexes", 1, 10)
			end,
		},
		{
			Name = "Tactical Precision",
			Rarity = 1,
			Apply = function(player)
				-- Physical attacks ignore 5% of enemy armor.
				EffectHandler.applyEffect(player, "ArmorPenetrationBonus", 5)
			end,
		},
		{
			Name = "Titanic Slam",
			Rarity = 11,
			Apply = function(player)
				-- Melee attacks deal 20% splash damage to nearby enemies.
				EffectHandler.applyEffect(player, "SplashDamage", 20)
			end,
		},
		{
			Name = "Relentless Strength",
			Rarity = 11,
			Apply = function(player)
				-- Killing an enemy increases Physical Damage by 5% for 5 seconds (stacks up to 5x)
				EffectHandler.applyEffect(player, "MomentumPhysicalBonus", 5, 5)
			end,
		},
		{
			Name = "Punishing Blows",
			Rarity = 11,
			Apply = function(player)
				-- Hitting a stunned, slowed, or rooted enemy deals an extra 15% damage.
				EffectHandler.applyEffect(player, "CCBonusDamage", 15)
			end,
		},
	},
	Magic = {
		{
			Name = "Arcane Precision",
			Rarity = 1,
			Apply = function(player)
				-- +5 Magic Power; -2% Defense.
				EffectHandler.modifyStat(player, "MagicPowerBonus", 5)
				EffectHandler.modifyStat(player, "DefenseModifier", -2)
			end,
		},
		{
			Name = "Runic Infusion",
			Rarity = 1,
			Apply = function(player)
				-- Gain 2% Magic Resistance for 5 seconds when casting a spell.
				EffectHandler.applyEffect(player, "MagicResistanceBonus", 2, 5)
			end,
		},
		{
			Name = "Focused Conduit",
			Rarity = 1,
			Apply = function(player)
				-- Casting abilities increases Magic Power by 2% for 6 seconds (stacks)
				EffectHandler.applyEffect(player, "FocusedMagicBonus", 2, 6)
			end,
		},
		{
			Name = "Mystic Flare",
			Rarity = 1,
			Apply = function(player)
				-- Spells apply a brief DOT equal to 10% of damage over 2 seconds.
				EffectHandler.applyEffect(player, "SpellDOT", 10, 2)
			end,
		},
		{
			Name = "Spellpiercer",
			Rarity = 1,
			Apply = function(player)
				-- Spells ignore 5% of enemy Magic Resistance.
				EffectHandler.applyEffect(player, "MagicPenetration", 5)
			end,
		},
		{
			Name = "Eldritch Weaving",
			Rarity = 11,
			Apply = function(player)
				-- Spells reduce enemy Magic Resistance by 5% (stacks up to 5)
				EffectHandler.applyEffect(player, "MagicResistanceReduction", 5)
			end,
		},
		{
			Name = "Sigil of Destruction",
			Rarity = 11,
			Apply = function(player)
				-- Kills with spells boost next spell damage by 20%.
				EffectHandler.applyEffect(player, "SpellKillDamageBonus", 20)
			end,
		},
		{
			Name = "Arcane Ward",
			Rarity = 11,
			Apply = function(player)
				-- Casting a spell grants temporary 10% damage reduction for 4 seconds.
				EffectHandler.applyEffect(player, "TemporaryDamageReduction", 10, 4)
			end,
		},
	},
	Bleed = {
		{
			Name = "Sharpened Blades",
			Rarity = 4,
			Apply = function(player)
				-- +2 Bleed Damage; -2% Crit Chance.
				EffectHandler.modifyStat(player, "BleedDamageBonus", 2)
				EffectHandler.modifyStat(player, "CritChanceModifier", -2)
			end,
		},
		{
			Name = "Extended Agony",
			Rarity = 4,
			Apply = function(player)
				-- Bleed duration increased by 1 second.
				EffectHandler.applyEffect(player, "BleedDurationBonus", 1)
			end,
		},
		{
			Name = "Flowing Blood",
			Rarity = 4,
			Apply = function(player)
				-- Gain 5% Life-Steal against Bleeding enemies.
				EffectHandler.applyEffect(player, "LifeStealBonusAgainstBleed", 5)
			end,
		},
		{
			Name = "Crimson Pressure",
			Rarity = 4,
			Apply = function(player)
				-- Bleeding enemies take 3% more Physical Damage.
				EffectHandler.applyEffect(player, "BleedDamageAmplification", 3)
			end,
		},
		{
			Name = "Bleed Spread",
			Rarity = 4,
			Apply = function(player)
				-- Bleeding enemies have a 10% chance to spread Bleed; -2% Physical Damage.
				EffectHandler.applyEffect(player, "BleedSpreadChance", 10)
				EffectHandler.modifyStat(player, "PhysicalDamageBonus", -2)
			end,
		},
		{
			Name = "Sanguine Execution",
			Rarity = 11,
			Apply = function(player)
				-- Attacks on Bleeding enemies grant 10% increased damage for 5 seconds (stacks 2x).
				EffectHandler.applyEffect(player, "BleedExecutionBonus", 10, 5)
			end,
		},
		{
			Name = "Hemorrhagic Surge",
			Rarity = 11,
			Apply = function(player)
				-- If Bleed damage would kill an enemy, execute them and heal 5% max health.
				EffectHandler.applyEffect(player, "BleedExecutionHeal", 5)
			end,
		},
		{
			Name = "Ruthless Bloodshed",
			Rarity = 11,
			Apply = function(player)
				-- Bleeding enemies take an additional 20% instant Bleed damage proc.
				EffectHandler.applyEffect(player, "InstantBleedProcBonus", 20)
			end,
		},
	},
	Burn = {
		{
			Name = "Flame Lash",
			Rarity = 4,
			Apply = function(player)
				-- +3 Burn Damage; -2% Defense.
				EffectHandler.modifyStat(player, "BurnDamageBonus", 3)
				EffectHandler.modifyStat(player, "DefenseModifier", -2)
			end,
		},
		{
			Name = "Ignition Spark",
			Rarity = 4,
			Apply = function(player)
				-- 5% chance on hit to apply Burn.
				EffectHandler.applyEffect(player, "BurnProcChance", 5)
			end,
		},
		{
			Name = "Creeping Fire",
			Rarity = 4,
			Apply = function(player)
				-- Burn duration increased by 1 second.
				EffectHandler.applyEffect(player, "BurnDurationBonus", 1)
			end,
		},
		{
			Name = "Smoldering Aura",
			Rarity = 4,
			Apply = function(player)
				-- Burned enemies deal 2% less damage.
				EffectHandler.applyEffect(player, "BurnDamageReduction", 2)
			end,
		},
		{
			Name = "Heat Chain",
			Rarity = 4,
			Apply = function(player)
				-- Burning enemies have 10% chance to spread fire on death; -2% Magic Resistance.
				EffectHandler.applyEffect(player, "BurnSpreadChance", 10)
				EffectHandler.modifyStat(player, "MagicResistance", -2)
			end,
		},
		{
			Name = "Inferno Surge",
			Rarity = 11,
			Apply = function(player)
				-- Each active Burn stack increases Burn damage by 4% (max 5 stacks).
				EffectHandler.applyEffect(player, "BurnStackBonus", 4)
			end,
		},
		{
			Name = "Pyromancer’s Resilience",
			Rarity = 11,
			Apply = function(player)
				-- Killing a Burning enemy restores 5 Mana and grants +10% Movement Speed for 5 seconds.
				EffectHandler.applyEffect(player, "BurnKillBonus", 5, 5)
				EffectHandler.applyEffect(player, "MovementSpeedBuff", 10, 5)
			end,
		},
		{
			Name = "Immolation Nova",
			Rarity = 11,
			Apply = function(player)
				-- Burning enemies explode on death, dealing damage equal to 15% of their max health.
				EffectHandler.applyEffect(player, "BurnExplosion", 15)
			end,
		},
	},
	Crit = {
		{
			Name = "Critical Edge",
			Rarity = 2,
			Apply = function(player)
				-- +5% Crit Damage; -2% Defense.
				EffectHandler.modifyStat(player, "CritDamageBonus", 5)
				EffectHandler.modifyStat(player, "DefenseModifier", -2)
			end,
		},
		{
			Name = "Sharp Precision",
			Rarity = 2,
			Apply = function(player)
				-- +2% Crit Chance.
				EffectHandler.modifyStat(player, "CritChanceBonus", 2)
			end,
		},
		{
			Name = "Lethal Momentum",
			Rarity = 2,
			Apply = function(player)
				-- Gain 1% Crit Chance for 2s after each crit (stacks up to 5%).
				EffectHandler.applyEffect(player, "CritMomentumBonus", 1, 2)
			end,
		},
		{
			Name = "Shattering Impact",
			Rarity = 2,
			Apply = function(player)
				-- Crits reduce enemy armor by 5% for 3 seconds.
				EffectHandler.applyEffect(player, "CritArmorReduction", 5, 3)
			end,
		},
		{
			Name = "Assassin’s Mark",
			Rarity = 2,
			Apply = function(player)
				-- Crits boost next attack damage by 10%.
				EffectHandler.applyEffect(player, "NextCritDamageBonus", 10)
			end,
		},
		{
			Name = "Deadly Chain",
			Rarity = 11,
			Apply = function(player)
				-- Crits deal 25% of their damage to a nearby enemy.
				EffectHandler.applyEffect(player, "CritChainDamage", 25)
			end,
		},
		{
			Name = "Executioner’s Precision",
			Rarity = 11,
			Apply = function(player)
				-- Crits against enemies below 30% health deal 20% more damage.
				EffectHandler.applyEffect(player, "LowHealthCritBonus", 20)
			end,
		},
		{
			Name = "Relentless Criticals",
			Rarity = 11,
			Apply = function(player)
				-- Landing a crit reduces cooldown of next ability by 1s.
				EffectHandler.applyEffect(player, "CritCooldownReduction", 1)
			end,
		},
	},
	Healing = {
		{
			Name = "Restorative Flow",
			Rarity = 2,
			Apply = function(player)
				-- +5 Healing Power; -2% Physical Resistance.
				EffectHandler.modifyStat(player, "HealingBonus", 5)
				EffectHandler.modifyStat(player, "PhysicalResistance", -2)
			end,
		},
		{
			Name = "Healing Aura",
			Rarity = 2,
			Apply = function(player)
				-- Allies receive 10% bonus healing.
				EffectHandler.applyEffect(player, "AllyHealingBonus", 10)
			end,
		},
		{
			Name = "Enduring Vitality",
			Rarity = 2,
			Apply = function(player)
				-- Gain a shield equal to 5% of max health when healing an ally.
				EffectHandler.applyEffect(player, "HealingShieldOnHeal", 5)
			end,
		},
		{
			Name = "Soothing Breeze",
			Rarity = 2,
			Apply = function(player)
				-- Heal for 1% of max health every 10 seconds.
				EffectHandler.applyEffect(player, "PassiveSelfHeal", 1, 10)
			end,
		},
		{
			Name = "Resilient Spirit",
			Rarity = 2,
			Apply = function(player)
				-- +5% Healing Received when below 50% health.
				EffectHandler.applyEffect(player, "LowHealthHealingBonus", 5)
			end,
		},
		{
			Name = "Healing Surge",
			Rarity = 11,
			Apply = function(player)
				-- Healing allies grant +10% movement speed for 3s.
				EffectHandler.applyEffect(player, "HealingSpeedBonus", 10, 3)
			end,
		},
		{
			Name = "Overflowing Renewal",
			Rarity = 11,
			Apply = function(player)
				-- Overhealing grants temporary shields equal to 50% of overheal.
				EffectHandler.applyEffect(player, "OverhealShield", 50)
			end,
		},
		{
			Name = "Celestial Radiance",
			Rarity = 11,
			Apply = function(player)
				-- Healing an ally removes one debuff and grants 10% bonus healing for 5s.
				EffectHandler.applyEffect(player, "DebuffRemovalBonus", 10, 5)
			end,
		},
	},
	Ice = {
		{
			Name = "Chilling Touch",
			Rarity = 4,
			Apply = function(player)
				-- Slows enemies by 5% for 2s; -2% Physical Damage.
				EffectHandler.applyEffect(player, "SlowEffect", 5, 2)
				EffectHandler.modifyStat(player, "PhysicalDamageBonus", -2)
			end,
		},
		{
			Name = "Glacial Spread",
			Rarity = 4,
			Apply = function(player)
				-- Slowing effects extend to enemies within 3 studs; -2% Movement Speed.
				EffectHandler.applyEffect(player, "AreaSlowBonus", 5)
				EffectHandler.modifyStat(player, "MovementSpeedModifier", -2)
			end,
		},
		{
			Name = "Frozen Fortitude",
			Rarity = 4,
			Apply = function(player)
				-- Gain 5% Magic Resistance when near slowed enemies.
				EffectHandler.applyEffect(player, "MagicResistanceBonus", 5)
			end,
		},
		{
			Name = "Icy Veins",
			Rarity = 4,
			Apply = function(player)
				-- Slowed enemies deal 5% less damage.
				EffectHandler.applyEffect(player, "DamageReductionAgainstSlowed", 5)
			end,
		},
		{
			Name = "Frostbite",
			Rarity = 4,
			Apply = function(player)
				-- Slowed enemies take 3% more damage.
				EffectHandler.applyEffect(player, "AdditionalDamageOnSlow", 3)
			end,
		},
		{
			Name = "Glacial Nova",
			Rarity = 11,
			Apply = function(player)
				-- 5% chance to freeze slowed enemies for 2s.
				EffectHandler.applyEffect(player, "FreezeChance", 5, 2)
			end,
		},
		{
			Name = "Permafrost",
			Rarity = 11,
			Apply = function(player)
				-- Slowing effects last 50% longer.
				EffectHandler.applyEffect(player, "SlowDurationIncrease", 50)
			end,
		},
		{
			Name = "Frozen Domain",
			Rarity = 11,
			Apply = function(player)
				-- Enemies inside a 6-stud radius take 10% more damage and are slowed an extra 10%.
				EffectHandler.applyEffect(player, "AreaSlowExtra", 10)
			end,
		},
	},
	Lightning = {
		{
			Name = "Electroshock",
			Rarity = 4,
			Apply = function(player)
				-- 5% chance to stun enemies for 1s; -2% Defense.
				EffectHandler.applyEffect(player, "StunChance", 5, 1)
				EffectHandler.modifyStat(player, "DefenseModifier", -2)
			end,
		},
		{
			Name = "Chain Lightning",
			Rarity = 4,
			Apply = function(player)
				-- Attacks chain to 2 nearby enemies for 50% damage; -2% Physical Damage.
				EffectHandler.applyEffect(player, "ChainLightningBonus", 50)
				EffectHandler.modifyStat(player, "PhysicalDamageBonus", -2)
			end,
		},
		{
			Name = "Static Surge",
			Rarity = 4,
			Apply = function(player)
				-- Gain 5% movement speed for 3s after stunning an enemy.
				EffectHandler.applyEffect(player, "PostStunSpeedBonus", 5, 3)
			end,
		},
		{
			Name = "Charged Conduit",
			Rarity = 4,
			Apply = function(player)
				-- Enemies stunned by you take 10% more damage for 2s.
				EffectHandler.applyEffect(player, "StunDamageBonus", 10, 2)
			end,
		},
		{
			Name = "Electric Flux",
			Rarity = 4,
			Apply = function(player)
				-- Regenerate 1% mana on chaining attacks.
				EffectHandler.applyEffect(player, "ChainManaRegen", 1)
			end,
		},
		{
			Name = "Thunderclap",
			Rarity = 11,
			Apply = function(player)
				-- Stunned enemies have 100% anti-heal for the stun duration.
				EffectHandler.applyEffect(player, "AntiHealOnStun", 100)
			end,
		},
		{
			Name = "High Voltage",
			Rarity = 11,
			Apply = function(player)
				-- Lightning chains to 2 additional enemies.
				EffectHandler.applyEffect(player, "ExtraChainTargets", 2)
			end,
		},
		{
			Name = "Storm Infusion",
			Rarity = 11,
			Apply = function(player)
				-- Every time you stun an enemy, gain 5% bonus Magic Power for 5s (stacks 3x).
				EffectHandler.applyEffect(player, "StunMagicBonus", 5, 5)
			end,
		},
	},
	Poison = {
		{
			Name = "Toxic Blades",
			Rarity = 4,
			Apply = function(player)
				-- +1 Poison Damage; -2% Physical Damage.
				EffectHandler.modifyStat(player, "PoisonDamageBonus", 1)
				EffectHandler.modifyStat(player, "PhysicalDamageBonus", -2)
			end,
		},
		{
			Name = "Lingering Venom",
			Rarity = 4,
			Apply = function(player)
				-- Poison lasts 1 second longer.
				EffectHandler.applyEffect(player, "PoisonDurationBonus", 1)
			end,
		},
		{
			Name = "Neurotoxin",
			Rarity = 4,
			Apply = function(player)
				-- Poisoned enemies are slowed by 5%.
				EffectHandler.applyEffect(player, "PoisonSlow", 5)
			end,
		},
		{
			Name = "Venomous Precision",
			Rarity = 4,
			Apply = function(player)
				-- Poisoned enemies deal 2% less damage.
				EffectHandler.applyEffect(player, "PoisonDamageReduction", 2)
			end,
		},
		{
			Name = "Contagion",
			Rarity = 4,
			Apply = function(player)
				-- Poison spreads to enemies within 3 studs; -2% Magic Damage.
				EffectHandler.applyEffect(player, "PoisonSpread", 3)
				EffectHandler.modifyStat(player, "MagicDamageBonus", -2)
			end,
		},
		{
			Name = "Corrosive Strike",
			Rarity = 11,
			Apply = function(player)
				-- Poison reduces enemy armor by 15%.
				EffectHandler.applyEffect(player, "PoisonArmorReduction", 15)
			end,
		},
		{
			Name = "Paralytic Venom",
			Rarity = 11,
			Apply = function(player)
				-- 10% chance to stun poisoned enemies for 1 second.
				EffectHandler.applyEffect(player, "PoisonStunChance", 10, 1)
			end,
		},
		{
			Name = "Virulent Decay",
			Rarity = 11,
			Apply = function(player)
				-- Poisoned enemies leave a poison pool on death.
				EffectHandler.applyEffect(player, "PoisonPool", 1)
			end,
		},
	},
	Shields = {
		{
			Name = "Barrier Strength",
			Rarity = 4,
			Apply = function(player)
				-- Shields absorb 10% more damage; -2% Movement Speed.
				EffectHandler.applyEffect(player, "ShieldAbsorptionBonus", 10)
				EffectHandler.modifyStat(player, "MovementSpeedModifier", -2)
			end,
		},
		{
			Name = "Fortified Barrier",
			Rarity = 4,
			Apply = function(player)
				-- Shields provide 5% increased defense; -2% Crit Chance.
				EffectHandler.applyEffect(player, "ShieldDefenseBonus", 5)
				EffectHandler.modifyStat(player, "CritChanceBonus", -2)
			end,
		},
		{
			Name = "Reactive Barrier",
			Rarity = 4,
			Apply = function(player)
				-- Gain a brief shield equal to 5% max health when struck.
				EffectHandler.applyEffect(player, "ReactiveShield", 5)
			end,
		},
		{
			Name = "Efficient Guard",
			Rarity = 4,
			Apply = function(player)
				-- Shields cost 5% less mana.
				EffectHandler.applyEffect(player, "ShieldCostReduction", 5)
			end,
		},
		{
			Name = "Resilient Protection",
			Rarity = 4,
			Apply = function(player)
				-- Gain a shield equal to 2% max health every 5 seconds while shielded.
				EffectHandler.applyEffect(player, "ShieldRegen", 2, 5)
			end,
		},
		{
			Name = "Shield Wall",
			Rarity = 11,
			Apply = function(player)
				-- Shields give 10% damage reduction while active.
				EffectHandler.applyEffect(player, "ShieldDamageReduction", 10)
			end,
		},
		{
			Name = "Echo Shield",
			Rarity = 11,
			Apply = function(player)
				-- 25% of absorbed damage is reflected.
				EffectHandler.applyEffect(player, "DamageReflection", 25)
			end,
		},
		{
			Name = "Aegis Resurgence",
			Rarity = 11,
			Apply = function(player)
				-- When a shield expires, heal for 5% of the remaining shield.
				EffectHandler.applyEffect(player, "ShieldExpireHeal", 5)
			end,
		},
	},
	Mana = {
		{
			Name = "Arcane Wellspring",
			Rarity = 2,
			Apply = function(player)
				-- +10 Max Mana; -2% Physical Defense.
				EffectHandler.modifyStat(player, "MaxManaBonus", 10)
				EffectHandler.modifyStat(player, "PhysicalDefenseModifier", -2)
			end,
		},
		{
			Name = "Meditative Flow",
			Rarity = 2,
			Apply = function(player)
				-- +5% Mana Regen; -2% Crit Damage.
				EffectHandler.applyEffect(player, "ManaRegenBonus", 5)
				EffectHandler.modifyStat(player, "CritDamageBonus", -2)
			end,
		},
		{
			Name = "Mana Surge",
			Rarity = 2,
			Apply = function(player)
				-- Regain 2 Mana per enemy hit.
				EffectHandler.applyEffect(player, "ManaOnHit", 2)
			end,
		},
		{
			Name = "Overflowing Arcana",
			Rarity = 2,
			Apply = function(player)
				-- On ability cast, gain 1% movement speed for 3s.
				EffectHandler.applyEffect(player, "AbilityCastSpeedBonus", 1, 3)
			end,
		},
		{
			Name = "Mana Conduit",
			Rarity = 2,
			Apply = function(player)
				-- 10% chance to refund 50% of the mana cost.
				EffectHandler.applyEffect(player, "ManaRefundChance", 10)
			end,
		},
		{
			Name = "Eldritch Overflow",
			Rarity = 11,
			Apply = function(player)
				-- If mana is full, excess regen grants shields.
				EffectHandler.applyEffect(player, "ExcessManaToShield", 1)
			end,
		},
		{
			Name = "Spell Catalyst",
			Rarity = 11,
			Apply = function(player)
				-- Casting a spell reduces another's cooldown by 1 second.
				EffectHandler.applyEffect(player, "SpellCooldownReduction", 1)
			end,
		},
		{
			Name = "Archmage’s Flow",
			Rarity = 11,
			Apply = function(player)
				-- Mana abilities cost 10% less.
				EffectHandler.applyEffect(player, "ManaCostReduction", 10)
			end,
		},
	},
	Vitality = {
		{
			Name = "Fortified Body",
			Rarity = 2,
			Apply = function(player)
				-- +10 Max HP; -2% Movement Speed.
				EffectHandler.modifyStat(player, "MaxHPBonus", 10)
				EffectHandler.modifyStat(player, "MovementSpeedModifier", -2)
			end,
		},
		{
			Name = "Enduring Resolve",
			Rarity = 2,
			Apply = function(player)
				-- +1% health regen every 5 seconds.
				EffectHandler.applyEffect(player, "HealthRegenBonus", 1, 5)
			end,
		},
		{
			Name = "Second Wind",
			Rarity = 2,
			Apply = function(player)
				-- Heal 10% HP once when below 30% (cooldown handled elsewhere).
				EffectHandler.applyEffect(player, "EmergencyHeal", 10)
			end,
		},
		{
			Name = "Overcharged Recovery",
			Rarity = 2,
			Apply = function(player)
				-- Healing restores 2% Mana.
				EffectHandler.applyEffect(player, "HealingManaRestore", 2)
			end,
		},
		{
			Name = "Resilient Veins",
			Rarity = 2,
			Apply = function(player)
				-- +5% healing received; -2% Magic Resistance.
				EffectHandler.applyEffect(player, "HealingReceivedBonus", 5)
				EffectHandler.modifyStat(player, "MagicResistance", -2)
			end,
		},
		{
			Name = "Undying Will",
			Rarity = 11,
			Apply = function(player)
				-- When reaching 1 HP, survive for 2 seconds.
				EffectHandler.applyEffect(player, "SurviveAt1HP", 1)
			end,
		},
		{
			Name = "Life Surge",
			Rarity = 11,
			Apply = function(player)
				-- Damage taken above 20% of max HP is reduced by 15%.
				EffectHandler.applyEffect(player, "DamageReductionOnBigHits", 15)
			end,
		},
		{
			Name = "Blood Infusion",
			Rarity = 11,
			Apply = function(player)
				-- Lifesteal effects heal for 10% more.
				EffectHandler.applyEffect(player, "LifestealBonus", 10)
			end,
		},
	},
}

-- Apply a vestige effect by name.
function VestigeManager.ApplyVestige(player, vestigeName)
	local vestigeData = nil
	-- Search in all category groups
	for _, category in pairs(VestigeManager.Categories) do
		for _, vestige in ipairs(category) do
			if vestige.Name == vestigeName then
				vestigeData = vestige
				break
			end
		end
		if vestigeData then break end
	end
	if vestigeData and vestigeData.Apply then
		vestigeData.Apply(player)
	else
		warn("Unknown vestige:", vestigeName)
	end
end

return VestigeManager