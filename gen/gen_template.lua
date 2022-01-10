--[[MOVE]] memory[inst.A] = memory[inst.B]

--[[LOADK]]
memory[inst.A] = inst.const

--[[LOADBOOL]]
memory[inst.A] = inst.B ~= 0

if inst.C ~= 0 then pc = pc + 1 end

--[[LOADNIL]]
for i = inst.A, inst.B do memory[i] = nil end

--[[GETUPVAL]]
local uv = upvals[inst.B]

memory[inst.A] = uv.store[uv.index]

--[[GETGLOBAL]]
memory[inst.A] = env[inst.const]

--[[GETTABLE]]
local index

if inst.is_KC then
	index = inst.const_C
else
	index = memory[inst.C]
end

memory[inst.A] = memory[inst.B][index]

--[[SETGLOBAL]]
env[inst.const] = memory[inst.A]

--[[SETUPVAL]]
local uv = upvals[inst.B]

uv.store[uv.index] = memory[inst.A]

--[[SETTABLE]]
local index, value

if inst.is_KB then
	index = inst.const_B
else
	index = memory[inst.B]
end

if inst.is_KC then
	value = inst.const_C
else
	value = memory[inst.C]
end

memory[inst.A][index] = value

--[[NEWTABLE]]
memory[inst.A] = {}

--[[SELF]]
local A = inst.A
local B = inst.B
local index

if inst.is_KC then
	index = inst.const_C
else
	index = memory[inst.C]
end

memory[A + 1] = memory[B]
memory[A] = memory[B][index]

--[[ADD]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

memory[inst.A] = lhs + rhs

--[[SUB]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

memory[inst.A] = lhs - rhs

--[[MUL]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

memory[inst.A] = lhs * rhs

--[[DIV]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

memory[inst.A] = lhs / rhs

--[[MOD]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

memory[inst.A] = lhs % rhs

--[[POW]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

memory[inst.A] = lhs ^ rhs

--[[UNM]]
memory[inst.A] = -memory[inst.B]

--[[NOT]]
memory[inst.A] = not memory[inst.B]

--[[LEN]]
memory[inst.A] = #memory[inst.B]

--[[CONCAT]]
local str = memory[inst.B]

for i = inst.B + 1, inst.C do str = str .. memory[i] end

memory[inst.A] = str

--[[JMP]]
pc = pc + inst.sBx

--[[EQ]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

if (lhs == rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

pc = pc + 1

--[[LT]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

if (lhs < rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

pc = pc + 1

--[[LE]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = memory[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = memory[inst.C]
end

if (lhs <= rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

pc = pc + 1

--[[TEST]]
if (not memory[inst.A]) ~= (inst.C ~= 0) then pc = pc + code[pc].sBx end
pc = pc + 1

--[[TESTSET]]
local A = inst.A
local B = inst.B

if (not memory[B]) ~= (inst.C ~= 0) then
	memory[A] = memory[B]
	pc = pc + code[pc].sBx
end
pc = pc + 1

--[[CALL]]
local A = inst.A
local B = inst.B
local C = inst.C
local params

if B == 0 then
	params = top_index - A
else
	params = B - 1
end

local ret_list = table.pack(memory[A](table.unpack(memory, A + 1, A + params)))
local ret_num = ret_list.n

if C == 0 then
	top_index = A + ret_num - 1
else
	ret_num = C - 1
end

table.move(ret_list, 1, ret_num, A, memory)

--[[TAILCALL]]
local A = inst.A
local B = inst.B
local params

if B == 0 then
	params = top_index - A
else
	params = B - 1
end

close_lua_upvalues(open_list, 0)

return memory[A](table.unpack(memory, A + 1, A + params))

--[[RETURN]]
local A = inst.A
local B = inst.B
local len

if B == 0 then
	len = top_index - A + 1
else
	len = B - 1
end

close_lua_upvalues(open_list, 0)

return table.unpack(memory, A, A + len - 1)

--[[FORLOOP]]
local A = inst.A
local step = memory[A + 2]
local index = memory[A] + step
local limit = memory[A + 1]
local loops

if step == math.abs(step) then
	loops = index <= limit
else
	loops = index >= limit
end

if loops then
	memory[inst.A] = index
	memory[inst.A + 3] = index
	pc = pc + inst.sBx
end

--[[FORPREP]]
local A = inst.A
local init, limit, step

init = assert(tonumber(memory[A]), '`for` initial value must be a number')
limit = assert(tonumber(memory[A + 1]), '`for` limit must be a number')
step = assert(tonumber(memory[A + 2]), '`for` step must be a number')

memory[A] = init - step
memory[A + 1] = limit
memory[A + 2] = step

pc = pc + inst.sBx

--[[TFORLOOP]]
local A = inst.A
local base = A + 3

local vals = {memory[A](memory[A + 1], memory[A + 2])}

table.move(vals, 1, inst.C, base, memory)

if memory[base] ~= nil then
	memory[A + 2] = memory[base]
	pc = pc + code[pc].sBx
end

pc = pc + 1

--[[SETLIST]]
local A = inst.A
local C = inst.C
local len = inst.B
local tab = memory[A]
local offset

if len == 0 then len = top_index - A end

if C == 0 then
	C = inst[pc].value
	pc = pc + 1
end

offset = (C - 1) * FIELDS_PER_FLUSH

table.move(memory, A + 1, A + len, offset + 1, tab)

--[[CLOSE]]
close_lua_upvalues(open_list, inst.A)

--[[CLOSURE]]
local sub = subs[inst.Bx + 1] -- offset for 1 based index
local nups = sub.num_upval
local uvlist

if nups ~= 0 then
	uvlist = {}

	for i = 1, nups do
		local pseudo = code[pc + i - 1]

		if pseudo.op == OPCODE_RM[0] then -- @MOVE
			uvlist[i - 1] = open_lua_upvalue(openupvs, pseudo.B, memory)
		elseif pseudo.op == OPCODE_RM[4] then -- @GETUPVAL
			uvlist[i - 1] = upvals[pseudo.B]
		end
	end

	pc = pc + nups
end

memory[inst.A] = wrap_lua_func(sub, env, uvlist)

--[[VARARG]]
local A = inst.A
local len = inst.B

if len == 0 then
	len = vararg.len
	top_index = A + len - 1
end

table.move(vararg.list, 1, len, A, memory)
