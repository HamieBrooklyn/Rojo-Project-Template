local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Ripple = require(ReplicatedStorage.Packages.Ripple)

local function useSpring(initial: any, options: Ripple.SpringOptions): (React.Binding<any>, Ripple.Spring<any>)
	local binding, setBinding = React.createBinding(initial)
	local spring = Ripple.createSpring(binding:getValue(), options)
	spring:onChange(function(value, _deltaTime: number)
		setBinding(value)
	end)
	return binding, spring
end

return useSpring
