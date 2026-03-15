-- // SERVICES // --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // DEPENDENCIES // --
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local RootUI = require(ReplicatedStorage.Shared.UI.App.RootUI)

-- // VARIABLES // --
local GuiClientMountingService = {}

-- // TYPES // --
export type GuiClientMountingService = typeof(GuiClientMountingService) & {}

-- CONSTANTS --

-- // PRIVATE FUNCTIONS // --

-- // PUBLIC FUNCTIONS // --
function GuiClientMountingService.Init(self: GuiClientMountingService): ()
	local container = Instance.new("ScreenGui")
	container.Name = "React"
	container.IgnoreGuiInset = true
	container.ResetOnSpawn = false
	container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	container.ClipToDeviceSafeArea = true
	container.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = ReactRoblox.createRoot(container)
	local app = React.createElement(RootUI)
	root:render(app)
end

-- // MAIN // --
return GuiClientMountingService :: GuiClientMountingService
