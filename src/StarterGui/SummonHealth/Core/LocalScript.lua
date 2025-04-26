local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local summonCreatedEvent = ReplicatedStorage:WaitForChild("SummonCreated")

local summonHealthGui = player:WaitForChild("PlayerGui"):WaitForChild("SummonHealth"):FindFirstChild("Core")
if not summonHealthGui then
	warn("[Debug] SummonHealth GUI is missing!")
	return
end

-- Ensure all GUI slots are hidden initially
for i = 1, 4 do
	local guiSlot = summonHealthGui:FindFirstChild("Health" .. i)
	if guiSlot then
		guiSlot.Visible = false
	else
		warn("[Debug] Missing GUI slot: Health" .. i)
	end
end

-- Function to reset a GUI slot
local function resetGuiSlot(guiSlot)
	guiSlot.Visible = false
	guiSlot:SetAttribute("BoundSummon", nil) -- Clear any binding
	local textLabel = guiSlot:FindFirstChild("Text")
	if textLabel then
		textLabel.Text = "" -- Reset text
	end
	local healthBar = guiSlot:FindFirstChild("HealthBar")
	if healthBar then
		healthBar.Size = UDim2.new(1, 0, 1, 0) -- Reset bar size to full
		healthBar.BackgroundColor3 = Color3.new(0, 1, 0) -- Reset color to green
	end
	print("[Debug] Reset GUI slot:", guiSlot.Name)
end

-- Function to continuously update the health bar
local function updateHealthBar(guiSlot, summon)
	local healthBar = guiSlot:FindFirstChild("HealthBar")
	if not healthBar then
		warn("[SummonHealth] Missing HealthBar in GUI slot!")
		return
	end

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not guiSlot.Visible then
			connection:Disconnect()
			print("[Debug] Stopped updating health bar for:", summon.Name)
			return
		end

		local currentHealth = summon:GetAttribute("Health") or 0
		local maxHealth = summon:GetAttribute("MaxHealth") or 40
		local healthRatio = math.clamp(currentHealth / maxHealth, 0, 1)

		print("[Debug] Constantly updating health bar for:", summon.Name, "Health Ratio:", healthRatio)

		-- Update bar size and color
		healthBar:TweenSize(
			UDim2.new(healthRatio, 0, 1, 0),
			"InOut",
			"Linear",
			0.1
		)
		healthBar.BackgroundColor3 = Color3.new(1 - healthRatio, healthRatio, 0)
	end)
end

-- Function to bind a summon to a free GUI slot
local function bindSummonToGui(summon)
	local availableGui

	-- Check for a free GUI slot
	for i = 1, 4 do
		local guiSlot = summonHealthGui:FindFirstChild("Health" .. i)
		if guiSlot and not guiSlot.Visible then
			availableGui = guiSlot
			break
		end
	end

	if not availableGui then
		warn("[SummonHealth] No available GUI slots for the summon!")
		return
	end

	print("[Debug] Binding summon:", summon.Name, "to", availableGui.Name)

	-- Make the slot visible and bind the summon
	availableGui.Visible = true
	availableGui:SetAttribute("BoundSummon", summon)

	local textLabel = availableGui:FindFirstChild("Text")
	if textLabel then
		textLabel.Text = summon.Name
		print("[Debug] Assigned summon name to GUI slot:", summon.Name)
	else
		warn("[SummonHealth] Missing TextLabel in GUI slot!")
	end

	-- Start updating the health bar
	updateHealthBar(availableGui, summon)

	-- Handle GUI reset when the summon is removed
	summon.AncestryChanged:Connect(function(_, parent)
		if not parent then
			resetGuiSlot(availableGui)
			print("[Debug] Reset GUI slot for removed summon:", summon.Name)
		end
	end)

	-- Reset GUI slot when Wisp health reaches 0
	summon:GetAttributeChangedSignal("Health"):Connect(function()
		if summon:GetAttribute("Health") <= 0 then
			resetGuiSlot(availableGui)
			print("[Debug] Reset GUI slot for dead summon:", summon.Name)
		end
	end)
end

-- Listen for summon creation
summonCreatedEvent.OnClientEvent:Connect(function(summon)
	print("[Debug] Received summon from server:", summon.Name)
	bindSummonToGui(summon)
end)