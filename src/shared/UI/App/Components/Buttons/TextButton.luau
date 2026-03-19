local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Theme = require(ReplicatedStorage.Shared.UI.App.Theme)
local useSpring = require(ReplicatedStorage.Shared.Utilities.React.useSpring)

local e = React.createElement

type TextButtonProps = {
	native: { Size: UDim2 } & { any },
	children: { React.Element<any> },
}

local function TextButton(props: TextButtonProps): ()
	local sizeSpringBinding, sizeSpring = useSpring(1, {
		tension = 500,
		friction = 10,
		start = true,
	})
	local size = props.native.Size or UDim2.fromScale(0, 0)
	props.native.Size = sizeSpringBinding:map(function(a0)
		return UDim2.fromScale(size.X.Scale * a0, size.Y.Scale * a0)
	end)

	return e(
		"TextButton",
		Sift.Dictionary.merge({
			FontFace = Theme.CONSTANTS.FONT,
			TextScaled = true,

			[React.Event.MouseEnter] = function()
				print("mouse enter")
				sizeSpring:setGoal(1.1)
			end,
			[React.Event.MouseLeave] = function()
				sizeSpring:setGoal(1)
			end,
			[React.Event.MouseButton1Down] = function()
				sizeSpring:setGoal(0.9)
			end,
			[React.Event.MouseButton1Up] = function()
				sizeSpring:setGoal(1)
			end,
		}, props.native),
		Sift.Dictionary.merge({}, props.children)
	)
end

return function(props: TextButtonProps)
	return e(TextButton, props)
end
