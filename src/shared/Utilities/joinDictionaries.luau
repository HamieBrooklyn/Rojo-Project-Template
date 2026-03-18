local function joinDictionaries(overwrite: boolean, mainDict: { [any]: any }, ...: { [any]: any }?)
	for _, dict in { ... } do
		for i, v in dict do
			if mainDict[i] and not overwrite then
				continue
			end
			mainDict[i] = v
		end
	end
	return mainDict
end

return joinDictionaries
