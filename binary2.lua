local low_fmt = 'if op < %i then %s else'
local high_fmt = 'if op > %i then %s else'

local function search(i, mn, mx)
	i = math.ceil(i)

	local low_num = i - (i - mn) / 2
	local high_num = i + (mx - i) / 2
	local low, high, pad = '', '', ''

	if mn + 1 ~= i then
		low = string.format(low_fmt, i, search(low_num, mn, i))
		pad = ' end '
	end

	if mx - 1 ~= i then
		high = string.format(high_fmt, i, search(high_num, i, mx))
		pad = ' end '
	end

	return low .. high .. '--[[' .. i .. ']]' .. pad
end

local function ps_search(n) return search(n / 2, -1, n + 1) end

-- helper to generate the binary search for instructions
local fp = io.open('opcodes.lua', 'wb')
fp:write(ps_search(37))
fp:close()
