--!strict
-- Number formatting shared by HUD and billboards (blueprint U8: readable numbers).

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.short(n: number): string
	n = math.floor(n)
	if math.abs(n) < 1000 then
		return tostring(n)
	end
	local i = 1
	local value = n
	while math.abs(value) >= 1000 and i < #SUFFIXES do
		value /= 1000
		i += 1
	end
	local text = if math.abs(value) < 10 then string.format("%.2f", value) else string.format("%.1f", value)
	text = text:gsub("%.?0+$", "")
	return text .. SUFFIXES[i]
end

function Format.clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

return Format
