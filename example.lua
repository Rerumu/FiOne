local env = getfenv(0)
local fio

local function wrap_func(fn) return fio.wrap_lua(fio.stm_lua(string.dump(fn)), env) end

fio = require('source')
-- fio = wrap_func(loadfile('source.lua'))() -- self running, uncomment to test

local sum = wrap_func(function(num)
	local ans = 0

	for i = 1, num do ans = ans + i end

	return ans
end)(100)

print(sum)
