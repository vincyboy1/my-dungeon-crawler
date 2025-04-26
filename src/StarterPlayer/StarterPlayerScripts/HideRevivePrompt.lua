
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function disableRevivePrompt(character)
	local hrp = character:WaitForChild("HumanoidRootPart")
	-- Check if a RevivePrompt already exists and disable it.
	local prompt = hrp:FindFirstChild("RevivePrompt")
	if prompt then
		prompt.Enabled = false
	end
	-- Listen for any new prompts added to the HRP and disable them if they are the RevivePrompt.
	hrp.ChildAdded:Connect(function(child)
		if child:IsA("ProximityPrompt") and child.Name == "RevivePrompt" then
			child.Enabled = false
		end
	end)
end

player.CharacterAdded:Connect(function(character)
	disableRevivePrompt(character)
end)

if player.Character then
	disableRevivePrompt(player.Character)
end
