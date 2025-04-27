-- KnitInit.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Knit)
print("[KnitInit] Requiring all server modules…")

-- Point Knit at your ServerScriptService/Knit folder
Knit.AddServices(ServerScriptService.Knit)

-- Start Knit!
Knit.Start():Catch(function(err)
    warn("[KnitInit] Knit failed to start:", err)
end)

print("[KnitInit] Knit started on server.")