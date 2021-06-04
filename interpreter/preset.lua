--[[MOVE]] stack[inst.A] = stack[inst.B]

--[[LOADK]]
stack[inst.A] = inst.const

--[[LOADBOOL]]
stack[inst.A] = inst.B ~= 0

if inst.C ~= 0 then pc = pc + 1 end

--[[LOADNIL]]
for i = inst.A, inst.B do stack[i] = nil end

--[[GETUPVAL]]
local uv = upvs[inst.B]

stack[inst.A] = uv.store[uv.index]

--[[GETGLOBAL]]
stack[inst.A] = env[inst.const]

--[[GETTABLE]]
local index

if inst.is_KC then
	index = inst.const_C
else
	index = stack[inst.C]
end

stack[inst.A] = stack[inst.B][index]

--[[SETGLOBAL]]
env[inst.const] = stack[inst.A]

--[[SETUPVAL]]
local uv = upvs[inst.B]

uv.store[uv.index] = stack[inst.A]

--[[SETTABLE]]
local index, value

if inst.is_KB then
	index = inst.const_B
else
	index = stack[inst.B]
end

if inst.is_KC then
	value = inst.const_C
else
	value = stack[inst.C]
end

stack[inst.A][index] = value

--[[NEWTABLE]]
stack[inst.A] = {}

--[[SELF]]
local A = inst.A
local B = inst.B
local index

if inst.is_KC then
	index = inst.const_C
else
	index = stack[inst.C]
end

stack[A + 1] = stack[B]
stack[A] = stack[B][index]

--[[ADD]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

stack[inst.A] = lhs + rhs

--[[SUB]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

stack[inst.A] = lhs - rhs

--[[MUL]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

stack[inst.A] = lhs * rhs

--[[DIV]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

stack[inst.A] = lhs / rhs

--[[MOD]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

stack[inst.A] = lhs % rhs

--[[POW]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

stack[inst.A] = lhs ^ rhs

--[[UNM]]
stack[inst.A] = -stack[inst.B]

--[[NOT]]
stack[inst.A] = not stack[inst.B]

--[[LEN]]
stack[inst.A] = #stack[inst.B]

--[[CONCAT]]
local str = stack[inst.B]

for i = inst.B + 1, inst.C do str = str .. stack[i] end

stack[inst.A] = str

--[[JMP]]
pc = pc + inst.sBx

--[[EQ]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

if (lhs == rhs) ~= (inst.A ~= 0) then pc = pc + 1 end

--[[LT]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

if (lhs < rhs) ~= (inst.A ~= 0) then pc = pc + 1 end

--[[LE]]
local lhs, rhs

if inst.is_KB then
	lhs = inst.const_B
else
	lhs = stack[inst.B]
end

if inst.is_KC then
	rhs = inst.const_C
else
	rhs = stack[inst.C]
end

if (lhs <= rhs) ~= (inst.A ~= 0) then pc = pc + 1 end

--[[TEST]]
if (not stack[inst.A]) == (inst.C ~= 0) then pc = pc + 1 end

--[[TESTSET]]
local A = inst.A
local B = inst.B

if (not stack[B]) == (inst.C ~= 0) then
	pc = pc + 1
else
	stack[A] = stack[B]
end

--[[CALL]]
local A = inst.A
local B = inst.B
local C = inst.C
local params
local sz_vals, l_vals

if B == 0 then
	params = stktop - A
else
	params = B - 1
end

sz_vals, l_vals = wrap_lua_variadic(stack[A](unpack(stack, A + 1, A + params)))

if C == 0 then
	stktop = A + sz_vals - 1
else
	sz_vals = C - 1
end

for i = 1, sz_vals do stack[A + i - 1] = l_vals[i] end

--[[TAILCALL]]
local A = inst.A
local B = inst.B
local params

if B == 0 then
	params = stktop - A
else
	params = B - 1
end

close_lua_upvalues(openupvs, 0)
return wrap_lua_variadic(stack[A](unpack(stack, A + 1, A + params)))

--[[RETURN]]
local A = inst.A
local B = inst.B
local vals = {}
local size

if B == 0 then
	size = stktop - A + 1
else
	size = B - 1
end

for i = 1, size do vals[i] = stack[A + i - 1] end

close_lua_upvalues(openupvs, 0)
return size, vals

--[[FORLOOP]]
local A = inst.A
local step = stack[A + 2]
local index = stack[A] + step
local limit = stack[A + 1]
local loops

if step == math.abs(step) then
	loops = index <= limit
else
	loops = index >= limit
end

if loops then
	stack[inst.A] = index
	stack[inst.A + 3] = index
	pc = pc + inst.sBx
end

--[[FORPREP]]
local A = inst.A
local init, limit, step

init = assert(tonumber(stack[A]), '`for` initial value must be a number')
limit = assert(tonumber(stack[A + 1]), '`for` limit must be a number')
step = assert(tonumber(stack[A + 2]), '`for` step must be a number')

stack[A] = init - step
stack[A + 1] = limit
stack[A + 2] = step

pc = pc + inst.sBx

--[[TFORLOOP]]
local A = inst.A
local func = stack[A]
local state = stack[A + 1]
local index = stack[A + 2]
local base = A + 3
local vals

stack[base + 2] = index
stack[base + 1] = state
stack[base] = func

vals = {func(state, index)}

for i = 1, inst.C do stack[base + i - 1] = vals[i] end

if stack[base] ~= nil then
	stack[A + 2] = stack[base]
else
	pc = pc + 1
end

--[[SETLIST]]
local A = inst.A
local C = inst.C
local size = inst.B
local tab = stack[A]
local offset

if size == 0 then size = stktop - A end

if C == 0 then
	C = inst[pc].value
	pc = pc + 1
end

offset = (C - 1) * FIELDS_PER_FLUSH

for i = 1, size do tab[i + offset] = stack[A + i] end

--[[CLOSE]]
close_lua_upvalues(openupvs, inst.A)

--[[CLOSURE]]
local sub = subs[inst.Bx + 1] -- offset for 1 based index
local nups = sub.numupvals
local uvlist

if nups ~= 0 then
	uvlist = {}

	for i = 1, nups do
		local pseudo = code[pc + i - 1]

		if pseudo.op == 0 then -- @MOVE
			uvlist[i - 1] = open_lua_upvalue(openupvs, pseudo.B, stack)
		elseif pseudo.op == 4 then -- @GETUPVAL
			uvlist[i - 1] = upvs[pseudo.B]
		end
	end

	pc = pc + nups
end

stack[inst.A] = wrap_lua_func(sub, env, uvlist)

--[[VARARG]]
local A = inst.A
local size = inst.B

if size == 0 then
	size = vargs.size
	stktop = A + size - 1
end

for i = 1, size do stack[A + i - 1] = vargs.list[i] end

