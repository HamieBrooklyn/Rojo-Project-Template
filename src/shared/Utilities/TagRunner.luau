-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // DEPENDENCIES // --
local Observers = require(ReplicatedStorage.Shared.Utilities.Observers)

-- // VARIABLES // --
local TagRunner = {}

-- // TYPES // --
export type TagRunner = typeof(TagRunner)

-- // PRIVATE FUNCTIONS // --

--- Collect all ModuleScript descendants of folder (recursive). Used to support categorized subfolders.
local function getTagModules(folder: Instance): { ModuleScript }
	local out = {} :: { ModuleScript }
	for _, child in folder:GetDescendants() do
		if child:IsA("ModuleScript") then
			table.insert(out, child :: ModuleScript)
		end
	end
	return out
end

local function runTag(classModule: ModuleScript): () -> ()
	local tagName = classModule.Name
	local Class = require(classModule)

	local observeCleanup = Observers.observeTag(tagName, function(instance: Instance): () -> ()
		if Class.OnlyLocalPlayer and not instance:IsDescendantOf(Players.LocalPlayer.PlayerGui) then
			return function() end
		end
		local obj = Class.new(instance)
		local cleaned = false
		local destroyingConnection: RBXScriptConnection?

		local function doCleanup()
			if cleaned then
				return
			end
			cleaned = true
			if destroyingConnection then
				destroyingConnection:Disconnect()
				destroyingConnection = nil
			end
			if obj and type(obj.Destroy) == "function" then
				obj:Destroy()
			end
		end

		destroyingConnection = instance.Destroying:Connect(doCleanup)
		return doCleanup
	end)

	return observeCleanup
end

-- // PUBLIC FUNCTIONS // --

--- Runs the tag system for the given Classes folder.
--- For each ModuleScript under classesFolder (including in subfolders), observes the tag
--- matching the module name, instantiates the class with the tagged instance, and calls
--- Destroy when the tag is removed or the instance is destroyed.
--- @param classesFolder Instance -- Folder containing ModuleScripts (name = tag name); may have category subfolders
--- @return () -> () -- Cleanup function that stops all tag observers
function TagRunner.run(classesFolder: Instance): () -> ()
	local cleanups = {} :: { () -> () }
	local seenNames = {} :: { [string]: boolean }
	for _, classModule in getTagModules(classesFolder) do
		if not seenNames[classModule.Name] then
			seenNames[classModule.Name] = true
			table.insert(cleanups, runTag(classModule))
		end
	end
	return function()
		for _, cleanup in cleanups do
			cleanup()
		end
	end
end

-- // MAIN // --
return TagRunner
