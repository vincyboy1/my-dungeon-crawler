local StateHandler = {}

local Players = game:GetService("Players")
local CustomHealthSystem = require(game.ReplicatedStorage.Modules.CombatModules.CustomHealthSystem)

-- Table to track active states for each entity
StateHandler.ActiveStates = {}

-- List of predefined states that all entities can have
StateHandler.DefaultStates = {
	-- Basic states
	BurnActive = false,
	PoisonActive = false,
	BleedActive = false,
	FreezeActive = false,
	ShockActive = false,
	Slowed = false,
	Rooted = false,
	Stunned = false,
	Silenced = false,
	Taunted = false,
	Ragdolled = false,
	ShieldHealth = 0,           -- Now handled by CustomHealthSystem
	ReflectDamage = 0,          -- Numeric value for damage reflection
	DamageAbsorption = 0,       -- Numeric value for damage absorption

	-- Burn Effects
	BurnChance = 0,             
	ExtraBurnTickChance = 0,    
	BurnSpreadTick = false,     
	MagicResistanceReduction = 0,
	BurnExplosion = false,      
	BurnStackScaling = 0,       

	-- Bleed Effects
	InstantBleedProcChance = 0, 
	BonusPhysicalDamageToBleeding = 0,
	AntiHealOnBleed = false,      
	BleedSpreadChance = 0,        
	BleedExecuteThreshold = 0,    
	BleedFury = false,            

	-- Poison Effects
	PoisonVulnerability = 0,      
	PoisonTrueDamage = 0,         
	PoisonShield = 0,             
	PoisonSpreadRange = 0,        
	PoisonStunChance = 0,         
	PoisonSlowEffect = 0,         
	PoisonPoolEffect = false,     
	PoisonArmorReduction = 0,     

	-- Ice Effects
	BonusDamageToSlowed = 0,      
	SlowDurationIncrease = 0,     
	SlowFreezeChance = 0,         
	FrozenZoneEffect = false,     
	ReducedDamageFromSlowed = 0,  

	-- Lightning Effects
	ChainAttackTargets = 0,       
	StunMagicPowerBonus = 0,      
	LightningInfiniteChain = false,
	AntiHealOnStun = false,       
	SpeedBoostOnStun = false,     
	ChainExtraTargets = 0,        
	ManaRegenOnChain = 0,         

	-- Healing Effects
	HealingBlocked = false,       
	AllyHealingBonus = 0,         
	HealingDefenseBoost = 0,      
	OverhealShield = 0,           
	HealingMovementSpeedBuff = 0, 
	HealingReflection = 0,        
	DebuffRemovalOnHeal = false,  
	LowHPHealingBonus = 0,        
	SelfHealingOverTime = 0,      

	-- Shields Effects
	ShieldDurationIncrease = 0,   
	ShieldBonusOnExpire = 0,      
	ShieldOnHit = false,          
	ShieldReflectDamage = 0,      
	AegisResurgence = false,      
	ShieldAmount = 0,             
	ShieldGuard = 0,              
	ShieldRemaining = 0,          

	-- Mana Effects
	ManaRestoreOnHit = 0,         
	ManaRefundChance = 0,         
	ExcessManaToShield = false,   
	SpeedOnAbilityCast = 0,       
	CooldownReductionOnCast = 0,  
	ManaAbilityCostReduction = 0, 

	-- Vitality Effects
	EmergencyHealOnLowHP = 0,     
	DamageReductionOnBigHits = 0, 
	SurviveAt1HP = false,         
	HealingRestoresMana = 0,      

	-- New States for Additional Vestige Effects
	BonusHealingReceived = 0,     
	TemporaryShield = 0,          
	MovementSpeedBuff = 0,        
	PoisonDuration = 0,           
	PoisonPool = false,           
	AreaSlow = 0,                 
	FrozenZone = 0,               
	AntiHeal = false,             
	CooldownReduction = 0,        
	MagicDOT = 0,                 
	ChainTargets = 0,             
}

-- Function to initialize states for a new entity
function StateHandler.initializeStates(target)
	if not target then return end
	StateHandler.ActiveStates[target] = {}
	for state, value in pairs(StateHandler.DefaultStates) do
		StateHandler.ActiveStates[target][state] = value
	end
end

-- Function to apply a state.
function StateHandler.applyState(target, stateName, value, duration)
	if not target or not stateName then
		warn("[StateHandler] Invalid parameters for applying state.")
		return
	end

	-- For shield-related state, delegate to CustomHealthSystem.
	if stateName == "ShieldHealth" then
		local player = Players:GetPlayerFromCharacter(target.Parent)
		if player then
			local healthInstance = CustomHealthSystem.GetInstance(player)
			if healthInstance then
				healthInstance.ShieldHealth = value
				print("[StateHandler] Applied ShieldHealth state to", target.Name, "with value:", value)
				if duration then
					task.delay(duration, function()
						healthInstance.ShieldHealth = 0
						print("[StateHandler] ShieldHealth state expired for", target.Name)
					end)
				end
			end
		end
		return
	end

	-- Initialize state table for the target if it doesn't exist
	StateHandler.ActiveStates[target] = StateHandler.ActiveStates[target] or {}

	-- Apply the state normally.
	StateHandler.ActiveStates[target][stateName] = {
		value = value,
		expiration = duration and (os.time() + duration) or nil,
	}

	-- Schedule state removal if duration is provided.
	if duration then
		task.delay(duration, function()
			StateHandler.removeState(target, stateName)
		end)
	end

	print("[StateHandler] Applied state:", stateName, "to", target.Name, "with value:", value, "Duration:", duration or "Permanent")
end

-- Function to check if a target has a state.
function StateHandler.hasState(target, stateName)
	if not target or not stateName then return false end
	return StateHandler.ActiveStates[target] and StateHandler.ActiveStates[target][stateName] ~= nil
end

-- Function to get the value of a state.
function StateHandler.getStateValue(target, stateName)
	if not target or not stateName then return nil end

	-- For shield-related state, delegate to CustomHealthSystem.
	if stateName == "ShieldHealth" then
		local player = Players:GetPlayerFromCharacter(target.Parent)
		if player then
			local healthInstance = CustomHealthSystem.GetInstance(player)
			if healthInstance then
				return healthInstance.ShieldHealth
			end
		end
		return 0
	end

	if StateHandler.ActiveStates[target] and StateHandler.ActiveStates[target][stateName] then
		return StateHandler.ActiveStates[target][stateName].value
	end
	return nil
end

-- Function to remove a state.
function StateHandler.removeState(target, stateName)
	if not target or not stateName then return end

	-- For shield-related state, delegate to CustomHealthSystem.
	if stateName == "ShieldHealth" then
		local player = Players:GetPlayerFromCharacter(target.Parent)
		if player then
			local healthInstance = CustomHealthSystem.GetInstance(player)
			if healthInstance then
				healthInstance.ShieldHealth = 0
				print("[StateHandler] Removed ShieldHealth state from", target.Name)
			end
		end
		return
	end

	if StateHandler.ActiveStates[target] then
		StateHandler.ActiveStates[target][stateName] = nil
		print("[StateHandler] Removed state:", stateName, "from", target.Name)
	end
end

-- Function to clear all states from a target.
function StateHandler.clearStates(target)
	if not target then return end
	if StateHandler.ActiveStates[target] then
		StateHandler.ActiveStates[target] = nil
		print("[StateHandler] Cleared all states for", target.Name)
	end
end

return StateHandler