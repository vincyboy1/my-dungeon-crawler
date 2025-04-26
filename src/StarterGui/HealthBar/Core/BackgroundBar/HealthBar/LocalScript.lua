-- Updated Health GUI script (LocalScript)
local bar = script.Parent -- HealthBar (base health)
local shieldBar = script.Parent.Parent:FindFirstChild("ShieldBar") -- Shield overlay
local hexShieldBar = script.Parent.Parent:FindFirstChild("HexShieldBar") -- New HexShield overlay
local text = script.Parent.Parent.Parent.Health -- TextLabel for displaying health

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local healthUpdateEvent = Remotes:WaitForChild("HealthUpdate")

-- This script uses only the data sent from the server by your custom health system.
local lastStatus = nil

local function updateBars(data)
	if data then
		-- Store the data received from the server.
		lastStatus = {
			MaxHealth = tonumber(data.MaxHealth) or 1,  -- Avoid division by zero
			Health = tonumber(data.Health) or 0,
			ShieldHealth = tonumber(data.ShieldHealth) or 0,
			HexShield = tonumber(data.HexShield) or 0,
		}
	end

	-- If no valid data has been received, do nothing.
	if not lastStatus then
		return
	end

	local maxHealth = lastStatus.MaxHealth
	local currentHealth = lastStatus.Health
	local shield = lastStatus.ShieldHealth
	local hexShield = lastStatus.HexShield

	-- Calculate the fractions.
	local healthFraction = currentHealth / maxHealth
	local shieldFraction = shield / maxHealth
	local hexShieldFraction = hexShield / maxHealth

	-- Update the base health bar.
	bar:TweenSize(UDim2.new(healthFraction, 0, 1, 0), "InOut", "Linear", 0.1)

	-- Update the shield bar overlay.
	if shield > 0 then
		shieldBar.Visible = true
		shieldBar:TweenSize(UDim2.new(shieldFraction, 0, 1, 0), "InOut", "Linear", 0.1)
	else
		shieldBar.Visible = false
	end

	-- Update the HexShieldBar overlay.
	-- This bar visually extends the health bar by the hex shield's proportion.
	if hexShield > 0 then
		hexShieldBar.Visible = true
		local totalFraction = healthFraction + hexShieldFraction
		-- Clamp totalFraction to 1 so it does not exceed the container's width.
		if totalFraction > 1 then totalFraction = 1 end
		hexShieldBar:TweenSize(UDim2.new(totalFraction, 0, 1, 0), "InOut", "Linear", 0.1)
	else
		hexShieldBar.Visible = false
	end

	-- Update the displayed health text.
	text.Text = tostring(math.floor(currentHealth))
end

-- Listen for health updates from the server.
healthUpdateEvent.OnClientEvent:Connect(function(data)
	updateBars(data)
end)

-- Optionally, if you want to ensure the UI remains responsive, you may poll the lastStatus.
while true do
	updateBars(nil)
	task.wait(0.2)
end