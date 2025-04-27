-- KnitInit.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Knit)
print("[KnitInit] Requiring all client controllers…")

-- Point Knit at your client-side Knit folder (controllers live under StarterPlayerScripts/Knit)
-- If you put controllers directly in StarterPlayerScripts, Knit will find them automatically:
Knit.AddControllers(script.Parent)

-- Start Knit!
Knit.Start():Catch(function(err)
    warn("[KnitInit] Knit failed to start on client:", err)
end)

print("[KnitInit] Knit started on client.")
