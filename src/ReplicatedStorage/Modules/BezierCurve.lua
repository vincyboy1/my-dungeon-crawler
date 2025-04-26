--// SERVICES
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// TYPES
type Point = Vector3 | BasePart
type Params = {
	Duration: number,
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
	LookAt: boolean,
	PointsInObjectSpace: boolean?
}

--// VARIABLES
local Module = {}

--// FUNCTIONS
local function lerp(startPoint: Point, endPoint: Point, alpha: number)
	if typeof(startPoint) == "Instance" then
		startPoint = startPoint.Position
	end
	if typeof(endPoint) == "Instance" then
		endPoint = endPoint.Position
	end
	return startPoint:Lerp(endPoint, alpha)
end

local function lerpPoints(points: {Point}, alpha: number)
	local lerps = {}
	local startPoint = points[1]
	local endPoint = points[2]
	for i = 2, #points do
		table.insert(lerps, lerp(startPoint, endPoint, alpha))
		startPoint = points[i]
		i += 1
		endPoint = points[i]
	end

	if #lerps == 1 then
		return lerps[1]
	else
		return lerpPoints(lerps, alpha)
	end
end

--// MODULE FUNCTIONS
function Module.Play(target: BasePart, points: {Point}, waitUntilCompleted: boolean, params: Params)
	local duration = params.Duration
	local style = params.EasingStyle
	local direction = params.EasingDirection
	local lookAt = params.LookAt
	local startTime = os.clock()

	local startCFrame
	local pointsInObjectSpace = params.PointsInObjectSpace
	if pointsInObjectSpace then
		startCFrame = target.CFrame
	end

	local thread = coroutine.running()
	local heartbeat
	heartbeat = RunService.Heartbeat:Connect(function()
		local alpha = (os.clock() - startTime) / duration
		alpha = TweenService:GetValue(alpha, style, direction)
		if alpha >= 1 then
			heartbeat:Disconnect()
			alpha = 1

			local endPoint = points[#points]
			if typeof(endPoint) == "Instance" then
				endPoint = endPoint.Position
			end
			if pointsInObjectSpace then
				endPoint = startCFrame:PointToWorldSpace(endPoint)
			end
			
			if lookAt then
				local lookAtPosition = endPoint
				if typeof(lookAt) == "Instance" then
					lookAtPosition = lookAt.Position
				elseif typeof(lookAt) == "Vector3" then
					lookAtPosition = lookAt
				end

				local x, y, z = CFrame.lookAt(target.Position, lookAtPosition):ToOrientation()
				target.CFrame = CFrame.new(endPoint) * CFrame.fromOrientation(x, y, z)
			else
				target.Position = endPoint
			end

			if waitUntilCompleted then
				coroutine.resume(thread)
			end
		else
			local position = lerpPoints(points, alpha)
			if pointsInObjectSpace then
				position = startCFrame:PointToWorldSpace(position)
			end

			if lookAt then
				local lookAtPosition = position
				if typeof(lookAt) == "Instance" then
					lookAtPosition = lookAt.Position
				elseif typeof(lookAt) == "Vector3" then
					lookAtPosition = lookAt
				end

				local x, y, z = CFrame.lookAt(target.Position, lookAtPosition):ToOrientation()
				target.CFrame = CFrame.new(position) * CFrame.fromOrientation(x, y, z)
			else
				target.Position = position
			end
		end
	end)

	if waitUntilCompleted then
		coroutine.yield()
	end

	return heartbeat
end

return Module