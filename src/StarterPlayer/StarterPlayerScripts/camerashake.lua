-- LocalCameraShake.lua (in StarterPlayerScripts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local hitFeedbackEvent = ReplicatedStorage.Remotes:WaitForChild("HitFeedbackEvent")

local function performCameraShake(shakeMagnitude, shakeTime)
	_G.CameraShakeActive = true
	_G.CameraShakeOffset = CFrame.new(
		math.random(-100,100)/500 * shakeMagnitude,
		math.random(-100,100)/500 * shakeMagnitude,
		0)
	print("Performing camera shake with magnitude:", shakeMagnitude, "and time:", shakeTime)

	task.delay(shakeTime, function()
		_G.CameraShakeActive = false
		_G.CameraShakeOffset = CFrame.new()
	end)
end

hitFeedbackEvent.OnClientEvent:Connect(function(shakeMagnitude, shakeTime)
	print("HitFeedbackEvent received with magnitude:", shakeMagnitude, "and time:", shakeTime)
	performCameraShake(shakeMagnitude, shakeTime)
end)
