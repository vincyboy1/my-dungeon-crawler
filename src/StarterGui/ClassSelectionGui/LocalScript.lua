local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local classSelectionEvent = remotes and remotes:FindFirstChild("ClassSelectionEvent")

local player = game.Players.LocalPlayer
local frame = script.Parent:WaitForChild("MainFrame")

-- Ensure the GUI is parented to PlayerGui so it appears regardless of character state.
if not player:FindFirstChild("PlayerGui") then
	warn("PlayerGui not found for " .. player.Name)
else
	script.Parent.Parent = player:WaitForChild("PlayerGui")
end

-- Function to handle class button clicks
local function selectClass(className)
	if not className then
		warn("Class name not provided.")
		return
	end

	if not classSelectionEvent then
		warn("ClassSelectionEvent not found in ReplicatedStorage.")
		return
	end

	classSelectionEvent:FireServer(className) -- Notify the server about the class choice

	-- Provide feedback to the player by hiding the GUI after selection.
	frame.Visible = false
end

-- Connect buttons to the function
local function setupButtons()
	local buttons = {
		Warrior = frame:FindFirstChild("WarriorButton"),
		Mage = frame:FindFirstChild("MageButton"),
		Ranger = frame:FindFirstChild("RangerButton"),
		Support = frame:FindFirstChild("SupportButton"),
		Striker = frame:FindFirstChild("StrikerButton"),  -- For Striker class
	}

	for className, button in pairs(buttons) do
		if button then
			button.MouseButton1Click:Connect(function()
				selectClass(className)
			end)
		else
			warn(className .. "Button not found in the GUI.")
		end
	end
end

setupButtons()