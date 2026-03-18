-- // SERVICES // --
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- // DEPENDENCIES // --
local Trove = require(ReplicatedStorage.Packages.Trove)

-- // VARIABLES // --
local Observers = {}

-- // PRIVATE FUNCTIONS // --

-- // PUBLIC FUNCTIONS // --
function Observers.observePlayers(callback: (player: Player) -> () -> ()): () -> ()
	local trove = Trove.new()
	local playerCleanupMethods = {} :: { [Player]: (exitReason: Enum.PlayerExitReason) -> () }
	local function added(player: Player)
		playerCleanupMethods[player] = callback(player)
	end
	for _, player in Players:GetPlayers() do
		added(player)
	end
	trove:Add(Players.PlayerAdded:Connect(added))
	trove:Add(Players.PlayerRemoving:Connect(function(a0: Player, a1: Enum.PlayerExitReason)
		local cleanup = playerCleanupMethods[a0]
		if cleanup then
			cleanup(a1)
			playerCleanupMethods[a0] = nil
		end
	end))
	return function()
		trove:Destroy()
	end
end

function Observers.observeCharacter(player: Player, callback: (char: Model) -> () -> ()): () -> ()
	local trove = Trove.new()
	local function added(char: Model)
		local charCleanup = callback(char)
		trove:Add(player.CharacterRemoving:Connect(function()
			charCleanup()
		end))
	end
	if player.Character then
		added(player.Character)
	end
	trove:Add(player.CharacterAdded:Connect(added))
	return function()
		trove:Destroy()
	end
end
function Observers.observeCharacters(callback: (player: Player, char: Model) -> () -> ()): () -> ()
	local trove = Trove.new()
	trove:Add(Observers.observePlayers(function(player: Player): () -> ()
		local obs = trove:Add(Observers.observeCharacter(player, function(char: Model): () -> ()
			local cleanup = callback(player, char)
			return cleanup
		end))
		return function()
			obs()
		end
	end))
	return function()
		trove:Destroy()
	end
end

function Observers.observeChildren(parent: Instance, callback: (child: Instance) -> () -> ()): () -> ()
	local trove = Trove.new()
	local childCleanupMethods = {} :: { [Instance]: () -> () }
	local function added(child: Instance)
		childCleanupMethods[child] = callback(child)
	end
	for _, child in parent:GetChildren() do
		added(child)
	end
	trove:Add(parent.ChildAdded:Connect(added))
	trove:Add(parent.ChildRemoved:Connect(function(a0: Instance)
		local cleanup = childCleanupMethods[a0]
		if cleanup then
			cleanup()
			childCleanupMethods[a0] = nil
		end
	end))
	return function()
		trove:Destroy()
	end
end
function Observers.observeDescendants(parent: Instance, callback: (descendant: Instance) -> () -> ()): () -> ()
	local trove = Trove.new()
	local descendantCleanupMethods = {} :: { [Instance]: () -> () }
	local function added(descendant: Instance)
		descendantCleanupMethods[descendant] = callback(descendant)
	end
	for _, descendant in parent:GetDescendants() do
		added(descendant)
	end
	trove:Add(parent.DescendantAdded:Connect(added))
	trove:Add(parent.DescendantRemoving:Connect(function(a0: Instance)
		local cleanup = descendantCleanupMethods[a0]
		if cleanup then
			cleanup()
			descendantCleanupMethods[a0] = nil
		end
	end))
	return function()
		trove:Destroy()
	end
end

function Observers.observeTag(tag: string, callback: (instance: Instance) -> () -> ()): () -> ()
	local trove = Trove.new()
	local taggedCleanupMethods = {} :: { [Instance]: () -> () }
	local function added(instance: Instance)
		taggedCleanupMethods[instance] = callback(instance)
	end
	for _, instance in CollectionService:GetTagged(tag) do
		added(instance)
	end
	trove:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(added))
	trove:Add(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(a0: Instance)
		local cleanup = taggedCleanupMethods[a0]
		if cleanup then
			cleanup()
			taggedCleanupMethods[a0] = nil
		end
	end))
	return function()
		trove:Destroy()
	end
end

function Observers.observeAttribute(instance: Instance, attribute: string, callback: (value: any) -> ()): () -> ()
	local trove = Trove.new()
	trove:Add(instance:GetAttributeChangedSignal(attribute):Connect(function()
		callback(instance:GetAttribute(attribute))
	end))
	callback(instance:GetAttribute(attribute))
	return function()
		trove:Destroy()
	end
end
function Observers.observeAllAttributes(instance: Instance, callback: (attribute: string, value: any) -> ()): () -> ()
	local trove = Trove.new()
	local attributesObserved = {} :: { string }
	local function added(attribute, startValue)
		if table.find(attributesObserved, attribute) then
			return
		end
		table.insert(attributesObserved, attribute)
		trove:Add(Observers.observeAttribute(instance, attribute, function(newValue: any)
			callback(attribute, newValue)
		end))
		callback(attribute, startValue)
	end
	for attribute, value in instance:GetAttributes() do
		added(attribute, value)
	end
	trove:Add(instance.AttributeChanged:Connect(function(a0: string)
		added(a0, instance:GetAttribute(a0))
	end))
	return function()
		trove:Destroy()
	end
end

-- // MAIN // --
return Observers
