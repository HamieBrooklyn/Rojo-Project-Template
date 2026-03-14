local function distributeRows(models, maxCellsPerRow)
	local totalUnits = #models
	local rows = {}

	if totalUnits == 0 then
		return rows
	end

	-- Build the row capacity pattern
	local capacities = {}
	if totalUnits <= maxCellsPerRow then
		-- just one row
		table.insert(capacities, totalUnits)
	else
		-- top row taper
		table.insert(capacities, 2)
		totalUnits -= 2

		-- middle rows
		while totalUnits > (2 + maxCellsPerRow) do
			table.insert(capacities, maxCellsPerRow)
			totalUnits -= maxCellsPerRow
		end

		-- last two rows
		if totalUnits > 2 then
			table.insert(capacities, maxCellsPerRow)
			table.insert(capacities, 2)
			totalUnits -= (maxCellsPerRow + 2)
		else
			-- if only <=2 left, just bottom taper
			table.insert(capacities, totalUnits)
			totalUnits = 0
		end
	end

	-- Fill rows with models
	local index = 1
	for row = 1, #capacities do
		rows[row] = {}
		for c = 1, capacities[row] do
			if index <= #models then
				table.insert(rows[row], models[index])
				index += 1
			end
		end
	end

	return rows
end

local function alignModelsInGrid(
	models: { Model },
	centerPosition: Vector3,
	props: {
		MarginX: number?, -- Horizontal spacing between models
		MarginZ: number?, -- Vertical spacing between rows
		MaxCellsPerRow: number?,
		FillDirection: string?,
	}
)
	props = props or {}
	local marginX = props.MarginX or 1
	local marginZ = props.MarginZ or 1
	local maxCellsPerRow = props.MaxCellsPerRow or 3
	local fillDirection = props.FillDirection or "Z"

	local rows = distributeRows(models, maxCellsPerRow)

	-- Calculate row dimensions
	local rowWidths = {}
	local rowDepths = {}

	for rowIndex, rowModels in ipairs(rows) do
		local totalWidth = 0
		local maxDepth = 0
		for _, model in ipairs(rowModels) do
			local size = model:GetExtentsSize()
			if fillDirection == "X" then
				totalWidth += size.X + marginX
				maxDepth = math.max(maxDepth, size.Z)
			else
				totalWidth += size.Z + marginZ
				maxDepth = math.max(maxDepth, size.X)
			end
		end
		rowWidths[rowIndex] = totalWidth - (fillDirection == "X" and marginX or marginZ)
		rowDepths[rowIndex] = maxDepth
	end

	-- Calculate total grid depth for centering
	local totalGridDepth = 0
	for _, depth in ipairs(rowDepths) do
		totalGridDepth += depth + (fillDirection == "X" and marginZ or marginX)
	end
	totalGridDepth -= (fillDirection == "X" and marginZ or marginX)

	-- Position models
	local currentZ = centerPosition.Z - (fillDirection == "X" and totalGridDepth or 0) / 2
	local currentX = centerPosition.X - (fillDirection == "Z" and totalGridDepth or 0) / 2

	for rowIndex, rowModels in ipairs(rows) do
		local rowWidth = rowWidths[rowIndex]
		local rowDepth = rowDepths[rowIndex]

		local localX = centerPosition.X - (fillDirection == "X" and rowWidth or rowDepth) / 2
		local localZ = centerPosition.Z - (fillDirection == "Z" and rowWidth or rowDepth) / 2

		for _, model in ipairs(rowModels) do
			local size = model:GetExtentsSize()
			local posX, posZ

			if fillDirection == "X" then
				posX = localX + size.X / 2
				posZ = currentZ + rowDepth / 2
				localX += size.X + marginX
			else
				posX = currentX + rowDepth / 2
				posZ = localZ + size.Z / 2
				localZ += size.Z + marginZ
			end

			local posY = centerPosition.Y + size.Y / 2
			local finalPosition = Vector3.new(posX, posY, posZ)
			model:PivotTo(CFrame.new(finalPosition))
		end

		if fillDirection == "X" then
			currentZ += rowDepth + marginZ
		else
			currentX += rowDepth + marginX
		end
	end
end

return alignModelsInGrid
