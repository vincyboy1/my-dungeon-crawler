local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_WALK_SPEED = 10
local DEFAULT_RUN_SPEED = 20

local defaultAnims = ReplicatedStorage:WaitForChild("DefaultAnimations")
local idleAnimObj = defaultAnims:WaitForChild("IdleAnim")
local walkAnimObj = defaultAnims:WaitForChild("WalkAnim")
local runAnimObj = defaultAnims:WaitForChild("RunAnim")

local function updateSpeed(humanoid, isSprinting, speedModifier)
	local baseSpeed = isSprinting and DEFAULT_RUN_SPEED or DEFAULT_WALK_SPEED
	local finalSpeedModifier = humanoid:GetAttribute("SpeedModifier") or 0
	humanoid.WalkSpeed = math.max(baseSpeed + finalSpeedModifier, 0)
end

local function setupSprinting(player)
	local function handleCharacter(character)
		local humanoid = character:WaitForChild("Humanoid")
		local currentSpeed = 0
		local isSprinting = false
		local speedModifier = 0
		local runTrack, walkTrack, idleTrack

		local function stopAllAnimations()
			if walkTrack and walkTrack.IsPlaying then walkTrack:Stop() end
			if runTrack and runTrack.IsPlaying then runTrack:Stop() end
			if idleTrack and idleTrack.IsPlaying then idleTrack:Stop() end
		end

		local function manageAnimations(speed)
			-- If a weapon is equipped, skip default animations.
			if character:GetAttribute("WeaponEquipped") then
				stopAllAnimations()
				updateSpeed(humanoid, isSprinting, speedModifier)
				return
			end

			if speed > 0 then
				if isSprinting then
					if not runTrack then
						runTrack = humanoid:LoadAnimation(runAnimObj)
						runTrack.Looped = true
					end
					if not runTrack.IsPlaying then
						stopAllAnimations()
						runTrack:Play()
					end
				else
					if not walkTrack then
						walkTrack = humanoid:LoadAnimation(walkAnimObj)
						walkTrack.Looped = true
					end
					if not walkTrack.IsPlaying then
						stopAllAnimations()
						walkTrack:Play()
					end
				end
			else
				if not idleTrack then
					idleTrack = humanoid:LoadAnimation(idleAnimObj)
					idleTrack.Looped = true
				end
				if not idleTrack.IsPlaying then
					stopAllAnimations()
					idleTrack:Play()
				end
			end

			updateSpeed(humanoid, isSprinting, speedModifier)
		end

		manageAnimations(0)

		humanoid.Running:Connect(function(speed)
			currentSpeed = speed
			manageAnimations(currentSpeed)
		end)

		humanoid:SetAttribute("SpeedModifier", 0)
		humanoid:GetAttributeChangedSignal("SpeedModifier"):Connect(function()
			speedModifier = humanoid:GetAttribute("SpeedModifier") or 0
			manageAnimations(currentSpeed)
		end)

		local sprintRemote = player:FindFirstChild("SprintToggle") or Instance.new("RemoteEvent", player)
		sprintRemote.Name = "SprintToggle"
		sprintRemote.OnServerEvent:Connect(function(_, sprintState)
			isSprinting = sprintState
			manageAnimations(currentSpeed)
		end)
	end

	if player.Character then
		handleCharacter(player.Character)
	end
	player.CharacterAdded:Connect(handleCharacter)
end

Players.PlayerAdded:Connect(function(player)
	local sprintRemote = player:FindFirstChild("SprintToggle") or Instance.new("RemoteEvent")
	sprintRemote.Name = "SprintToggle"
	sprintRemote.Parent = player
	setupSprinting(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	local sprintRemote = player:FindFirstChild("SprintToggle") or Instance.new("RemoteEvent")
	sprintRemote.Name = "SprintToggle"
	sprintRemote.Parent = player
	setupSprinting(player)
end