-- KnitInit.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit.Knit)
print("[KnitInit] Requiring all client controllers…")

Knit.AddControllers(script.Parent)

-- lowercase :catch
Knit.Start():catch(function(err)
    warn("[KnitInit] Knit failed to start on client:", err)
end)

print("[KnitInit] Knit start() called on client.")