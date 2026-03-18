-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // PRIVATE VARIABLES // --
local Particle = {}

local PARTICLE_CONTAINERS = {
	ReplicatedStorage.Assets.VisualEffects.Particles,
}

-- // PRIVATE FUNCTIONS // --

-- // PUBLIC FUNCTIONS // --
function Particle.createParticlePartAt(particlePart: BasePart, cframe: CFrame, parent: Instance?): BasePart
	particlePart = particlePart:Clone()
	particlePart:PivotTo(cframe)
	particlePart.Parent = parent or workspace.Terrain
	return particlePart
end
function Particle.emitAllUnder(
	parent: Instance,
	sharedEmitCount: number?,
	ignoreAutoCleanup: boolean?,
	finished: (() -> ())?
): ()
	local lifetime: number = 0
	for _, v in parent:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			if v.Lifetime.Max > lifetime then
				lifetime = v.Lifetime.Max
			end
			v:Emit(sharedEmitCount or v:GetAttribute("EmitCount") or 1)
		end
	end
	if not ignoreAutoCleanup then
		task.delay(lifetime, function()
			if finished ~= nil then
				finished()
			end
			parent:Destroy()
		end)
	end
end

-- // SETUP // --
for _, v: Instance in PARTICLE_CONTAINERS do
	for _, emitter: ParticleEmitter? in v:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = false
		end
	end
end

return Particle
