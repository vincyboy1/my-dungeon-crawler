-- src/StarterPlayer/StarterPlayerScripts/AbilityController.lua
-- Client‐side Knit Controller for binding input to abilities

local Players               = game:GetService("Players")
local ContextActionService  = game:GetService("ContextActionService")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Knit                  = require(ReplicatedStorage.Knit.Knit)

local AbilityController = Knit.CreateController { Name = "AbilityController" }

function AbilityController:KnitInit()
    self.AbilityService = Knit.GetService("AbilityService")
end

function AbilityController:KnitStart()
    local player = Players.LocalPlayer

    -- Bind M1 (left click) to basic attack
    ContextActionService:BindAction("BasicAttack", function(_, state)
        if state == Enum.UserInputState.Begin then
            local className = player.Character and player.Character.Name
            self.AbilityService:UseAbility(className, "Slash", nil)
              :andThen(function(success, reason)
                  if success then
                      print("Basic Attack used")
                  else
                      warn("BasicAttack failed:", reason)
                  end
              end)
        end
    end, true, Enum.UserInputType.MouseButton1)

    -- Bind Q to second ability (example)
    ContextActionService:BindAction("Ability2", function(_, state)
        if state == Enum.UserInputState.Begin then
            local className = player.Character and player.Character.Name
            -- abilityKey must match one in your definitions, e.g. "UnbreakableCharge"
            self.AbilityService:UseAbility(className, "UnbreakableCharge", nil)
              :andThen(function(success, reason)
                  if success then
                      print("Charge used")
                  else
                      warn("Charge failed:", reason)
                  end
              end)
        end
    end, false, Enum.KeyCode.Q)
end

return AbilityController