-- Abbreviates large numbers for display (e.g. 1000 -> "1K", 100000 -> "100K", 1000000 -> "1M").
local function formatNumberAbbrev(n: number): string
	n = math.floor(tonumber(n) or 0)
	if n < 0 then
		return "-" .. formatNumberAbbrev(-n)
	end
	-- n >= 0 below
	if n >= 1_000_000 then
		local m = n / 1_000_000
		return (m == math.floor(m)) and (m .. "M") or (string.format("%.1fM", m))
	end
	if n >= 1_000 then
		local k = n / 1_000
		return (k == math.floor(k)) and (k .. "K") or (string.format("%.1fK", k))
	end
	return tostring(n)
end

return formatNumberAbbrev
