local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Menu = require(script.Parent.Menu)
local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

local function RootUI(): ()
	return e(Menu, {
		Text = "Menu",
		Color = Color3.new(1, 0, 0),
	})
end

return RootUI
