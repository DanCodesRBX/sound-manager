--!strict

local RANDOM = Random.new()

local function jitter(center: number, spread: number?): number
	local usedSpread = spread or 0.5 * center

	return center - 0.5 * usedSpread + RANDOM:NextNumber() * usedSpread
end

return jitter