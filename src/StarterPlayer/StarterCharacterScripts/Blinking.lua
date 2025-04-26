local character = script.Parent

local eyesOpen = character:FindFirstChild("Eyes Open")
local eyesBlink = character:FindFirstChild("Eyes Blink")
local eyesHappy = character:FindFirstChild("Eyes Happy")
local eyesMeme = character:FindFirstChild("Eyes Meme")

if not (eyesOpen and eyesBlink and eyesHappy and eyesMeme) then
	warn("Missing one or more eye accessories in StarterCharacter!")
	return
end

local blinkInterval = 5 -- Interval in seconds between blinks
local blinkDuration = 0.1 -- Duration of the blink in seconds
local isExpressing = false -- Track if the player is performing an emote

-- Function to toggle between eyes
local function setEyeState(openVisible, blinkVisible, happyVisible, memeVisible)
	if eyesOpen:FindFirstChild("Handle") then
		eyesOpen.Handle.Transparency = openVisible and 0 or 1
	end
	if eyesBlink:FindFirstChild("Handle") then
		eyesBlink.Handle.Transparency = blinkVisible and 0 or 1
	end
	if eyesHappy:FindFirstChild("Handle") then
		eyesHappy.Handle.Transparency = happyVisible and 0 or 1
	end
	if eyesMeme:FindFirstChild("Handle") then
		eyesMeme.Handle.Transparency = memeVisible and 0 or 1
	end
end

-- Function to blink
local function blink()
	if isExpressing then return end -- Skip blinking during emotes
	setEyeState(false, true, false, false) -- Blink
	task.wait(blinkDuration)
	setEyeState(true, false, false, false) -- Open eyes
end

-- Monitor animations for emotes
local humanoid = character:FindFirstChild("Humanoid")
if not humanoid then
	warn("Missing Humanoid in character!")
	return
end

humanoid.AnimationPlayed:Connect(function(animationTrack)
	local cheerId = "http://www.roblox.com/asset/?id=129423030"
	local waveId = "http://www.roblox.com/asset/?id=128777973"
	local dance2Ids = {
		"http://www.roblox.com/asset/?id=182436842",
		"http://www.roblox.com/asset/?id=182491248",
		"http://www.roblox.com/asset/?id=182491277",
	}

	if animationTrack.Animation then
		local animationId = animationTrack.Animation.AnimationId
		if animationId == cheerId or animationId == waveId then
			isExpressing = true
			setEyeState(false, false, true, false) -- Show happy eyes during Cheer or Wave emote

			-- Listen for animation end
			animationTrack.Stopped:Wait()
			isExpressing = false
			setEyeState(true, false, false, false) -- Restore to open eyes
		elseif table.find(dance2Ids, animationId) then
			isExpressing = true
			setEyeState(false, false, false, true) -- Show meme eyes during Dance2 emote

			-- Listen for animation end
			animationTrack.Stopped:Wait()
			isExpressing = false
			setEyeState(true, false, false, false) -- Restore to open eyes
		end
	end
end)

-- Blink periodically
while task.wait(blinkInterval) do
	blink()
end