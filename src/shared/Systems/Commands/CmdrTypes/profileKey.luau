local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileSharedInfo = require(ReplicatedStorage.Shared.Systems.Profile.ProfileSharedInfo)

return function(registry)
	registry:RegisterType("profileKey", registry.Cmdr.Util.MakeEnumType("Profile key", ProfileSharedInfo.KEYS))
end
