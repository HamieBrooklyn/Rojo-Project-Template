local ServerScriptService = game:GetService("ServerScriptService")

local TABLE_KEYS = { Inventory = true, IslandExpansionSlots = true, IslandBuildings = true }

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

return function(_context, player, key: string, value: number)
	local ProfileServerService = getProfileServerService()
	if not ProfileServerService then
		return "ProfileServerService not available."
	end
	if TABLE_KEYS[key] then
		return "That key does not support set from command (use a numeric key)."
	end
	ProfileServerService:Set(player, key, value)
	return ("Set %s.%s = %s"):format(player.Name, key, tostring(value))
end
