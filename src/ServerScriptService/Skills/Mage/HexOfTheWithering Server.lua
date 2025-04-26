-- HexOfTheWithering_Server.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Services/Modules
local AbilityManager = require(ReplicatedStorage.Modules.CombatModules.AbilityManager)
local CustomHealthSystem = require(ReplicatedStorage.Modules.CombatModules.CustomHealthSystem)
local StateHandler = require(ReplicatedStorage.Modules.AttributeModules.StateHandler)
local DamageType = require(ReplicatedStorage.Modules.CombatModules.DamageType)
local HealingType = require(ReplicatedStorage.Modules.CombatModules.HealingType)
-- (Assuming you have a BuffManager or similar for VFX/debuff visuals.)

-- Remote event for hex casting and health updates
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CastHexEvent = Remotes:FindFirstChild("CastHexOfTheWithering")
local healthUpdateEvent = Remotes:WaitForChild("HealthUpdate")

-- Table to store active hex data: key = caster.UserId, value = {targetHumanoid, costPercent, effectBonus, createdRoot}
local activeHexes = {}

local HEX_DURATION = 9

-- Table to throttle hex shield gain per caster.
local hexShieldCooldown = 0.8
local hexShieldTimestamps = {}

-- Function to remove hex effects from target
local function removeHexEffects(caster, target)
	if target and target:IsA("Model") then
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:SetAttribute("HexDamageReduction", nil)
			humanoid:SetAttribute("HexMagicVulnerability", nil)
			humanoid:SetAttribute("HexCaster", nil)
		end
	end
end

-- Helper to broadcast health status to the caster's client.
local function broadcastHealthUpdate(caster)
	local healthInstance = CustomHealthSystem.GetInstance(caster)
	if healthInstance then
		healthUpdateEvent:FireClient(caster, healthInstance:GetStatus())
	end
end

-- Function to handle damage broadcasting for hex shield accumulation
local function onDamageDealt(targetHumanoid, damageDealt, damageType, sourcePlayer)
	local hexData = activeHexes[sourcePlayer.UserId]
	if not hexData then return end
	if targetHumanoid ~= hexData.targetHumanoid then return end

	-- Throttle addition so that repeated hits within the cooldown period are ignored.
	local currentTime = tick()
	local lastTime = hexShieldTimestamps[sourcePlayer.UserId] or 0
	if currentTime - lastTime < hexShieldCooldown then
		return
	end
	hexShieldTimestamps[sourcePlayer.UserId] = currentTime

	local caster = sourcePlayer
	local healthInstance = CustomHealthSystem.GetInstance(caster)
	if healthInstance then
		-- Calculate hex shield gain as 0.4% of damage dealt.
		local hexAdded = damageDealt * 0.4
		-- Cap the gain to 5% of caster's max health per hit.
		local maxHealth = healthInstance.MaxHealth or 100
		local maxAddition = maxHealth * 0.05
		if hexAdded > maxAddition then
			hexAdded = maxAddition
		end

		healthInstance.HexShield = (healthInstance.HexShield or 0) + hexAdded
		print("[HexOfTheWithering] Added " .. hexAdded .. " to HexShield for " .. caster.Name .. " (damage: " .. damageDealt .. ", cap: " .. maxAddition .. ")")
		broadcastHealthUpdate(caster)
	end
end

-- Connect to DamageBroadcast event to monitor damage dealt.
local damageConn = DamageType.DamageBroadcast.Event:Connect(onDamageDealt)

-- Function to attach caster arm effects
local function attachArmEffects(caster)
	local char = caster.Character
	if not char then
		print("[HexOfTheWithering] attachArmEffects: Caster has no character.")
		return 
	end
	local leftArm = char:FindFirstChild("Left Arm")
	if not leftArm then
		print("[HexOfTheWithering] attachArmEffects: No LeftArm found.")
		return 
	end
	local leftGrip = leftArm:FindFirstChild("LeftGripAttachment")
	if not leftGrip then
		print("[HexOfTheWithering] attachArmEffects: No LeftGripAttachment found.")
		return 
	end

	local armEffectsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if armEffectsFolder then
		armEffectsFolder = armEffectsFolder:FindFirstChild("MageAbilities")
		if armEffectsFolder then
			armEffectsFolder = armEffectsFolder:FindFirstChild("HexOfWithering")
			if armEffectsFolder then
				local armEffects = armEffectsFolder:FindFirstChild("ArmEffects")
				if armEffects then
					print("[HexOfTheWithering] attachArmEffects: Found ArmEffects with " .. #armEffects:GetChildren() .. " effect(s).")
					for _, effect in ipairs(armEffects:GetChildren()) do
						local cloned = effect:Clone()
						cloned.Parent = leftGrip
						print("[HexOfTheWithering] attachArmEffects: Cloned effect '" .. effect.Name .. "' to LeftGripAttachment.")
					end
				else
					print("[HexOfTheWithering] attachArmEffects: ArmEffects not found in HexOfWithering folder.")
				end
			else
				print("[HexOfTheWithering] attachArmEffects: HexOfWithering folder not found under MageAbilities.")
			end
		else
			print("[HexOfTheWithering] attachArmEffects: MageAbilities folder not found under Assets.")
		end
	else
		print("[HexOfTheWithering] attachArmEffects: Assets folder not found in ReplicatedStorage.")
	end
end

-- Function to attach target torso effects
local function attachTorsoEffects(target)
	local hrp = target:FindFirstChild("HumanoidRootPart")
	if not hrp then
		print("[HexOfTheWithering] attachTorsoEffects: Target does not have a HumanoidRootPart.")
		return 
	end
	-- Look for existing RootAttachment; if none, create one.
	local rootAttachment = hrp:FindFirstChild("RootAttachment")
	local createdAttachment = false
	if not rootAttachment then
		rootAttachment = Instance.new("Attachment")
		rootAttachment.Name = "RootAttachment"
		rootAttachment.Parent = hrp
		createdAttachment = true
		print("[HexOfTheWithering] attachTorsoEffects: Created new RootAttachment on target's HumanoidRootPart.")
	end

	local torsoEffectsFolder = ReplicatedStorage:FindFirstChild("Assets")
	if torsoEffectsFolder then
		torsoEffectsFolder = torsoEffectsFolder:FindFirstChild("MageAbilities")
		if torsoEffectsFolder then
			torsoEffectsFolder = torsoEffectsFolder:FindFirstChild("HexOfWithering")
			if torsoEffectsFolder then
				local torsoEffects = torsoEffectsFolder:FindFirstChild("TorsoEffects")
				if torsoEffects then
					print("[HexOfTheWithering] attachTorsoEffects: Found TorsoEffects with " .. #torsoEffects:GetChildren() .. " effect(s).")
					for _, effect in ipairs(torsoEffects:GetChildren()) do
						local cloned = effect:Clone()
						cloned.Parent = rootAttachment
						print("[HexOfTheWithering] attachTorsoEffects: Cloned effect '" .. effect.Name .. "' to RootAttachment.")
					end
				else
					print("[HexOfTheWithering] attachTorsoEffects: TorsoEffects folder not found in HexOfWithering folder.")
				end
			else
				print("[HexOfTheWithering] attachTorsoEffects: HexOfWithering folder not found under MageAbilities.")
			end
		else
			print("[HexOfTheWithering] attachTorsoEffects: MageAbilities folder not found under Assets.")
		end
	else
		print("[HexOfTheWithering] attachTorsoEffects: Assets folder not found in ReplicatedStorage.")
	end

	return createdAttachment, rootAttachment
end

-- Function to play the caster's animation (non-looping)
local function playCasterAnimation(caster)
	local char = caster.Character
	if not char then
		print("[HexOfTheWithering] playCasterAnimation: No character found for caster.")
		return 
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://99966409957724"
		local animTrack = humanoid:LoadAnimation(anim)
		animTrack.Looped = false  -- Ensure the animation does not loop
		animTrack:Play()
		print("[HexOfTheWithering] playCasterAnimation: Playing animation 99966409957724.")
	else
		print("[HexOfTheWithering] playCasterAnimation: No humanoid found on caster's character.")
	end
end

-- Function to cast Hex of the Withering using the new math, VFX and animation.
local function castHex(caster, target)
	if not caster or not target then return end
	local char = caster.Character
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not char or not targetHumanoid then
		warn("[HexOfTheWithering] Invalid caster or target")
		return
	end

	-- Validate casting through centralized function.
	if not AbilityManager.CanCast(caster, "HexOfTheWithering") then
		return
	end

	local healthInstance = CustomHealthSystem.GetInstance(caster)
	if not healthInstance then return end

	-- Play caster animation and attach arm effects.
	playCasterAnimation(caster)
	attachArmEffects(caster)

	-- After 1 second, attach torso effects to target.
	delay(1, function()
		local createdAttachment, rootAttachment = attachTorsoEffects(target)
		if not rootAttachment then
			print("[HexOfTheWithering] Failed to attach torso effects: no RootAttachment available.")
		end
	end)

	-- Calculate current health percentage.
	local currentHealth = healthInstance.Health
	local maxHealth = healthInstance.MaxHealth
	local currentHPPercent = (currentHealth / maxHealth) * 100

	-- Disallow if current health is 10% or less.
	if currentHPPercent <= 10 then
		warn("[HexOfTheWithering] Not enough health to cast the skill.")
		return
	end

	-- Calculate cost percentage based on current health:
	-- At 100% HP, cost = 45% of max health.
	-- For every 10% less HP, reduce cost by 5%.
	local costPercent = 45 - 0.5 * (100 - currentHPPercent)
	-- Calculate bonus effect as 2% per 10% HP consumed.
	local effectBonus = (costPercent / 10) * 2

	local sacrificeAmount = math.floor(maxHealth * (costPercent / 100))
	print("[HexOfTheWithering] " .. caster.Name .. " sacrifices " .. sacrificeAmount .. " HP (" .. costPercent .. "% of max)")

	-- Sacrifice HP from the caster (self-damage)
	healthInstance:TakeDamage(sacrificeAmount)
	broadcastHealthUpdate(caster)

	-- Apply hex debuff on target:
	-- The target will deal effectBonus% less damage to the caster,
	-- and take effectBonus% more magic damage from the caster.
	targetHumanoid:SetAttribute("HexDamageReduction", effectBonus)
	targetHumanoid:SetAttribute("HexMagicVulnerability", effectBonus)
	targetHumanoid:SetAttribute("HexCaster", caster.UserId)

	-- Store hex data for this caster.
	activeHexes[caster.UserId] = {
		targetHumanoid = targetHumanoid,
		costPercent = costPercent,
		effectBonus = effectBonus,
		createdRoot = nil,  -- We track creation in attachTorsoEffects separately if needed.
	}

	-- Start the hex effect timer.
	delay(HEX_DURATION, function()
		-- On hex end, convert remaining HexShield into healing.
		local healthInst = CustomHealthSystem.GetInstance(caster)
		if healthInst then
			local shieldValue = healthInst.HexShield or 0
			if shieldValue > 0 then
				print("[HexOfTheWithering] Converting " .. shieldValue .. " HexShield to healing for " .. caster.Name)
				healthInst.HexShield = 0
				healthInst:Heal(shieldValue)
				broadcastHealthUpdate(caster)
			end
		end

		-- Remove hex debuff from target.
		removeHexEffects(caster, target)
		activeHexes[caster.UserId] = nil

		-- Clean up arm effects.
		local casterChar = caster.Character
		if casterChar then
			local leftArm = casterChar:FindFirstChild("Left Arm")
			if leftArm then
				local leftGrip = leftArm:FindFirstChild("LeftGripAttachment")
				if leftGrip then
					for _, effect in ipairs(leftGrip:GetChildren()) do
						effect:Destroy()
						print("[HexOfTheWithering] Removed arm effect: " .. effect.Name)
					end
				else
					print("[HexOfTheWithering] No LeftGripAttachment found for arm cleanup.")
				end
			end
		end

		-- Clean up torso effects.
		local targetHRP = target:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			local rootAtt = targetHRP:FindFirstChild("RootAttachment")
			if rootAtt then
				for _, effect in ipairs(rootAtt:GetChildren()) do
					effect:Destroy()
					print("[HexOfTheWithering] Cleaned up torso effect: " .. effect.Name)
				end
				-- Optionally, if you created the RootAttachment, you can destroy it.
			end
		end

		-- Start the cooldown for HexOfTheWithering after the effect ends.
		local moveData = AbilityManager.moveDamages["HexOfTheWithering"]
		local cooldownTime = moveData and moveData.baseCooldown or 40
		AbilityManager.startCooldown(caster, "HexOfTheWithering", cooldownTime)
	end)

	print("[HexOfTheWithering] " .. caster.Name .. " cast Hex on " .. target.Name .. " for " .. HEX_DURATION .. " seconds with bonus effect: " .. effectBonus .. "%.")
end

-- Listen for the remote event from the client.
CastHexEvent.OnServerEvent:Connect(function(player, target)
	castHex(player, target)
end)