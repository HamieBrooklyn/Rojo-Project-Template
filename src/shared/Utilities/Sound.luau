-- // SERVICES // --
local SoundService = game:GetService("SoundService")

-- // PRIVATE VARIABLES // --
local Sound = {
	_replicatedSounds = {} :: { Sound },
}

local repSoundsFold = Instance.new("Folder")
repSoundsFold.Name = "_ReplicatedSounds"
repSoundsFold.Parent = SoundService

-- // PUBLIC FUNCTIONS // --
function Sound.playSound(parent: Instance?, properties: { [string]: any }, ignoreDestroyOnEnd: boolean?): Sound
	local sound = Sound._getSound(properties, ignoreDestroyOnEnd)
	sound.Parent = parent
	sound:Play()
	return sound
end

function Sound.startSoundReplication(properties: { [string]: any })
	local sound = Sound._getSound(properties)
	if Sound._replicatedSounds[properties.SoundId] then
		Sound._replicatedSounds[properties.SoundId]:Destroy()
	end
	sound.Parent = repSoundsFold
	Sound._replicatedSounds[properties.SoundId] = sound
end
function Sound.stopSoundReplication(id: string)
	local sound = Sound._replicatedSounds[id]
	if sound then
		sound:Destroy()
	end
end

function Sound._getSound(properties: { [string]: any }, ignoreDestroyOnEnd: boolean?): Sound
	local replicatedSound: Sound? = Sound._replicatedSounds[properties.SoundId]
	local sound = replicatedSound ~= nil and replicatedSound:Clone() or Instance.new("Sound")
	for i, v in properties do
		sound[i] = v
	end
	if not ignoreDestroyOnEnd then
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
	return sound
end

return Sound
