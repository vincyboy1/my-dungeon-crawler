-- src/ServerScriptService/Knit/AbilityService.lua
-- Server‐side Knit Service for handling ability use and cooldowns

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit              = require(ReplicatedStorage.Knit.Knit)

-- load all class → ability tables
local AbilityDefs = require(ReplicatedStorage.SharedModules.AbilityDefinitions.AbilityDefinitions)

local AbilityService = Knit.CreateService {
    Name = "AbilityService",
    Client = {
        -- exposed to clients: returns (success: bool, reason: string?)
        UseAbility = function() end,
    },
}

function AbilityService:KnitInit()
    -- cooldown tracking: player → { abilityKey = nextAllowedTimestamp }
    self._cooldowns = {}
end

function AbilityService:KnitStart()
    -- cache other services if needed later
    self.DataService   = Knit.GetService("DataService")
    self.CombatService = Knit.GetService("CombatService")
end

-- Client calls: AbilityService.Client:UseAbility(player, className, abilityKey, target)
function AbilityService.Client:UseAbility(player, className, abilityKey, target)
    local service = self.Server
    local now     = tick()

    -- Lookup definitions
    local classDefs = AbilityDefs[className]
    if not classDefs then
        return false, "InvalidClass"
    end
    local ability = classDefs[abilityKey]
    if not ability then
        return false, "InvalidAbility"
    end

    -- Setup this player's cooldown table
    service._cooldowns[player] = service._cooldowns[player] or {}
    local nextAllowed = service._cooldowns[player][abilityKey] or 0

    if now < nextAllowed then
        return false, "Cooldown"
    end

    -- TODO: Check resource costs (mana, etc.) via DataService
    -- TODO: Validate range/target if needed

    -- Mark new cooldown
    service._cooldowns[player][abilityKey] = now + ability.Cooldown

    -- Execute the ability effect:
    -- e.g. service.CombatService:ApplyDamage(player, target, ability.Damage, ability.Type)

    -- (You can fire additional signals or events here)

    return true
end

return AbilityService