-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- // DEPENDENCIES // --
local Fusion = require(ReplicatedStorage.Packages.Fusion)

-- // CONSTANTS // --
local DEFAULT_SPEED = 10
local DEFAULT_DAMPING = 0.8
local SETTLE_EPSILON = 0.0001
local SETTLE_FRAMES = 3
-- Minimum change before applying to target (reduces expensive Model:ScaleTo / property sets)
local MIN_CHANGE_SCALE = 0.004
local MIN_CHANGE_VECTOR3 = 0.02
local MIN_CHANGE_UDIM2_SQ = 0.0004 -- squared so we avoid sqrt in hot path
local DEFAULT_SIZE_UPDATE_RATE = 30 -- Hz; lower = fewer Model:ScaleTo calls, still smooth

-- // TYPES // --
export type JumpOptions = {
	height: number,
	speed: number?,
	damping: number?,
	scope: any?, -- Fusion.Scope when provided
}

export type SpringSizeOptions = {
	targetSize: number | Vector3 | UDim2,
	speed: number?,
	damping: number?,
	scope: any?, -- Fusion.Scope when provided
	-- Update rate in Hz (e.g. 30). Lower = fewer apply calls, especially helps Model:ScaleTo. Default 30 for models, every frame for parts/gui.
	updateRate: number?,
}

type Scope = typeof(Fusion.scoped())
type SizeTargetType = "model" | "part" | "gui"

-- // PRIVATE HELPERS // --

local function getTargetBasePosition(target: Instance)
	if target:IsA("BasePart") then
		return target.Position, false
	end
	if target:IsA("Model") then
		local primary = target.PrimaryPart
		if primary then
			return primary.Position, false
		end
		return target:GetPivot().Position, false
	end
	if target:IsA("GuiObject") then
		return target.Position, true
	end
	return nil
end

local function applyOffsetToTarget(target: Instance, base: Vector3 | UDim2, offset: number, isGui: boolean)
	if isGui then
		local udim2 = base :: UDim2
		(target :: GuiObject).Position =
			UDim2.new(udim2.X.Scale, udim2.X.Offset, udim2.Y.Scale, udim2.Y.Offset - offset)
	else
		local pos = base :: Vector3
		local newPos = Vector3.new(pos.X, pos.Y + offset, pos.Z)
		if target:IsA("BasePart") then
			(target :: BasePart).Position = newPos
		elseif target:IsA("Model") then
			local model = target :: Model
			local primary = model.PrimaryPart
			if primary then
				model:SetPrimaryPartCFrame(CFrame.new(newPos))
			else
				model:PivotTo(CFrame.new(newPos))
			end
		end
	end
end

local function initialVelocityForHeight(height: number, speed: number, damping: number): number
	return height * speed * math.sqrt(math.max(0, 1 - damping * damping))
end

local function getCurrentSize(target: Instance)
	if target:IsA("Model") then
		return (target :: Model):GetScale(), "model"
	end
	if target:IsA("BasePart") then
		return (target :: BasePart).Size, "part"
	end
	if target:IsA("GuiObject") then
		return (target :: GuiObject).Size, "gui"
	end
	return nil, nil
end

local function applySizeToTarget(target: Instance, size: number | Vector3 | UDim2, sizeType: SizeTargetType)
	if sizeType == "model" then
		(target :: Model):ScaleTo(size :: number)
	elseif sizeType == "part" then
		(target :: BasePart).Size = size :: Vector3
	elseif sizeType == "gui" then
		(target :: GuiObject).Size = size :: UDim2
	end
end

local function sizeChangeExceedsThreshold(
	newSize: number | Vector3 | UDim2,
	lastApplied: number | Vector3 | UDim2?,
	sizeType: SizeTargetType
): boolean
	if lastApplied == nil then
		return true
	end
	if sizeType == "model" then
		return math.abs((newSize :: number) - (lastApplied :: number)) >= MIN_CHANGE_SCALE
	end
	if sizeType == "part" then
		return ((newSize :: Vector3) - (lastApplied :: Vector3)).Magnitude >= MIN_CHANGE_VECTOR3
	end
	local u = newSize :: UDim2
	local v = lastApplied :: UDim2
	local dx = u.X.Scale - v.X.Scale
	local dy = u.X.Offset - v.X.Offset
	local dz = u.Y.Scale - v.Y.Scale
	local dw = u.Y.Offset - v.Y.Offset
	return (dx * dx + dy * dy + dz * dz + dw * dw) >= MIN_CHANGE_UDIM2_SQ
end

-- // PUBLIC API // --

local Animation = {}

function Animation.jump(target: Instance, options: JumpOptions): () -> ()
	local height = options.height
	local speed = options.speed or DEFAULT_SPEED
	local damping = options.damping or DEFAULT_DAMPING
	local providedScope = options.scope

	local base, isGui = getTargetBasePosition(target)
	if not base then
		error("Animation.jump: unsupported target type " .. target.ClassName, 2)
	end

	local scope: Scope = providedScope or Fusion.scoped()
	local ownsScope = (providedScope == nil)

	local goal = Fusion.Value(scope, 0)
	local spring = Fusion.Spring(scope, goal, speed, damping)

	local v0 = initialVelocityForHeight(height, speed, damping)
	if isGui then
		v0 = -v0
	end
	spring:setVelocity(v0)

	local connection: RBXScriptConnection?
	local settledFrames = 0
	local cleaned = false

	local function doCleanup()
		if cleaned then
			return
		end
		cleaned = true
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if ownsScope then
			Fusion.doCleanup(scope)
		end
	end

	connection = RunService.Heartbeat:Connect(function()
		if not target.Parent then
			doCleanup()
			return
		end
		local offset = Fusion.peek(spring)
		applyOffsetToTarget(target, base, offset, isGui)
		if math.abs(offset) < SETTLE_EPSILON then
			settledFrames += 1
			if settledFrames >= SETTLE_FRAMES then
				doCleanup()
			end
		else
			settledFrames = 0
		end
	end)

	return doCleanup
end

function Animation.springSize(target: Instance, options: SpringSizeOptions): () -> ()
	local targetSize = options.targetSize
	local speed = options.speed or DEFAULT_SPEED
	local damping = options.damping or DEFAULT_DAMPING
	local providedScope = options.scope
	local requestedUpdateRate = options.updateRate

	local currentSize, sizeType = getCurrentSize(target)
	if not sizeType then
		error("Animation.springSize: unsupported target type " .. target.ClassName, 2)
	end

	-- Models: default 30 Hz to reduce Model:ScaleTo cost; parts/gui: every frame
	local updateRate: number? = requestedUpdateRate
	if updateRate == nil and sizeType == "model" then
		updateRate = DEFAULT_SIZE_UPDATE_RATE
	end

	local scope: Scope = providedScope or Fusion.scoped()
	local ownsScope = (providedScope == nil)

	local goal = Fusion.Value(scope, currentSize)
	local spring = Fusion.Spring(scope, goal, speed, damping)
	goal:set(targetSize)

	local connection: RBXScriptConnection?
	local settledFrames = 0
	local cleaned = false
	local lastAppliedSize: number | Vector3 | UDim2? = nil

	local function isSettled(size: number | Vector3 | UDim2): boolean
		if typeof(size) == "number" then
			return math.abs((size :: number) - (targetSize :: number)) < SETTLE_EPSILON
		end
		if typeof(size) == "Vector3" then
			return ((size :: Vector3) - (targetSize :: Vector3)).Magnitude < SETTLE_EPSILON
		end
		local u = size :: UDim2
		local t = targetSize :: UDim2
		local dx = u.X.Scale - t.X.Scale
		local dy = u.X.Offset - t.X.Offset
		local dz = u.Y.Scale - t.Y.Scale
		local dw = u.Y.Offset - t.Y.Offset
		return (dx * dx + dy * dy + dz * dz + dw * dw) < (SETTLE_EPSILON * SETTLE_EPSILON)
	end

	local function doCleanup()
		if cleaned then
			return
		end
		cleaned = true
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if ownsScope then
			Fusion.doCleanup(scope)
		end
	end

	local function tick()
		if not target.Parent then
			doCleanup()
			return
		end
		local size = Fusion.peek(spring)
		if sizeChangeExceedsThreshold(size, lastAppliedSize, sizeType) then
			applySizeToTarget(target, size, sizeType)
			lastAppliedSize = size
		end
		if isSettled(size) then
			settledFrames += 1
			if settledFrames >= SETTLE_FRAMES then
				doCleanup()
			end
		else
			settledFrames = 0
		end
	end

	if updateRate and updateRate > 0 then
		task.spawn(function()
			while not cleaned and target.Parent do
				tick()
				task.wait(1 / updateRate)
			end
			if not cleaned then
				doCleanup()
			end
		end)
	else
		connection = RunService.Heartbeat:Connect(tick)
	end

	return doCleanup
end

return Animation
