local opcode_map = {}

do
	local fp = io.open('preset.lua')
	local preset = fp:read('a')

	fp:close()

	local list = {}
	local index = 1

	while index do
		table.insert(list, index - 1)
		index = string.find(preset, '--[[', index + 1, true)
	end

	table.insert(list, #preset)

	for i = 1, #list - 1 do opcode_map[i - 1] = string.sub(preset, list[i], list[i + 1] - 1) end
end

local function midpoint(a, b) return a + (b - a) / 2 end

local function fmt_insert(buf, fmt, ...) table.insert(buf, string.format(fmt, ...)) end

local function gen_search_inner(buf, i, min, max)
	local lower = math.floor(midpoint(i, min))
	local higher = math.ceil(midpoint(i, max))
	local len = #buf + 1

	if lower ~= min then
		fmt_insert(buf, 'if op < %d then ', i)
		gen_search_inner(buf, lower, min, i)
		table.insert(buf, 'else')
	end

	if higher ~= max then
		fmt_insert(buf, 'if op > %d then ', i)
		gen_search_inner(buf, higher, i, max)
		table.insert(buf, 'else')
	end

	table.insert(buf, opcode_map[i])

	if len ~= #buf then table.insert(buf, ' end ') end
end

local function gen_search(min, max)
	local buf = {}
	local pivot = math.floor(midpoint(min, max))

	gen_search_inner(buf, pivot, min - 1, max + 1)

	return table.concat(buf)
end

local fp = io.open('opcodes.lua', 'wb')

fp:write(gen_search(0, 37))
fp:close()
