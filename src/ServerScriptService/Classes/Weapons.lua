local weaponTypes = {
	Bow = "Arrow",
	Saber = "Sharp",
	Staff = "Magical",
	StaffS = "Magical",
	Fist = "Brawler",  -- Added for Striker's Fist weapon
	-- Add more weapons here
}

local event = game.ReplicatedStorage.Remotes:WaitForChild("Equip")

event.OnServerEvent:Connect(function(plr, tool)
	local character = plr.Character or plr.CharacterAdded:Wait()
	if not character then
		warn("[ERROR]: Character not found for player: " .. plr.Name)
		return
	end

	local targetArm
	if tool.Name == "Bow" then
		targetArm = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
	elseif tool.Name == "Saber" or tool.Name == "StaffS" or tool.Name == "Staff" or tool.Name == "Fist" then
		targetArm = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	else
		warn("[ERROR]: No target arm specified for tool: " .. tool.Name)
		return
	end

	for attempt = 1, 3 do
		if targetArm then break end
		warn("[WARNING]: Attempt #" .. attempt .. " to find target arm for player: " .. plr.Name)
		task.wait(0.5)
		targetArm = character:FindFirstChild("RightHand") or character:FindFirstChild("LeftHand") or
			character:FindFirstChild("Right Arm") or character:FindFirstChild("Left Arm")
	end

	if not targetArm then
		warn("[ERROR]: Target arm not found for player: " .. plr.Name)
		return
	end

	local motor = tool:FindFirstChild("Motor6D")
	if not motor then
		warn("[ERROR]: Motor6D not found in the tool: " .. tool.Name)
		return
	end

	motor.Part0 = targetArm
	motor.Part1 = tool:FindFirstChild("BodyAttach") or tool:FindFirstChildWhichIsA("BasePart")
	motor.C0 = CFrame.new(0, -1.005, 0)
	motor.Parent = targetArm

	tool.Parent = character

	-- Assign weapon type to tool
	local weaponType = weaponTypes[tool.Name]
	if not weaponType then
		warn("[ERROR]: WeaponType not defined for tool: " .. tool.Name)
		return
	end

	tool:SetAttribute("WeaponType", weaponType)
	print(string.format("[Weapons] Assigned WeaponType '%s' to tool '%s'", weaponType, tool.Name))
end)
