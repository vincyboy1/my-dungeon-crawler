local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatModules")

local AbilityManager = require(CombatModules:WaitForChild("AbilityManager"))
local PartyManager = require(CombatModules:WaitForChild("PartyManager"))
local CrowdControlHandler = require(CombatModules:WaitForChild("CrowdControlHandler"))

local rs = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local players = game:GetService("Players")
local assets = rs:WaitForChild("Assets")
local tauntShieldPart = assets:WaitForChild("Taunt/Shield")

-- Remote Events
local remotes = rs:WaitForChild("Remotes")
local tauntShieldEvent = remotes:FindFirstChild("ActivateTauntShield") or Instance.new("RemoteEvent", remotes)
tauntShieldEvent.Name = "ActivateTauntShield"

local castingUpdateEvent = remotes:FindFirstChild("CastingUpdate") or Instance.new("RemoteEvent", remotes)
castingUpdateEvent.Name = "CastingUpdate" -- Synchronizes casting state with the client

-- Animation Asset ID
local TAUNT_SHIELD_ANIMATION_ID = "rbxassetid://93925406910720"

-- Buff Data
local tauntRadius = 40 -- Radius in studs

local isCasting = {} -- Tracks whether a player is currently casting

local function tauntEnemies(player, radius)
	local character = player.Character
	if not character then 
		warn("[Taunt] Player character not found.")
		return 
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		warn("[Taunt] Player's HumanoidRootPart not found.")
		return 
	end

	-- Apply the taunt to all nearby enemy characters
	for _, descendant in pairs(workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant ~= character and descendant:FindFirstChild("Humanoid") then
			local otherHumanoid = descendant:FindFirstChild("Humanoid")
			local otherRoot = descendant:FindFirstChild("HumanoidRootPart")
			local targetPlayer = game.Players:GetPlayerFromCharacter(descendant)

			if otherHumanoid and otherRoot then
				local distance = (otherRoot.Position - humanoidRootPart.Position).Magnitude

				-- Check if within radius and not an ally
				if distance <= radius then
					local isAlly = targetPlayer and PartyManager.isPlayerAlly(player, targetPlayer)
					if not isAlly then
						print("[Taunt] Applying taunt to:", descendant.Name)
						-- Trigger the "Taunted" crowd control effect
						local success, err = pcall(function()
							CrowdControlHandler.applyCC("Taunted", character, 3, {
								TauntRadius = radius,
								SlowPercentage = 0.7
							})
						end)
						if not success then
							warn("[Taunt] Error applying taunt:", err)
						end
					end
				end
			end
		end
	end
end

local function activateTauntShield(player)
	local moveName = "UnyieldingGuard"
	local moveData = AbilityManager.moveDamages[moveName]

	-- Consolidated casting check (includes cooldown, mana, CC, downed state, etc.)
	if not AbilityManager.CanCast(player, moveName) then
		return
	end

	local char = player.Character
	if not char then
		warn("[UnyieldingGuard] No character found for player:", player.Name)
		return
	end

	local humanoid = char:FindFirstChild("Humanoid")
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not humanoidRootPart then
		return
	end

	-- Set casting state and notify client
	isCasting[player] = true
	castingUpdateEvent:FireClient(player, true)

	-- Anchor the caster
	humanoidRootPart.Anchored = true

	-- Play animation
	local animator = humanoid:FindFirstChild("Animator") or humanoid:WaitForChild("Animator")
	local animation = Instance.new("Animation")
	animation.AnimationId = TAUNT_SHIELD_ANIMATION_ID
	local animationTrack = animator:LoadAnimation(animation)
	animationTrack:Play()

	animationTrack.Stopped:Connect(function()
		isCasting[player] = nil
		castingUpdateEvent:FireClient(player, false)
		humanoidRootPart.Anchored = false

		-- Start cooldown after casting completes using move's cooldown values.
		local moveData = AbilityManager.moveDamages[moveName]
		local baseCooldown = moveData.baseCooldown or 0
		local minCooldown = moveData.minCooldown or baseCooldown
		local cooldown = (baseCooldown < minCooldown) and minCooldown or baseCooldown
		AbilityManager.startCooldown(player, moveName, cooldown)
		remotes.StartCooldown:FireClient(player, moveName, cooldown)
	end)

	-- Clone the Taunt/Shield VFX
	local shieldEffect = tauntShieldPart:Clone()
	shieldEffect.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -3, 0)
	shieldEffect.Parent = workspace

	-- Emit VFX
	task.delay(0.1, function()
		for _, emitter in pairs(shieldEffect:GetDescendants()) do
			if emitter:IsA("ParticleEmitter") then
				local emitCount = emitter:GetAttribute("EmitCount") or 10
				local emitDelay = emitter:GetAttribute("EmitDelay")
				if not emitDelay or emitDelay <= 0 then
					emitter:Emit(emitCount)
				else
					task.delay(emitDelay, function()
						emitter:Emit(emitCount)
					end)
				end
			end
		end
	end)

	-- Cleanup shield effect after 3 seconds
	debris:AddItem(shieldEffect, 3)

	-- Apply shield healing effect and taunt enemies
	AbilityManager.applyMoveHealing(humanoid, moveName, player)
	tauntEnemies(player, tauntRadius)
end

-- Listen for the activation event from the client
tauntShieldEvent.OnServerEvent:Connect(function(player)
	activateTauntShield(player)
end)