-- ServerScriptService/Classes/ClassFramework.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local CombatModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatModules")
local AttributeModules = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("AttributeModules")
local CustomHealthSystem = require(CombatModules:WaitForChild("CustomHealthSystem"))
local AbilityManager = require(CombatModules:WaitForChild("AbilityManager"))
local StatsModule = require(AttributeModules:WaitForChild("StatsModule"))

local ClassFramework = {}

-- Base stats and clothing for classes
ClassFramework.BaseStats = {
	Warrior = {
		Health = 200,
		MaxMana = 100,
		ManaRegen = 1,
		Physical = 5,
		DamageMultiplier = 1,
		CriticalChance = 0,
		CriticalDamage = 1.8,
		MovementSpeed = 100,
		PhysicalResistance = 0,
		MagicResistance = 0,
		PhysicalResistancePenetration = 0,
		MagicResistancePenetration = 0,
		HealthRegen = 0,
		Burn = 0,
		Poison = 0,
		Bleed = 0,
		Ice = 0,
		Lightning = 0,
		Healing = 0,
		LifestealPercentage = 0,
		Class = "Warrior",
		Weapon = "Sword",
	},
	Mage = {
		Health = 160,
		MaxMana = 160,
		ManaRegen = 3,
		Physical = 0,
		Magic = 5,
		DamageMultiplier = 1,
		CriticalChance = 0,
		CriticalDamage = 1.2,
		MovementSpeed = 100,
		PhysicalResistance = 0,
		MagicResistance = 0,
		PhysicalResistancePenetration = 0,
		MagicResistancePenetration = 0,
		HealthRegen = 0,
		Burn = 0,
		Poison = 0,
		Bleed = 0,
		Ice = 0,
		Lightning = 0,
		Healing = 0,
		Class = "Mage",
		Weapon = "Staff",
	},
	Ranger = {
		Health = 180,
		MaxMana = 110,
		ManaRegen = 2,
		Physical = 5,
		DamageMultiplier = 1,
		CriticalChance = 10,
		CriticalDamage = 2,
		MovementSpeed = 110,
		PhysicalResistance = 0,
		MagicResistance = 0,
		PhysicalResistancePenetration = 0,
		MagicResistancePenetration = 0,
		HealthRegen = 0,
		Burn = 0,
		Poison = 0,
		Bleed = 0,
		Ice = 0,
		Lightning = 0,
		Healing = 0,
		Class = "Ranger",
		Weapon = "Bow",
	},
	Support = {
		Health = 180,
		MaxMana = 145,
		ManaRegen = 2.5,
		Physical = 4,
		Magic = 5,
		DamageMultiplier = 1,
		CriticalChance = 0,
		CriticalDamage = 1.5,
		MovementSpeed = 100,
		PhysicalResistance = 0,
		MagicResistance = 0,
		PhysicalResistancePenetration = 0,
		MagicResistancePenetration = 0,
		HealthRegen = 2,
		Burn = 0,
		Poison = 0,
		Bleed = 0,
		Ice = 0,
		Lightning = 0,
		Healing = 0,
		Class = "Support",
		Weapon = "StaffS",
	},
	Striker = {
		Health = 180,
		MaxMana = 110,
		ManaRegen = 2,
		Physical = 6,
		DamageMultiplier = 1.2,
		CriticalChance = 0,
		CriticalDamage = 2,
		MovementSpeed = 105,
		PhysicalResistance = 1,
		MagicResistance = 1,
		PhysicalResistancePenetration = 0,
		MagicResistancePenetration = 0,
		HealthRegen = 0,
		Burn = 0,
		Poison = 0,
		Bleed = 0,
		Ice = 0,
		Lightning = 0,
		Healing = 0,
		LifestealPercentage = 0,
		Class = "Striker",
		Weapon = "Fist",
	},
}

function ClassFramework:EquipBaseCharacter(player, className)
	local stats = self.BaseStats[className]
	if not stats then
		warn("Invalid class: " .. tostring(className))
		return
	end

	-- Initialize stats and mana
	StatsModule.initializeStats(player, stats)
	AbilityManager.initializePlayer(player)

	local StarterCharacters = ReplicatedStorage:WaitForChild("StarterCharacters")
	local characterTemplate = StarterCharacters:FindFirstChild(className)
	if not characterTemplate then
		warn("Starter character model not found for class: " .. className)
		return
	end

	local oldCharacter = player.Character
	local spawnCFrame = CFrame.new(0, 5, 0)
	if oldCharacter and oldCharacter.PrimaryPart then
		spawnCFrame = oldCharacter.PrimaryPart.CFrame
	end

	if oldCharacter then
		player.Character = nil
		oldCharacter:Destroy()
		task.wait(0.1)
	end

	local newCharacter = characterTemplate:Clone()
	newCharacter.Name = player.Name
	newCharacter.Parent = workspace

	if newCharacter.PrimaryPart then
		newCharacter:SetPrimaryPartCFrame(spawnCFrame)
	else
		local part = newCharacter:FindFirstChild("HumanoidRootPart") or newCharacter:FindFirstChild("Head")
		if part then part.CFrame = spawnCFrame end
	end

	local StarterCharacterScripts = StarterPlayer:FindFirstChild("StarterCharacterScripts")
	if StarterCharacterScripts then
		for _, scriptObj in ipairs(StarterCharacterScripts:GetChildren()) do
			local clone = scriptObj:Clone()
			clone.Parent = newCharacter
		end
	end

	player.Character = newCharacter

	local humanoid = newCharacter:WaitForChild("Humanoid")
	humanoid.WalkSpeed = stats.MovementSpeed / 10

	CustomHealthSystem.Instances[player.UserId] = nil
	CustomHealthSystem.Attach(player, stats.Health, humanoid)

	StarterGui:SetCore("HealthDisplayEnabled", false)
	newCharacter:SetAttribute("WeaponType", stats.Weapon)

	local SetSubject = ReplicatedStorage:WaitForChild("SetSubject")
	if SetSubject then
		task.delay(0.1, function()
			SetSubject:FireClient(player, humanoid)
		end)
	end

	newCharacter.Humanoid.Died:Connect(function()
		wait(game.Players.RespawnTime)
		player:LoadCharacter()
	end)

	local loadSkillsEvent = ReplicatedStorage.Remotes:FindFirstChild("LoadClassSkills")
	if loadSkillsEvent then
		loadSkillsEvent:FireClient(player, className)
	end
end

return ClassFramework
