local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local loadSkillsEvent = ReplicatedStorage.Remotes:WaitForChild("LoadClassSkills")

loadSkillsEvent.OnClientEvent:Connect(function(className)
	local skillsFolder = ReplicatedStorage:FindFirstChild("Skills")
	if skillsFolder then
		local classSkillsFolder = skillsFolder:FindFirstChild(className)
		if classSkillsFolder then
			local playerScripts = player:WaitForChild("PlayerScripts")
			for _, skillScript in ipairs(classSkillsFolder:GetChildren()) do
				if skillScript:IsA("LocalScript") then
					local clonedScript = skillScript:Clone()
					clonedScript.Parent = playerScripts
				end
			end
		else
			warn("No skills folder found for class: " .. className)
		end
	else
		warn("No Skills folder found in ReplicatedStorage")
	end
end)