-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- // DEPENDENCIES // --
local ProfileServerRemotes = require(ServerScriptService.Server.Systems.Profile.ProfileServerRemotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ProfileSharedInfo = require(ReplicatedStorage.Shared.Systems.Profile.ProfileSharedInfo)
local Observers = require(ReplicatedStorage.Shared.Utilities.Observers)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

-- // VARIABLES // --
local ProfileServerService = {}

local PlayerStore = ProfileStore.New(ProfileSharedInfo.StoreVersion, ProfileSharedInfo.ProfileTemplate)

-- // TYPES // --
type Profile = typeof(PlayerStore:StartSessionAsync())
export type ProfileServerService = typeof(ProfileServerService) & {
	playerProfileLoaded: Signal.Signal<Player, Profile>,
	playerProfileLastSave: Signal.Signal<Player, Profile, string>,

	_profiles: { [Player]: Profile },
}

-- CONSTANTS --

-- // PRIVATE FUNCTIONS // --
local function deepCopy(source: any): any
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for k, v in source do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function replicateProfileDataToClient(self: ProfileServerService, player: Player): ()
	local profile = self._profiles[player]
	if profile and player.Parent == Players then
		ProfileServerRemotes.ProfileDataUpdated:FireClient(player, deepCopy(profile.Data))
	end
end

local function replicateProfileDataValueToClient(
	_self: ProfileServerService,
	player: Player,
	key: string,
	value: any
): ()
	print(player, key, value)
	ProfileServerRemotes.ProfileDataValueUpdated:FireClient(player, key, value)
end

-- // PUBLIC FUNCTIONS // --
function ProfileServerService.Init(self: ProfileServerService): ()
	self.playerProfileLoaded = Signal.new()
	self.playerProfileLastSave = Signal.new()

	self._profiles = {} :: { [Player]: Profile }
	Observers.observePlayers(function(player: Player): () -> ()
		-- Start a profile session for this player's data:

		local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId) -- GDPR compliance
			profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

			profile.OnSessionEnd:Connect(function()
				self._profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)
			profile.OnLastSave:Connect(function(reason)
				self.playerProfileLastSave:Fire(player, profile, reason)
			end)

			if player.Parent == Players then
				self._profiles[player] = profile
				print(`Profile loaded for {player.DisplayName}!`)
				self.playerProfileLoaded:Fire(player, profile)
				replicateProfileDataToClient(self, player)
			else
				-- The player has left before the profile session started
				profile:EndSession()
			end
		else
			-- This condition should only happen when the Roblox server is shutting down
			player:Kick(`Profile load fail - Please rejoin`)
		end
		return function()
			profile:EndSession()
			self._profiles[player] = nil
		end
	end)
end

function ProfileServerService.GetProfile(self: ProfileServerService, player: Player)
	return self._profiles[player]
end
function ProfileServerService.ObservePlayerProfile(
	self: ProfileServerService,
	player: Player,
	callback: (
		profile: typeof(PlayerStore:StartSessionAsync())
	) -> (reason: string) -> ()
): () -> ()
	local function onProfileLoaded(loadedPlayer: Player)
		if loadedPlayer == player then
			local profile = self._profiles[player]
			local cleanup = callback(profile)
			local con: RBXScriptConnection
			con = profile.OnLastSave:Connect(function(reason: "External" | "Manual" | "Shutdown")
				con:Disconnect()
				cleanup(reason)
			end)
		end
	end
	local connection = self.playerProfileLoaded:Connect(onProfileLoaded)
	if self._profiles[player] ~= nil then
		onProfileLoaded(player)
	end
	return function()
		connection:Disconnect()
	end
end
function ProfileServerService.ObserveProfiles(
	self: ProfileServerService,
	callback: (
		player: Player,
		profile: typeof(PlayerStore:StartSessionAsync())
	) -> (reason: string) -> ()
): () -> ()
	local obs = Observers.observePlayers(function(player: Player): () -> ()
		local cleanup = self:ObservePlayerProfile(player, function(profile): (reason: string) -> ()
			return callback(player, profile)
		end)
		return cleanup
	end)
	return function()
		obs()
	end
end

function ProfileServerService.Set(
	self: ProfileServerService,
	player: Player,
	key: string,
	value: any,
	ignoreClientSync: boolean?
): ()
	local profile = self._profiles[player]
	if profile ~= nil then
		profile.Data[key] = value
		if not ignoreClientSync then
			replicateProfileDataValueToClient(self, player, key, value)
		end
	else
		warn(`Attempted to set key '{key}' for player '{player.Name}', but profile is not loaded.`)
	end
end
function ProfileServerService.Get(self: ProfileServerService, player: Player, key: string): any
	local profile = self._profiles[player]
	if profile ~= nil then
		return profile.Data[key]
	else
		warn(`Attempted to get key '{key}' for player '{player.Name}', but profile is not loaded.`)
		return nil
	end
end
function ProfileServerService.Update(
	self: ProfileServerService,
	player: Player,
	key: string,
	callback: (currentValue: any) -> any,
	ignoreClientSync: boolean?
): ()
	local profile = self._profiles[player]
	if profile ~= nil then
		local currentValue = profile.Data[key]
		local newValue = callback(currentValue)
		if newValue == nil then
			warn(`Update callback for key '{key}' for player '{player.Name}' returned nil. No update performed.`)
			return
		end
		profile.Data[key] = newValue
		if not ignoreClientSync then
			replicateProfileDataValueToClient(self, player, key, newValue)
		end
	else
		warn(`Attempted to update key '{key}' for player '{player.Name}', but profile is not loaded.`)
	end
end

-- // MAIN // --
return ProfileServerService :: ProfileServerService
