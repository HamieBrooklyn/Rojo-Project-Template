-- AnimUtil: resolve, preload, and play animations (with optional Janitor cleanup)
-- Works with Animation objects (preferred) and Studio KeyframeSequences.

local RunService   = game:GetService("RunService")
local Content      = game:GetService("ContentProvider")
local KFSProvider  = game:GetService("KeyframeSequenceProvider")
local RS           = game:GetService("ReplicatedStorage")

local Packages     = RS:WaitForChild("Packages")
local Janitor      = require(Packages:WaitForChild("Janitor"))

local AnimUtil = {}

-- Ensure there's an Animator on the model (AnimationController or Humanoid).
-- If you pass a janitor, any created AnimationController/Animator is registered for cleanup.
function AnimUtil.ensureAnimator(model: Model, janitor): Animator?
	local container = model:FindFirstChildOfClass("AnimationController")
	if not container then container = model:FindFirstChildOfClass("Humanoid") end
	if not container then
		container = Instance.new("AnimationController")
		container.Name = "AnimationController"
		container.Parent = model
		if janitor then janitor:Add(container, "Destroy") end
	end
	local animator = container:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = container
		if janitor then janitor:Add(animator, "Destroy") end
		task.wait() -- let Roblox wire it up
	end
	return animator
end

-- Internal: find an Animation by name or first available under container(s).
local function findAnimationIn(containers: {Instance}, namePref: string?): Animation?
	for _, container in ipairs(containers) do
		if not container then continue end
		local saves = container:FindFirstChild("AnimSaves")

		if namePref and saves then
			local a = saves:FindFirstChild(namePref)
			if a and a:IsA("Animation") and a.AnimationId ~= "" then return a end
		end

		if saves then
			for _, d in ipairs(saves:GetDescendants()) do
				if d:IsA("Animation") and d.AnimationId ~= "" then return d end
			end
		end

		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("Animation") and d.AnimationId ~= "" then return d end
		end
	end
	return nil
end

-- Internal (Studio only): register a KeyframeSequence as a temporary Animation.
-- If a janitor is provided, the created Animation instance is auto-cleaned.
local function registerKFS(containers: {Instance}, namePref: string?, janitor): Animation?
	if not RunService:IsStudio() then return nil end

	for _, container in ipairs(containers) do
		if not container then continue end
		local saves = container:FindFirstChild("AnimSaves")

		local function pickKFS(root: Instance): KeyframeSequence?
			if namePref and saves then
				local k = saves:FindFirstChild(namePref)
				if k and k:IsA("KeyframeSequence") then return k end
			end
			if saves then
				for _, d in ipairs(saves:GetDescendants()) do
					if d:IsA("KeyframeSequence") then return d end
				end
			end
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("KeyframeSequence") then return d end
			end
			return nil
		end

		local kfs = pickKFS(container)
		if kfs then
			local ok, assetId = pcall(function()
				return KFSProvider:RegisterKeyframeSequence(kfs)
			end)
			if ok and assetId and assetId ~= "" then
				local anim = Instance.new("Animation")
				anim.Name = (kfs.Name .. "_Registered")
				anim.AnimationId = assetId
				anim.Parent = container
				if janitor then janitor:Add(anim, "Destroy") end
				return anim
			end
		end
	end

	return nil
end

-- Resolve an Animation named `namePref` (e.g., "Open") from one or more sources.
-- sources: array of Instances to search (e.g., {template, RS.Assets.Animations.Chests[template.Name]}).
-- If a janitor is provided, any temporary Animation created via KFS registration is tracked.
function AnimUtil.resolveAnimation(sources: {Instance}, namePref: string, janitor): Animation?
	local anim = findAnimationIn(sources, namePref)
	if not anim then
		anim = registerKFS(sources, namePref, janitor)
	end
	if anim then
		-- Preload may throw on bad asset or networking hiccup; swallow because it's non-fatal.
		pcall(function() Content:PreloadAsync({anim}) end)
	end
	return anim
end

-- Play to completion, then hold final frame (freeze) so pose stays visible.
-- Returns track, lengthSec. If janitor provided, the track.Stopped connection is tracked
-- and the track will be stopped on janitor cleanup.
function AnimUtil.playToEndHold(animator: Animator, anim: Animation, opts: {timeout: number?, eps: number?}?, janitor): (AnimationTrack?, number)
	local timeout = (opts and opts.timeout) or 8.0
	local eps     = (opts and opts.eps) or (1/30)

	local track = animator:LoadAnimation(anim)
	if not track then return nil, 0 end
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.1, 1, 1)

	-- ensure it actually starts
	local t0 = os.clock()
	while not track.IsPlaying and os.clock() - t0 < 2 do task.wait() end

	local len = 0
	-- Some rigs/old assets can throw here; safe to guard and fallback.
	local ok = pcall(function()
		len = (track.Length and track.Length > 0) and track.Length or track:GetTimeLength()
	end)
	if not ok or len <= 0 then len = 1.2 end

	local finished = false
	local conn = track.Stopped:Connect(function()
		finished = true
	end)
	-- Track the connection so it never leaks on early cleanup.
	if janitor then janitor:Add(conn, "Disconnect") end

	local waited = 0
	while not finished and waited < timeout do
		task.wait(0.05); waited += 0.05
	end

	-- Park on final frame (freeze the last pose)
	track:Play(0, 1, 0)               -- snap
	track.TimePosition = math.max(len - eps, 0)
	track.Looped = true
	track:AdjustSpeed(0)

	-- Ensure cleanup will stop the track if caller forgets
	if janitor then
		janitor:Add(track, function()
			-- AnimationTrack has no Destroy; just stop safely.
			pcall(function() track:AdjustSpeed(0) end)
			pcall(function() track:Stop(0) end)
		end)
	end

	return track, len
end

return AnimUtil
