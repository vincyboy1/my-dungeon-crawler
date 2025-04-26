local CustomHealthSystem = {}
CustomHealthSystem.__index = CustomHealthSystem

CustomHealthSystem.Instances = {}

function CustomHealthSystem.new(player, maxHealth, humanoid)
	local self = setmetatable({}, CustomHealthSystem)
	self.Player = player
	self.MaxHealth = maxHealth or 100
	self.Health = self.MaxHealth
	self.LowHealthActive = false
	self.IsDowned = false
	self.IsDying = false
	self.ShieldHealth = 0
	self.HexShield = 0
	self.Humanoid = humanoid or nil
	if humanoid then
		self.DefaultSpeed = humanoid.WalkSpeed
	else
		self.DefaultSpeed = 16
	end
	self.HealthChanged = Instance.new("BindableEvent")
	self.Died = Instance.new("BindableEvent")
	self.Downed = Instance.new("BindableEvent")
	return self
end

function CustomHealthSystem.Attach(player, maxHealth, humanoid)
	local key
	if player:IsA("Player") then
		key = player.UserId
	else
		key = player.Name
	end
	CustomHealthSystem.Instances[key] = nil
	local instance = CustomHealthSystem.new(player, maxHealth, humanoid)
	CustomHealthSystem.Instances[key] = instance
	instance.HealthChanged:Fire(instance:GetStatus())
	return instance
end

function CustomHealthSystem.GetInstance(player)
	local key
	if player:IsA("Player") then
		key = player.UserId
	else
		key = player.Name
	end
	return CustomHealthSystem.Instances[key]
end

function CustomHealthSystem:ApplyShield(damage)
	local shield = self.ShieldHealth or 0
	shield = math.max(tonumber(shield) or 0, 0)
	print("[CustomHealthSystem] Checking shield:", shield)
	if shield > 0 then
		if damage <= shield then
			self.ShieldHealth = shield - damage
			print("[CustomHealthSystem] Shield absorbed:", damage, "Remaining shield:", self.ShieldHealth)
			self.HealthChanged:Fire(self:GetStatus())
			return 0
		else
			damage = damage - shield
			self.ShieldHealth = 0
			print("[CustomHealthSystem] Shield broke! Remaining damage:", damage)
			self.HealthChanged:Fire(self:GetStatus())
		end
	end
	return damage
end

function CustomHealthSystem:TakeDamage(n)
	if self.IsDowned or self.IsDying then
		print("[CustomHealthSystem] Damage ignored; instance is downed or dying.")
		return
	end
	local hexShield = self.HexShield or 0
	if hexShield > 0 then
		if n <= hexShield then
			self.HexShield = hexShield - n
			print("[CustomHealthSystem] Hex shield absorbed:", n, "Remaining Hex shield:", self.HexShield)
			self.HealthChanged:Fire(self:GetStatus())
			return
		else
			n = n - hexShield
			self.HexShield = 0
			print("[CustomHealthSystem] Hex shield broke! Remaining damage:", n)
		end
	end
	local remainingDamage = self:ApplyShield(n)
	if remainingDamage <= 0 then
		return
	end
	if remainingDamage >= self.Health then
		self.LastDamage = self.Health
		self.Health = 0
		self.HealthChanged:Fire(self:GetStatus())
		print("[CustomHealthSystem] Fatal damage received; entering downed state.")
		self.IsDying = true
		self:EnterDownedState()
		return
	end
	self.LastDamage = remainingDamage
	local newHealth = self.Health - remainingDamage
	self.Health = newHealth
	self.HealthChanged:Fire(self:GetStatus())
	print(string.format("[CustomHealthSystem] Took %.2f damage. Health now: %.2f / %.2f", remainingDamage, self.Health, self.MaxHealth))
end

function CustomHealthSystem:Heal(n)
	self.Health = math.min(self.Health + n, self.MaxHealth)
	self.HealthChanged:Fire(self:GetStatus())
	print(string.format("[CustomHealthSystem] Healed %.2f. Health now: %.2f / %.2f", n, self.Health, self.MaxHealth))
end

function CustomHealthSystem:TriggerLowHealth()
	self.LowHealthActive = true
	self.Health = self.MaxHealth * 0.40
	self.HealthChanged:Fire(self:GetStatus())
	print("[CustomHealthSystem] Low Health triggered. Health set to 40% of MaxHealth.")
end

function CustomHealthSystem:EnterDownedState()
	self.IsDowned = true
	print("[CustomHealthSystem] Entered downed state.")
	self.Downed:Fire()
	if self.Humanoid then
		self.Humanoid.WalkSpeed = 0
	end
	local character = self.Player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local revivePart = Instance.new("Part")
			revivePart.Name = "RevivePart"
			revivePart.Size = Vector3.new(16, 1, 16)
			revivePart.Position = hrp.Position
			revivePart.Anchored = true
			revivePart.CanCollide = false
			revivePart.Transparency = 0.5
			revivePart.Parent = workspace

			local touchConnections = {}
			local reviveTriggered = false

			local function onTouched(hit)
				if reviveTriggered then return end
				local otherHumanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
				if otherHumanoid and otherHumanoid ~= self.Humanoid then
					local otherPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
					if otherPlayer and otherPlayer.Team == self.Player.Team then
						print("[CustomHealthSystem] Teammate " .. otherPlayer.Name .. " started revival process.")
						reviveTriggered = true
						wait(5)
						if self.IsDowned then
							self:ReviveByTeammate()
							if revivePart then
								revivePart:Destroy()
							end
							for _, conn in pairs(touchConnections) do
								conn:Disconnect()
							end
						end
					end
				end
			end

			table.insert(touchConnections, revivePart.Touched:Connect(onTouched))
		end
	end
	delay(30, function()
		if self.IsDowned then
			print("[CustomHealthSystem] Downed timer expired. Instance will now fully die (respawn).")
			self:Die()
		end
	end)
end

function CustomHealthSystem:ReviveByTeammate()
	if not self.IsDowned then
		print("[CustomHealthSystem] Cannot revive; instance is not downed.")
		return
	end
	self.IsDowned = false
	self.IsDying = false
	self.Health = self.MaxHealth * 0.20
	self.HealthChanged:Fire(self:GetStatus())
	print("[CustomHealthSystem] Instance revived by teammate. Health set to 20% of MaxHealth.")
	if self.Humanoid and self.DefaultSpeed then
		self.Humanoid.WalkSpeed = self.DefaultSpeed
	end
end

function CustomHealthSystem:Revive()
	if not self.IsDowned then
		print("[CustomHealthSystem] Cannot revive; instance is not downed.")
		return
	end
	self.IsDowned = false
	self.IsDying = false
	self.Health = self.MaxHealth * 0.5
	self.HealthChanged:Fire(self:GetStatus())
	print("[CustomHealthSystem] Instance revived. Health set to 50% of MaxHealth.")
	if self.Humanoid and self.DefaultSpeed then
		self.Humanoid.WalkSpeed = self.DefaultSpeed
	end
end

function CustomHealthSystem:Die()
	print("[CustomHealthSystem] Instance died. Respawning player:", self.Player.Name)
	self.Died:Fire()
	CustomHealthSystem.Instances[self.Player.UserId] = nil
	local character = self.Player.Character
	if character then
		character:Destroy()
	end
	delay(5, function()
		if self.Player and self.Player.Parent then
			self.Player:LoadCharacter()
		end
	end)
end

function CustomHealthSystem:GetStatus()
	return {
		Health = self.Health,
		MaxHealth = self.MaxHealth,
		LowHealthActive = self.LowHealthActive,
		IsDowned = self.IsDowned,
		ShieldHealth = self.ShieldHealth,
		HexShield = self.HexShield,
		LastDamage = self.LastDamage or 0,
	}
end

return CustomHealthSystem