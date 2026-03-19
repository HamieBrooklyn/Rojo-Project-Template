local ServerScriptService = game:GetService("ServerScriptService")

local function getProfileServerService()
	local server = ServerScriptService:FindFirstChild("Server")
	if not server then
		return nil
	end
	local services = server:FindFirstChild("Services")
	if not services then
		return nil
	end
	local mod = services:FindFirstChild("ProfileServerService")
	if not mod then
		return nil
	end
	return require(mod)
end

return function(_context, player, key: string)
	local ProfileServerService = getProfileServerService()
	if not ProfileServerService then
		return "ProfileServerService not available."
	end
	local value = ProfileServerService:Get(player, key)
	if value == nil then
		return "nil"
	end
	if type(value) == "table" then
		return "table (use game to inspect)"
	end
	return tostring(value)
end
