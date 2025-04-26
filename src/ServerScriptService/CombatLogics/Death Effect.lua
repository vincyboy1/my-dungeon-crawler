local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local deathEffectFolder = ReplicatedStorage:WaitForChild("Assets"):FindFirstChild("DeathEffect") -- Folder with particle emitters

-- Function to trigger the disintegration effect
local function disintegrateCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Anchor all body parts
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end

	-- Add particle emitters directly to each body part
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			-- Clone and attach particle emitters directly
			for _, emitterTemplate in ipairs(deathEffectFolder:GetChildren()) do
				if emitterTemplate:IsA("ParticleEmitter") then
					local emitter = emitterTemplate:Clone()
					emitter.Parent = part
					local emitCount = emitter:GetAttribute("EmitCount") or 20
					local lifetime = emitter.Lifetime.Max or 1

					-- Emit particles
					emitter.Enabled = true
					emitter:Emit(emitCount)

					-- Disable emitter after lifetime
					task.delay(lifetime, function()
						emitter.Enabled = false
						emitter:Destroy() -- Cleanup emitter
					end)
				end
			end
		end
	end

	-- Gradually fade out the transparency of body parts
	local fadeTime = 0.5 -- Duration to match particle emit lifetime
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			local tween = TweenService:Create(part, TweenInfo.new(fadeTime), { Transparency = 1 })
			tween:Play()
		end
	end

	-- Cleanup after the effect is done
	task.delay(fadeTime, function()
		-- Unanchor the body parts (optional)
		for _, part in ipairs(character:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end)
end

-- Listen for player deaths
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			disintegrateCharacter(character)
		end)
	end)
end)