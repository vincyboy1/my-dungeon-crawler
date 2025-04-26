-- ReplicatedStorage/Modules/Combat/CombatUtils.lua
local CombatUtils = {}
local Workspace = game:GetService("Workspace")

-- Raycast helper
function CombatUtils.Raycast(origin, direction, params)
	return Workspace:Raycast(origin, direction, params)
end

-- Sweep helper (multiple raycasts)
function CombatUtils.Sweep(attachment0, attachment1, rayCount, params)
	local hits = {}
	local pos0 = attachment0.WorldPosition
	local pos1 = attachment1.WorldPosition
	for i = 0, rayCount do
		local t = i / rayCount
		local origin = pos0:Lerp(pos1, t)
		local direction = (pos1 - pos0)
		local result = Workspace:Raycast(origin, direction, params)
		if result then
			table.insert(hits, result)
		end
	end
	return hits
end

-- Combo manager
local Combo = {}
Combo.__index = Combo
function Combo.new(maxCombo, window)
	return setmetatable({ maxCombo = maxCombo, window = window, count = 0, lastTime = 0 }, Combo)
end

function Combo:TryAdvance()
	local now = os.clock()
	if now - self.lastTime <= self.window and self.count < self.maxCombo then
		self.count = self.count + 1
	else
		self.count = 1
	end
	self.lastTime = now
	return self.count
end

function Combo:Reset()
	self.count = 0
	self.lastTime = 0
end

CombatUtils.ComboManager = Combo

return CombatUtils