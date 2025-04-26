-- Ability GUI Manager
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Icons")
local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local classSelectionEvent = remotes:FindFirstChild("ClassSelectionEvent")
local abilityUsedEvent = remotes:FindFirstChild("AbilityUsed")

local AbilityManager = require(game.ReplicatedStorage.Modules.CombatModules.AbilityManager)

local function updateAbilityIcons(player)
	local abilitiesGui = player:WaitForChild("PlayerGui"):WaitForChild("Abilities")
	local mainFrame = abilitiesGui:WaitForChild("Main")

	-- Clear existing icons
	for _, frameName in ipairs({"Passive", "EAbility", "RAbility", "TAbility"}) do
		local frame = mainFrame:FindFirstChild(frameName)
		if frame then
			local abilityFrame = frame:FindFirstChild("AbilityBorder"):FindFirstChild("Ability")
			if abilityFrame then
				for _, child in ipairs(abilityFrame:GetChildren()) do
					child:Destroy()
				end
			end
		end
	end

	-- Retrieve the player's selected class
	local className = player:GetAttribute("Class")
	if not className then return end

	-- Loop through all available ability icons
	for _, icon in ipairs(Assets:GetChildren()) do
		if icon:IsA("ImageLabel") then
			local assignedClass = icon:GetAttribute("Class")
			local key = icon:GetAttribute("Key")

			-- Only add abilities that match the player's selected class
			if assignedClass == className and key and mainFrame:FindFirstChild(key .. "Ability") then
				local targetFrame = mainFrame:FindFirstChild(key .. "Ability")
				local border = targetFrame:FindFirstChild("AbilityBorder")
				if border then
					local abilityFrame = border:FindFirstChild("Ability")
					if abilityFrame then
						local newIcon = icon:Clone()
						newIcon.Size = UDim2.new(1, 0, 1, 0)
						newIcon.Position = UDim2.new(0, 0, 0, 0)
						newIcon.Name = "AbilityIcon"
						newIcon.Parent = abilityFrame

						-- Initialize cooldown frontground
						local frontground = targetFrame:FindFirstChild("Frontground")
						if frontground then
							local isOnCooldown = AbilityManager.isOnCooldown(player, icon.Name)
							frontground.Visible = isOnCooldown
							frontground.Size = isOnCooldown and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 1, 0)
						end
					end
				end
			end
		end
	end
end

-- Function to handle cooldown shrinking
local function handleCooldown(player, abilityName, cooldownTime)
	local abilitiesGui = player:WaitForChild("PlayerGui"):WaitForChild("Abilities")
	local mainFrame = abilitiesGui:WaitForChild("Main")

	for _, key in ipairs({"E", "R", "T"}) do
		local frame = mainFrame:FindFirstChild(key .. "Ability")
		if frame then
			local border = frame:FindFirstChild("AbilityBorder")
			local frontground = frame:FindFirstChild("Frontground")
			if border and frontground then
				local icon = border:FindFirstChild("Ability"):FindFirstChild("AbilityIcon")
				if icon and icon.Name == abilityName then
					frontground.Visible = true
					frontground.Size = UDim2.new(1, 0, 1, 0)

					local startTime = os.time()
					local endTime = startTime + cooldownTime

					while os.time() < endTime do
						local remainingTime = endTime - os.time()
						local progress = remainingTime / cooldownTime
						frontground.Size = UDim2.new(1, 0, progress, 0)
						task.wait(0.1)
					end

					frontground.Visible = false
					frontground.Size = UDim2.new(1, 0, 1, 0)
				end
			end
		end
	end
end

-- Update abilities immediately after class selection
classSelectionEvent.OnServerEvent:Connect(function(player, className)
	player:SetAttribute("Class", className) -- Store class selection
	updateAbilityIcons(player)
end)

-- Ensure abilities update when the player joins
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		updateAbilityIcons(player)
	end)
end)

-- Event to trigger cooldown
abilityUsedEvent.OnServerEvent:Connect(function(player, abilityName, cooldownTime)
	if not AbilityManager.isOnCooldown(player, abilityName) then
		AbilityManager.startCooldown(player, abilityName, cooldownTime)
		handleCooldown(player, abilityName, cooldownTime)
	end
end)
