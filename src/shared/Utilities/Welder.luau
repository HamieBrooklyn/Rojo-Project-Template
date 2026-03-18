local function weldToPart(part0: BasePart, part1: BasePart, animateable: boolean?, keepOffset: boolean?)
	if keepOffset == nil then
		keepOffset = true
	end
	local weld = if animateable then Instance.new("Motor6D") else Instance.new("Weld")
	if keepOffset then
		weld.C0 = part0.CFrame:Inverse() * part1.CFrame
	end
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Name = part1.Name .. "_Weld"
	weld.Parent = part0

	return weld
end

local function weldModel(model: Model, animateable: boolean?, keepOffset: boolean?)
	if keepOffset == nil then
		keepOffset = true
	end

	if not model.PrimaryPart then
		error("Model must have a PrimaryPart to weld to another part.")
	end

	local welds = {}
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and child ~= model.PrimaryPart then
			local weld = weldToPart(model.PrimaryPart, child, animateable, keepOffset)
			table.insert(welds, weld)
		end
	end

	return welds
end

return {
	weldToPart = weldToPart,
	weldModel = weldModel,
}
