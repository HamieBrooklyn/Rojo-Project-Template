-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // DEPENDENCIES // --
local Charm = require(ReplicatedStorage.Packages.Charm)
local Net = require(ReplicatedStorage.Packages.Net)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ProfileSharedTypes = require(ReplicatedStorage.Shared.Systems.Profile.ProfileSharedTypes)

-- // VARIABLES // --
local atom, subscribe = Charm.atom, Charm.subscribe

local ProfileClientService = {}

-- // TYPES // --
export type ProfileClientService = typeof(ProfileClientService) & {
	_profileData: Charm.Atom<ProfileSharedTypes.ProfileDataTable?>,

	_profileDataUpdated: Signal.Signal<ProfileSharedTypes.ProfileDataTable?>,
	_profileDataValueUpdated: Signal.Signal<string, any>,
}

-- // PUBLIC FUNCTIONS // --
function ProfileClientService.Init(self: ProfileClientService): ()
	self._profileData = atom(nil :: ProfileSharedTypes.ProfileDataTable?)

	self._profileDataUpdated = Signal.new()
	self._profileDataValueUpdated = Signal.new()

	Net:Connect("ProfileDataUpdated", function(data: ProfileSharedTypes.ProfileDataTable)
		self._profileData(data)
		self._profileDataUpdated:Fire(data)
		if data then
			for key, value in data do
				self._profileDataValueUpdated:Fire(key, value)
			end
		end
	end)
	Net:Connect("ProfileDataValueUpdated", function(key: string, value: any)
		local state = self._profileData()
		if state then
			state[key] = value
			self._profileData(state)
		end
		self._profileDataValueUpdated:Fire(key, value)
	end)
end

function ProfileClientService.GetProfileData(self: ProfileClientService): ProfileSharedTypes.ProfileDataTable?
	return self._profileData()
end

function ProfileClientService.ObserveProfileData(
	self: ProfileClientService,
	callback: (data: ProfileSharedTypes.ProfileDataTable?) -> ()
): () -> ()
	local observer = subscribe(self._profileData, function(value)
		callback(value)
	end)
	return function()
		observer()
	end
end

function ProfileClientService.ObserveProfileDataValue(
	self: ProfileClientService,
	key: string,
	callback: (value: any) -> ()
): () -> ()
	local trove = Trove.new()
	local state = self._profileData()
	if state and state[key] then
		callback(state[key])
	end
	trove:Add(self._profileDataValueUpdated:Connect(function(updatedKey: string, value: any)
		if updatedKey == key then
			callback(value)
		end
	end))
	return function()
		trove:Destroy()
	end
end

-- // MAIN // --
return ProfileClientService :: ProfileClientService
