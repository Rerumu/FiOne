local env = getfenv(0)
local fio

local function wrap_func(fn)
	local bc = string.dump(fn)
	local state = fio.bc_to_state(bc)

	return fio.wrap_state(state, env)
end

fio = require('source')
-- fio = wrap_func(loadfile('source.lua'))() -- self running, uncomment to test

local sum = wrap_func(function(num)
	local ans = 0

	for i = 1, num do ans = ans + i end

	return ans
end)(100)

print(sum)
