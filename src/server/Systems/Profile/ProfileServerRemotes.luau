local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)

local ProfileDataUpdated = Net:RemoteEvent("ProfileDataUpdated")
local ProfileDataValueUpdated = Net:RemoteEvent("ProfileDataValueUpdated")

return {
	ProfileDataUpdated = ProfileDataUpdated,
	ProfileDataValueUpdated = ProfileDataValueUpdated,
}
