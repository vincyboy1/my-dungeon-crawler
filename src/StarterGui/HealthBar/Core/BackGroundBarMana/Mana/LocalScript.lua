local manaBar = script.Parent -- ManaBar
local manaText = script.Parent.Parent.Parent.Mana -- TextLabel for displaying mana
local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- RemoteEvent for receiving mana updates from the server
local manaUpdateEvent = ReplicatedStorage:WaitForChild("ManaUpdateEvent")

-- Function to update mana bar
local function updateMana(currentMana, maxMana)
	if not currentMana or not maxMana then return end

	-- Calculate mana ratio
	local manaRatio = math.clamp(currentMana / maxMana, 0, 1)

	-- Update mana bar size
	manaBar:TweenSize(
		UDim2.new(manaRatio, 0, 1, 0),
		Enum.EasingDirection.InOut,
		Enum.EasingStyle.Linear,
		0.1
	)

	-- Update mana text
	manaText.Text = string.format("%d / %d", math.floor(currentMana), maxMana)
end

-- Listen for mana updates from the server
manaUpdateEvent.OnClientEvent:Connect(updateMana)

-- Request initial mana data when GUI loads
manaUpdateEvent:FireServer()
