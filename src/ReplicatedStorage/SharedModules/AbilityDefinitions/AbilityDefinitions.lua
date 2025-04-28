-- src/ReplicatedStorage/SharedModules/AbilityDefinitions/AbilityDefinitions.lua
-- maps each archetype folder’s Base.lua

return {
    Warrior = require(script.Parent.Warrior.Base),
    Ranger  = require(script.Parent.Ranger.Base),
    Mage    = require(script.Parent.Mage.Base),
    Support = require(script.Parent.Support.Base),
    Striker = require(script.Parent.Striker.Base),
}