-- // SERVICES // --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // DEPENDENCIES // --
local TagRunner = require(ReplicatedStorage.Shared.Utilities.TagRunner)

-- // VARIABLES // --
local TagsClientService = {}

-- // TYPES // --
export type TagsClientService = typeof(TagsClientService) & {
	_classesFolder: Instance,
	_runCleanup: () -> (),
}

-- // PRIVATE FUNCTIONS // --

-- // PUBLIC FUNCTIONS // --
function TagsClientService.Init(self: TagsClientService): ()
	-- Classes folder: sibling folder named TagsClientServiceClasses (contains tag class modules)
	self._classesFolder = ReplicatedStorage.Shared.Systems.Tags
end

function TagsClientService.Start(self: TagsClientService): ()
	self._runCleanup = TagRunner.run(self._classesFolder)
end

-- // MAIN // --
return TagsClientService :: TagsClientService
