local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local VestigeEvent = Remotes:WaitForChild("VestigeEvent")
local VestigeManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("VestigeManager"))
local PlayerStatsManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AttributeModules"):WaitForChild("StatsModule"))

-- Handle vestige selection from the client
VestigeEvent.OnServerEvent:Connect(function(player, vestigeName)
	VestigeManager.ApplyVestige(player, vestigeName)
end)

-- Function to wait until the player selects a class
local function waitForClassSelection(player)
	local timeout = 500 -- Max time to wait for class selection (prevents infinite loop)
	local elapsedTime = 0

	while elapsedTime < timeout do
		local stats = PlayerStatsManager.getStats(player)
		if stats and stats.Class then
			return stats.Class -- Class has been selected, return it
		end
		wait(1)
		elapsedTime += 1
	end

	warn("[VestigeEvent] Player", player.Name, "did not select a class in time.")
	return nil
end

-- Function to give players a choice of random vestiges at the start of a round
local function startRound(player)
	local class = waitForClassSelection(player)
	if not class then return end -- If class is still nil, do nothing

	local availableCategories = VestigeManager.ClassVestigeCategories[class]
	if not availableCategories then
		warn("[VestigeEvent] No vestige categories for class:", class)
		return
	end

	-- Select 3 random vestiges to offer the player
	local chosenVestiges = {}
	for i = 1, 3 do
		local randomCategory = availableCategories[math.random(#availableCategories)]
		local randomVestige = VestigeManager.GetRandomVestige(randomCategory)
		if randomVestige then
			table.insert(chosenVestiges, randomVestige.Name)
		end
	end

	-- Send choices to the client
	VestigeEvent:FireClient(player, chosenVestiges)
end

game.Players.PlayerAdded:Connect(function(player)
	task.spawn(startRound, player) -- Run asynchronously so it doesn't block other players
end)