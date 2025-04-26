local uis = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("Remotes")

local bulwarkSlamEvent = remotes:WaitForChild("BulwarkSlam")
local castingUpdateEvent = remotes:WaitForChild("CastingUpdate") -- Event to receive casting state updates
local cooldownEvent = remotes:WaitForChild("StartCooldown") -- Event to notify cooldowns

local isCasting = false -- Tracks whether the player is casting
local cooldowns = {} -- Tracks active cooldowns

-- Input handling
uis.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R then
		if isCasting then
			warn("You are currently casting another ability!")
			return
		end

		if cooldowns["BulwarkSlam"] then
			warn("Bulwark Slam is on cooldown!")
			return
		end

		bulwarkSlamEvent:FireServer()
	end
end)

-- Listen for cooldown updates from the server
cooldownEvent.OnClientEvent:Connect(function(skillName, duration)
	if skillName == "BulwarkSlam" then
		-- Set the local cooldown
		cooldowns[skillName] = true
		task.delay(duration, function()
			cooldowns[skillName] = nil -- Reset cooldown after duration
		end)
	end
end)

-- Listen for casting state updates from the server
castingUpdateEvent.OnClientEvent:Connect(function(state)
	isCasting = state -- Update the local casting state
end)