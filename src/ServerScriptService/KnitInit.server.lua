-- KnitInit.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Knit.Knit)
print("[KnitInit] Requiring all server modules…")

Knit.AddServices(ServerScriptService.Knit)

-- lowercase :catch
Knit.Start():catch(function(err)
    warn("[KnitInit] Knit failed to start on server:", err)
end)

print("[KnitInit] Knit start() called on server.")