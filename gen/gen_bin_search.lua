local opcode_map = {}

local OPCODE_RM = {
	-- level 1
	[18] = 22, -- JMP
	[8] = 31, -- FORLOOP
	[28] = 33, -- TFORLOOP
	-- level 2
	[3] = 0, -- MOVE
	[13] = 1, -- LOADK
	[23] = 2, -- LOADBOOL
	[33] = 26, -- TEST
	-- level 3
	[1] = 12, -- ADD
	[6] = 13, -- SUB
	[10] = 14, -- MUL
	[16] = 15, -- DIV
	[20] = 16, -- MOD
	[26] = 17, -- POW
	[30] = 18, -- UNM
	[36] = 19, -- NOT
	-- level 4
	[0] = 3, -- LOADNIL
	[2] = 4, -- GETUPVAL
	[4] = 5, -- GETGLOBAL
	[7] = 6, -- GETTABLE
	[9] = 7, -- SETGLOBAL
	[12] = 8, -- SETUPVAL
	[14] = 9, -- SETTABLE
	[17] = 10, -- NEWTABLE
	[19] = 20, -- LEN
	[22] = 21, -- CONCAT
	[24] = 23, -- EQ
	[27] = 24, -- LT
	[29] = 25, -- LE
	[32] = 27, -- TESTSET
	[34] = 32, -- FORPREP
	[37] = 34, -- SETLIST
	-- level 5
	[5] = 11, -- SELF
	[11] = 28, -- CALL
	[15] = 29, -- TAILCALL
	[21] = 30, -- RETURN
	[25] = 35, -- CLOSE
	[31] = 36, -- CLOSURE
	[35] = 37, -- VARARG
}

do
	local fp = io.open('gen_template.lua')
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

	table.insert(buf, opcode_map[OPCODE_RM[i]])

	if len ~= #buf then table.insert(buf, ' end ') end
end

local function gen_search(min, max)
	local buf = {}
	local pivot = math.floor(midpoint(min, max))

	gen_search_inner(buf, pivot, min - 1, max + 1)

	return table.concat(buf)
end

local fp = io.open('bin_tree.lua')

fp:write(gen_search(0, 37))
fp:close()
