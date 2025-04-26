local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local VestigeEvent = Remotes:WaitForChild("VestigeEvent")

local Player = Players.LocalPlayer
local screenGui = script.Parent
local vestigeFrame = screenGui:WaitForChild("MainFrame")

-- Ensure the vestige display frame is hidden by default
vestigeFrame.Visible = false

local function notifyServer(vestigeName)
	VestigeEvent:FireServer(vestigeName)
end

local function fetchClassVestigeCategories()
	local className = Player:GetAttribute("Class")
	if not className then
		warn("Player class not set!")
		return {}
	end

	-- Fetch vestige categories for the player's class from VestigeManager
	local VestigeManager = require(ReplicatedStorage.Modules:WaitForChild("VestigeManager"))
	local classVestigeCategories = VestigeManager.ClassVestigeCategories[className] or {}
	return classVestigeCategories
end

local function retryClassCheck()
	-- Retry logic for checking class
	task.wait(5) -- Wait for 5 seconds
	displayRandomVestiges() -- Retry after waiting
end

local function displayRandomVestiges()
	-- Ensure the player has selected a class
	local className = Player:GetAttribute("Class")
	if not className then
		warn("Player has not selected a class. Retrying in 5 seconds.")
		task.defer(retryClassCheck) -- Retry using deferred call
		return
	end

	-- Clear the existing UI elements in the frame
	for _, child in ipairs(vestigeFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	-- Fetch the vestige categories for the player's class
	local classVestigeCategories = fetchClassVestigeCategories()
	if #classVestigeCategories == 0 then
		warn("No vestige categories available for the player's class!")
		return
	end

	local vestigeFolder = ReplicatedStorage:FindFirstChild("Vestiges")
	if not vestigeFolder then
		warn("Vestiges folder not found in ReplicatedStorage!")
		return
	end

	-- Gather eligible vestiges by category and factor in rarity
	local eligibleVestiges = {}
	for _, categoryName in ipairs(classVestigeCategories) do
		local categoryFolder = vestigeFolder:FindFirstChild(categoryName)
		if categoryFolder and categoryFolder:IsA("Folder") then
			for _, vestige in ipairs(categoryFolder:GetChildren()) do
				local rarity = vestige:GetAttribute("Rarity") or 1
				for _ = 1, rarity do
					table.insert(eligibleVestiges, vestige)
				end
			end
		end
	end

	if #eligibleVestiges < 3 then
		warn("Not enough eligible vestiges to display!")
		return
	end

	-- Select 3 random vestiges
	local selectedVestiges = {}
	while #selectedVestiges < 3 do
		local randomVestige = eligibleVestiges[math.random(1, #eligibleVestiges)]
		if not table.find(selectedVestiges, randomVestige) then
			table.insert(selectedVestiges, randomVestige)
		end
	end

	-- Display the selected vestiges in the UI
	vestigeFrame.Visible = true
	for _, vestige in ipairs(selectedVestiges) do
		local clonedVestige = vestige:Clone()
		if clonedVestige:IsA("TextLabel") or clonedVestige:IsA("Frame") then
			clonedVestige.Visible = true
			clonedVestige.Parent = vestigeFrame

			local selectButton = clonedVestige:FindFirstChild("SelectButton")
			if selectButton then
				selectButton.MouseButton1Click:Connect(function()
					notifyServer(clonedVestige.Name)
					vestigeFrame.Visible = false
				end)
			end
		else
			warn("Unexpected vestige object type: " .. clonedVestige.ClassName)
		end
	end
end

-- Listen for when the player's class attribute is set
Player:GetAttributeChangedSignal("Class"):Connect(function()
	if Player:GetAttribute("Class") then
		displayRandomVestiges()
	end
end)

VestigeEvent.OnClientEvent:Connect(function()
	-- Trigger the display of vestiges only if the class is already set
	if Player:GetAttribute("Class") then
		displayRandomVestiges()
	else
		warn("Player has not selected a class yet. Waiting for selection.")
	end
end)
