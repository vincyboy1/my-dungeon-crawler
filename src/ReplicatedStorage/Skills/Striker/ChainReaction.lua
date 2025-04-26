local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local CombatModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatModules")
local AnimationManager = require(CombatModules:WaitForChild("AnimationManager"))
local SoundManager = require(CombatModules:WaitForChild("SoundManager"))

local castingUpdateEvent = remotes:WaitForChild("CastingUpdate")
local chainReactionEvent = remotes:WaitForChild("ChainReaction")
local cooldownEvent = remotes:WaitForChild("StartCooldown")

local isCasting = false
local chainStage = 0  -- 0 means no chain active; 1 means attack1 done; 2 means attack2 done.
local isChargingLocal = false
local chargeStartTime = 0

local function resetChain()
	chainStage = 0
	isChargingLocal = false
	chargeStartTime = 0
	print("Chain Reaction chain reset.")
end

local function startChainTimeout()
	-- Local UI timeout; server enforces the 30-second window.
	task.delay(30, function()
		if chainStage > 0 then
			resetChain()
		end
	end)
end

castingUpdateEvent.OnClientEvent:Connect(function(state)
	isCasting = state
	print("Casting state updated:", isCasting)
end)

cooldownEvent.OnClientEvent:Connect(function(moveName, cooldownTime)
	if moveName == "ChainReaction" then
		print("Chain Reaction is on cooldown for " .. cooldownTime .. " seconds.")
		resetChain()
	end
end)

-- Handle key input for charge phases.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		-- Delay 0.1 sec before starting charge (windup delay).
		task.delay(0.1, function()
			-- Determine which attack we are charging.
			if chainStage == 0 then
				chainReactionEvent:FireServer("start1")
			elseif chainStage == 1 then
				chainReactionEvent:FireServer("start2")
			elseif chainStage == 2 then
				chainReactionEvent:FireServer("start3")
			end
			isChargingLocal = true
			chargeStartTime = os.clock()
			print("Started charging Chain Reaction attack " .. (chainStage + 1))
		end)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		if isChargingLocal then
			local chargeTime = os.clock() - chargeStartTime
			if chargeTime > 2.0 then chargeTime = 2.0 end  -- Max charge is 2.0 sec.
			-- If held for 1.9 sec or more, cancel the attack.
			if chargeTime >= 1.9 then
				if chainStage == 0 then
					chainReactionEvent:FireServer("cancel1", chargeTime)
				elseif chainStage == 1 then
					chainReactionEvent:FireServer("cancel2", chargeTime)
				elseif chainStage == 2 then
					chainReactionEvent:FireServer("cancel3", chargeTime)
				end
				resetChain()
				print("Charge held too long (>=1.9 sec); attack canceled.")
			else
				-- Otherwise, release the charge normally.
				if chainStage == 0 then
					chainReactionEvent:FireServer("release1", chargeTime)
					chainStage = 1
					print("Released attack 1 with charge time: " .. chargeTime)
				elseif chainStage == 1 then
					chainReactionEvent:FireServer("release2", chargeTime)
					chainStage = 2
					print("Released attack 2 with charge time: " .. chargeTime)
				elseif chainStage == 2 then
					chainReactionEvent:FireServer("release3", chargeTime)
					chainStage = 0 -- Chain complete.
					print("Released attack 3 with charge time: " .. chargeTime)
				end
				startChainTimeout()
			end
			isChargingLocal = false
		end
	end
end)