local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SetSubject = ReplicatedStorage:WaitForChild("SetSubject")

SetSubject.OnClientEvent:Connect(function(newHumanoid)
	workspace.CurrentCamera.CameraSubject = newHumanoid
end)