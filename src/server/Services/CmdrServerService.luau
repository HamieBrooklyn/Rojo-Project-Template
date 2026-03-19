-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // DEPENDENCIES // --
local Cmdr = require(ReplicatedStorage.Packages.Cmdr)

-- // CONSTANTS // --
local ALLOWED_USER_IDS: { number } = {
	1236498240, -- Mrloadd
} -- Add UserIds here to grant command permission (e.g. { 123456789 })

-- // VARIABLES // --
local CmdrServerService = {}

-- // TYPES // --
export type CmdrServerService = typeof(CmdrServerService) & {
	Init: (self: CmdrServerService) -> (),
	Start: (self: CmdrServerService) -> (),
}

-- // PRIVATE FUNCTIONS // --
local function getCmdrTypesFolder(): Instance?
	return ReplicatedStorage.Shared.Systems.Commands.CmdrTypes
end

local function getCmdrCommandsFolder(): Instance?
	return ReplicatedStorage.Shared.Systems.Commands.CmdrCommands
end

local function canRunCommand(executorUserId: number): boolean
	if executorUserId == game.CreatorId then
		return true
	end
	for _, id in ipairs(ALLOWED_USER_IDS) do
		if id == executorUserId then
			return true
		end
	end
	return false
end

-- // PUBLIC FUNCTIONS // --
function CmdrServerService.Start(_self: CmdrServerService): ()
	local typesFolder = getCmdrTypesFolder()
	if typesFolder then
		Cmdr:RegisterTypesIn(typesFolder)
	end

	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		if not canRunCommand(context.Executor.UserId) then
			return "You don't have permission to run this command."
		end
		return nil
	end)

	local commandsFolder = getCmdrCommandsFolder()
	if commandsFolder then
		Cmdr:RegisterCommandsIn(commandsFolder)
	end
	return nil
end

-- // MAIN // --
return CmdrServerService :: CmdrServerService
