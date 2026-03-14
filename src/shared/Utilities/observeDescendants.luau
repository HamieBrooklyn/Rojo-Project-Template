local function observeDescendants(parent: Instance, callback: (instance: Instance) -> () -> ()): () -> ()
	local function added(instance: Instance)
		local cleanup = callback(instance)
		instance.Destroying:Once(cleanup)
	end
	local addedCon = parent.DescendantAdded:Connect(added)
	for _, v in parent:GetDescendants() do
		added(v)
	end
	return function()
		addedCon:Disconnect()
	end
end

return observeDescendants
