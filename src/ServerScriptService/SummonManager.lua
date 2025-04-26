local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local summonCreatedEvent = Instance.new("RemoteEvent")
summonCreatedEvent.Name = "SummonCreated"
summonCreatedEvent.Parent = ReplicatedStorage

-- Function to handle summon creation and notify the client
local function createSummon(player, summonName, maxHealth)
	-- Create the summon instance
	local summon = Instance.new("Model")
	summon.Name = summonName
	summon:SetAttribute("Health", maxHealth)
	summon:SetAttribute("MaxHealth", maxHealth)
	summon.Parent = workspace -- Add summon to workspace or another folder

	-- Notify the client
	summonCreatedEvent:FireClient(player, summon)

	return summon
end