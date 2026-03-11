-- // SERVICES // --

-- // DEPENDENCIES // --

-- // PRIVATE VARIABLES // --
local ExampleTag = {}
ExampleTag.__index = ExampleTag

-- // TYPES // --
export type ExampleTag = typeof(ExampleTag) & {}

-- // PRIVATE FUNCTIONS // --

-- // PUBLIC FUNCTIONS // --
function ExampleTag.new(): ExampleTag
	local self = setmetatable({}, ExampleTag)
	return self
end

function ExampleTag.Destroy(self: ExampleTag): () end

return ExampleTag
