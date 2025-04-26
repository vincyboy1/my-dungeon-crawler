local CrowdControlHandler = {}
local activeEffects = {}
local ccPriorities = {
	Ragdoll = 6,
	Taunted = 2,
	Stunned = 5,
	Rooted = 4,
	Silenced = 3,
	Slowed = 1,
}

function CrowdControlHandler.applyCC(ccType, character, duration, extraData)
	if not character or not character:FindFirstChild("Humanoid") then
		return
	end
	local handler = script:FindFirstChild(ccType .. "Handler")
	if not handler then
		warn("[CrowdControlHandler] No handler found for CC type:", ccType)
		return
	end
	local currentCCType = next(activeEffects[character] or {})
	local currentPriority = currentCCType and ccPriorities[currentCCType] or 0
	local newPriority = ccPriorities[ccType] or 0
	if currentCCType and newPriority <= currentPriority then return end
	if currentCCType and newPriority > currentPriority then
		print(string.format("[CrowdControlHandler] Removing %s to apply %s (priority %d) on %s.",
			currentCCType, ccType, newPriority, character.Name))
		CrowdControlHandler.removeCC(currentCCType, character)
	end
	local handlerModule = require(handler)
	if handlerModule and handlerModule.Apply then
		print("[Debug] Applying", ccType, "to", character.Name, "for", duration, "seconds.")
		handlerModule.Apply(character, duration, extraData)
		activeEffects[character] = {}
		activeEffects[character][ccType] = true
		task.delay(duration, function()
			if activeEffects[character] and activeEffects[character][ccType] then
				CrowdControlHandler.removeCC(ccType, character)
			end
		end)
	else
		warn("[CrowdControlHandler] Invalid handler for CC type:", ccType)
	end
end

function CrowdControlHandler.removeCC(ccType, character)
	if not character or not activeEffects[character] or not activeEffects[character][ccType] then
		warn("[CrowdControlHandler] No active effect of type:", ccType, "on character:", character and character.Name)
		return
	end
	local handler = script:FindFirstChild(ccType .. "Handler")
	if not handler then
		warn("[CrowdControlHandler] No handler found for CC type:", ccType)
		return
	end
	local handlerModule = require(handler)
	if handlerModule and handlerModule.Remove then
		handlerModule.Remove(character)
		activeEffects[character][ccType] = nil
		if next(activeEffects[character]) == nil then
			activeEffects[character] = nil
		end
	else
		warn("[CrowdControlHandler] Invalid handler for CC type:", ccType)
	end
end

function CrowdControlHandler.clearAllCC(character)
	if not character or not activeEffects[character] then return end
	for ccType in pairs(activeEffects[character]) do
		print("[Debug] Clearing CC type:", ccType, "from", character.Name)
		CrowdControlHandler.removeCC(ccType, character)
	end
end

function CrowdControlHandler.getActiveEffects(character)
	if not character or not activeEffects[character] then return {} end
	local effects = {}
	for ccType in pairs(activeEffects[character]) do
		table.insert(effects, ccType)
	end
	return effects
end

function CrowdControlHandler.isAffectedByCC(character, ccTypes)
	if not character or not activeEffects[character] then return false end
	for _, ccType in ipairs(ccTypes) do
		if activeEffects[character][ccType] then
			print("[Debug] Character", character.Name, "is affected by CC:", ccType)
			return true
		end
	end
	return false
end

return CrowdControlHandler