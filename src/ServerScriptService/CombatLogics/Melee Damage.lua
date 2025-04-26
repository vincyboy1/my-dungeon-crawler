-- MeleeAttacks.txt
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatModules")
local AbilityManager = require(CombatModules:WaitForChild("AbilityManager"))
local PartyManager = require(CombatModules:WaitForChild("PartyManager"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local SpatialQueryHitbox = require(ReplicatedStorage.Modules.CombatModules.SpatialQueryHitbox)

local MeleeAttackEvent = remotes:WaitForChild("MeleeAttackEvent")

local hitSoundPools = {
	Warrior = {
		[1] = {"rbxassetid://123116931034309"},
		[2] = {"rbxassetid://123116931034309"},
		[3] = {"rbxassetid://123116931034309"},
		[4] = {"rbxassetid://123116931034309"},
		[5] = {"rbxassetid://123116931034309"},
	},
	Mage = {
		[1] = {"rbxassetid://MageMeleeHit1"},
		[2] = {"rbxassetid://MageMeleeHit2"},
		[3] = {"rbxassetid://MageMeleeHit3"},
	},
	Striker = {
		[1] = {"rbxassetid://StrikerMeleeHit1"},
		[2] = {"rbxassetid://StrikerMeleeHit2"},
		[3] = {"rbxassetid://StrikerMeleeHit3"},
		[4] = {"rbxassetid://StrikerMeleeHit4"},
	},
	Ranger = {
		[1] = {"rbxassetid://RangerMeleeHit1"},
		[2] = {"rbxassetid://RangerMeleeHit2"},
	},
	Support = {
		[1] = {"rbxassetid://SupportMeleeHit1"},
		[2] = {"rbxassetid://SupportMeleeHit2"},
		[3] = {"rbxassetid://SupportMeleeHit3"},
		[4] = {"rbxassetid://SupportMeleeHit4"},
		[5] = {"rbxassetid://SupportMeleeHit5"},
	},
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

local function TriggerHitFeedback(player, hitPart, className, combo)
	local pool = hitSoundPools[className] and hitSoundPools[className][combo]
	if pool then
		local soundId = GetRandomSoundFromPool(pool)
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
				game:GetService("Debris"):AddItem(sound, sound.TimeLength + 0.5)
			end
		end
	end
	local hitFeedbackEvent = remotes:WaitForChild("HitFeedbackEvent")
	if hitFeedbackEvent then
		hitFeedbackEvent:FireClient(player, 0.2, 0.1)
	end
end

MeleeAttackEvent.OnServerEvent:Connect(function(player, comboCount, className, animDuration)
	local character = player.Character
	if not character then return end

	local globalHitList = {}
	local hitboxParts = {}
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "Hitbox" then
			table.insert(hitboxParts, part)
		end
	end

	if #hitboxParts == 0 then
		warn("MeleeAttackEvent: No hitbox parts found for player " .. player.Name)
		return
	end

	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	local hitParticlesFolder = nil
	if assetsFolder then
		local hitsFolder = assetsFolder:FindFirstChild("Hits")
		if hitsFolder then
			hitParticlesFolder = hitsFolder:FindFirstChild(className) or hitsFolder:FindFirstChild("Default")
		end
	end

	for _, hitboxPart in ipairs(hitboxParts) do
		local hitbox = SpatialQueryHitbox.new(hitboxPart)
		hitbox:Start(animDuration)
		hitbox.OnHit:Connect(function(hitPart, hitHumanoid, model)
			if model and model == character then return end
			local targetId = model and model:GetFullName() or hitPart:GetFullName()
			if globalHitList[targetId] then return end
			globalHitList[targetId] = true

			local targetPlayer = game.Players:GetPlayerFromCharacter(model)
			if targetPlayer and PartyManager.isPlayerAlly(player, targetPlayer) then return end

			AbilityManager.applyMoveDamage(hitHumanoid, "BasicMeleeAttack" .. className, player, "Physical")
			TriggerHitFeedback(player, hitPart, className, comboCount)

			if hitParticlesFolder then
				for _, particle in ipairs(hitParticlesFolder:GetChildren()) do
					local particleClone = particle:Clone()
					local torso = model and (model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart"))
					if torso then
						particleClone.Parent = torso
						game:GetService("Debris"):AddItem(particleClone, 2)
					end
				end
			end
		end)
		task.delay(animDuration, function()
			if hitbox and type(hitbox.Destroy) == "function" then
				hitbox:Destroy(false)
			end
		end)
	end
end)