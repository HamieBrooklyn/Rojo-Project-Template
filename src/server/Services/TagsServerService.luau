-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- // DEPENDENCIES // --
local TagRunner = require(ReplicatedStorage.Shared.Utilities.TagRunner)

-- // VARIABLES // --
local TagsServerService = {}

-- // TYPES // --
export type TagsServerService = typeof(TagsServerService) & {
	_classesFolder: Instance,
	_runCleanup: () -> (),
}

-- // PRIVATE FUNCTIONS // --

-- // PUBLIC FUNCTIONS // --
function TagsServerService.Init(self: TagsServerService): ()
	-- Classes folder: sibling folder named TagsServerServiceClasses (contains tag class modules)
	self._classesFolder = ServerScriptService.Server:FindFirstChild("Systems"):FindFirstChild("Tags")
end

function TagsServerService.Start(self: TagsServerService): ()
	self._runCleanup = TagRunner.run(self._classesFolder)
end

-- // MAIN // --
return TagsServerService :: TagsServerService
