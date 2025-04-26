-- PlayerAttributesSetup.lua
-- Place this script in ServerScriptService to initialize player attributes.
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("CurrentCharge", 0)
	player:SetAttribute("MaxCharge", 3)  -- Maximum allowed charge (in seconds)
end)