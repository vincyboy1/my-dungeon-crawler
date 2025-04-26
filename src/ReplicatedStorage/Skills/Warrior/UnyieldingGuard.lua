local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("Remotes")

local tauntShieldEvent = remotes:WaitForChild("ActivateTauntShield")
local castingUpdateEvent = remotes:FindFirstChild("CastingUpdate") or Instance.new("RemoteEvent", remotes)
castingUpdateEvent.Name = "CastingUpdate" -- Synchronizes casting state with the server

-- Cooldown tracking
local isCasting = false -- Tracks whether the player is casting an ability

local cooldownEvent = remotes:WaitForChild("StartCooldown")

cooldownEvent.OnClientEvent:Connect(function(skillName, duration)
	if skillName == "TauntShield" then
		print("TauntShield is on cooldown for " .. duration .. " seconds.")
		-- Optionally update UI if needed
	end
end)

uis.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.T then
		-- Prevent casting if already active or on cooldown
		if isCasting then
			warn("Already casting another ability!")
			return
		end

		tauntShieldEvent:FireServer()
	end
end)

-- Listen for global casting state updates from the server
castingUpdateEvent.OnClientEvent:Connect(function(state)
	isCasting = state -- Synchronize casting state with the server
end)

-- Listen for cooldown updates (if using cooldown UI or feedback)
cooldownEvent.OnClientEvent:Connect(function(skillName, duration)
	if skillName == "TauntShield" then
		print("TauntShield is on cooldown for " .. duration .. " seconds.")
	end
end)
