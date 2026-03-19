local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.React)
local useSpring = require(ReplicatedStorage.Shared.Utilities.React.useSpring)

local e = React.createElement

type MenuProps = {
	ToggleKeybind: Enum.KeyCode,
	Size: UDim2,
	children: { React.Element<any> },
}

local function Menu(props: MenuProps): ()
	local rot, setRot = React.useBinding(0)
	React.useEffect(function()
		local conn = RunService.Heartbeat:Connect(function(dt)
			setRot(rot:getValue() + dt * 360)
		end)

		return function()
			conn:Disconnect()
		end
	end, { rot })

	local binding, sizeSpring = useSpring(UDim2.fromScale(0, 0), {
		tension = 170,
		friction = 15,
		start = true,
	})
	sizeSpring:setGoal(props.Size)

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = binding:map(function(a0: UDim2)
			return a0
		end),
		BackgroundTransparency = 1,
	}, props.children)
end

return function(props: MenuProps)
	local shown, setShown = React.useState(true)
	React.useEffect(function()
		local conn = UserInputService.InputBegan:Connect(function(a0: InputObject, a1: boolean)
			if a0.KeyCode == props.ToggleKeybind then
				setShown(not shown)
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, { shown })

	if shown then
		return e(Menu, props)
	else
		return nil
	end
end
