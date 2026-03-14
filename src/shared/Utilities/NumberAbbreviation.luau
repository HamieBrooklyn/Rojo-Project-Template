-- A special number abreviation module. Script originaly by OMGitsmeokay, script turned into a module by 128Cores.

local abbreviator = {}

local suffixes = { "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N" } -- Abbreviation changes every additional 3 integer in a number

function abbreviator.en(value)
	if value == nil then
		return "0"
	end

	local negative = (tonumber(value) or 0) < 0

	if negative then
		value = -value
	end
	if not (tonumber(value)) or tonumber(value) <= 999 then
		return value
	end
	local str = value

	if value > 99_999_999 then
		for i = 1, #suffixes do
			if tonumber(value) < 10 ^ (i * 3) then
				str = math.floor(value / ((10 ^ ((i - 1) * 3)) / 100)) / 100 .. suffixes[i - 1]
				break
			end
		end
	else
		local formatted, k = value, nil
		while task.wait() do
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
			if k == 0 then
				break
			end
		end

		str = tostring(formatted)
	end

	if str and negative then
		str = "-" .. str
	end
	return str
end

return abbreviator
