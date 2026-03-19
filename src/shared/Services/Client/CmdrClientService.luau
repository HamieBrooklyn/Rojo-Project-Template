--!nocheck
-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // VARIABLES // --
local CmdrClientService = {}

-- // TYPES // --
export type CmdrClientService = typeof(CmdrClientService) & {
	Init: (self: CmdrClientService) -> (),
	Start: (self: CmdrClientService) -> (),
}

-- // PUBLIC FUNCTIONS // --
function CmdrClientService.Init(_self: CmdrClientService): ()
	local cmdrClientContainer = ReplicatedStorage:WaitForChild("CmdrClient")
	local CmdrClient = require(cmdrClientContainer)
	CmdrClient:SetActivationKeys({ Enum.KeyCode.F2 })
	CmdrClient:SetPlaceName("Stud Royale")

	local registry = CmdrClient.Registry
	local util = CmdrClient.Util
	if registry and util then
		for _, typeModule in ReplicatedStorage.Shared.Systems.Commands.CmdrTypes:GetChildren() do
			if typeModule:IsA("ModuleScript") then
				registry:RegisterType(typeModule.Name, util.MakeEnumType(typeModule.Name, require(typeModule)))
			end
		end
	end
end

-- // MAIN // --
return CmdrClientService :: CmdrClientService
