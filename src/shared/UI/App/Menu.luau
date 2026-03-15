local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local React = require(ReplicatedStorage.Packages.React)

local e = React.createElement

type MenuProps = {
	Text: string,
	Color: Color3,
}

local function Menu(props: MenuProps): ()
	local counter, setCounter = React.useState(0)

	local rot, setRot = React.useBinding(0)
	React.useEffect(function()
		local conn = RunService.Heartbeat:Connect(function(dt)
			setRot(rot:getValue() + dt * 360)
		end)

		return function()
			conn:Disconnect()
		end
	end, { rot })

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = props.Color,
	}, {
		Button = e("TextButton", {
			Text = "Pressed " .. counter .. " times",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.95),
			Size = UDim2.fromScale(0.2, 0.2),
			[React.Event.Activated] = function()
				setCounter(counter + 1)
			end,
		}),
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0.1, 0),
		}),
		UIStroke = e("UIStroke", {
			Thickness = 4,
		}),
		Text = e("TextLabel", {
			Size = UDim2.fromScale(1, 0.25),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			TextScaled = true,
			Text = props.Text,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = 0,
			TextStrokeTransparency = 1,
			BackgroundTransparency = 1,
			Rotation = rot,
		}),
	})
end

return function(props: MenuProps)
	local shown, setShown = React.useState(true)
	React.useEffect(function()
		local conn = UserInputService.InputBegan:Connect(function(a0: InputObject, a1: boolean)
			print(a0.KeyCode)
			if a0.KeyCode == Enum.KeyCode.C then
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
