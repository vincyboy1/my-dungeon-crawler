local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return require(script.Parent.KnitServer)
else
	local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer and RunService:IsRunning() then
		KnitServer:Destroy()
	end

	return require(script.Parent.KnitClient)
end
