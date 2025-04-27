-- src/ServerScriptService/KnitInit.server.lua

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- 1) Load Knit itself
local Knit = require(ReplicatedStorage.Knit.Knit)
print("[KnitInit] Knit loaded")

-- 2) Manually require each service ModuleScript BEFORE starting
--    This guarantees each service calls Knit.CreateService() now.
local servicesFolder = ServerScriptService:WaitForChild("Knit")
for _, moduleScript in ipairs(servicesFolder:GetChildren()) do
    if moduleScript:IsA("ModuleScript") then
        require(moduleScript)
        print("[KnitInit]  → Registered service:", moduleScript.Name)
    end
end

-- 3) Finally, start Knit
Knit.Start():catch(function(err)
    warn("[KnitInit] Knit failed to start:", err)
end)
print("[KnitInit] Knit.Start() called on server")
