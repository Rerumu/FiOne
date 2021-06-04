--[[0 MOVE]] stack[inst.A] = stack[inst.B]

--[[1 LOADK]]
stack[inst.A] = inst.const

--[[2 LOADBOOL]]
stack[inst.A] = inst.B ~= 0

if inst.C ~= 0 then pc = pc + 1 end

--[[3 LOADNIL]]
for i = inst.A, inst.B do stack[i] = nil end

--[[4 GETUPVAL]]
local uv = upvs[inst.B]

stack[inst.A] = uv.store[uv.index]

--[[5 GETGLOBAL]]
stack[inst.A] = env[inst.const]

--[[6 GETTABLE]]
local index

if inst.is_KC then
	index = inst.const_C
else
	index = stack[inst.C]
end

stack[inst.A] = stack[inst.B][index]

--[[7 SETGLOBAL]]
env[inst.const] = stack[inst.A]

--[[8 SETUPVAL]]
local uv = upvs[inst.B]

uv.store[uv.index] = stack[inst.A]

--[[9 SETTABLE]]
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

--[[10 NEWTABLE]]
stack[inst.A] = {}

--[[11 SELF]]
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

--[[12 ADD]]
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

--[[13 SUB]]
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

--[[14 MUL]]
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

--[[15 DIV]]
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

--[[16 MOD]]
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

--[[17 POW]]
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

--[[18 UNM]]
stack[inst.A] = -stack[inst.B]

--[[19 NOT]]
stack[inst.A] = not stack[inst.B]

--[[20 LEN]]
stack[inst.A] = #stack[inst.B]

--[[21 CONCAT]]
local str = stack[inst.B]

for i = inst.B + 1, inst.C do str = str .. stack[i] end

stack[inst.A] = str

--[[22 JMP]]
pc = pc + inst.sBx

--[[23 EQ]]
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

--[[24 LT]]
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

--[[25 LE]]
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

--[[26 TEST]]
if (not stack[inst.A]) == (inst.C ~= 0) then pc = pc + 1 end

--[[27 TESTSET]]
local A = inst.A
local B = inst.B

if (not stack[B]) == (inst.C ~= 0) then
	pc = pc + 1
else
	stack[A] = stack[B]
end

--[[28 CALL]]
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

--[[29 TAILCALL]]
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

--[[30 RETURN]]
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

--[[31 FORLOOP]]
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

--[[32 FORPREP]]
local A = inst.A
local init, limit, step

init = assert(tonumber(stack[A]), '`for` initial value must be a number')
limit = assert(tonumber(stack[A + 1]), '`for` limit must be a number')
step = assert(tonumber(stack[A + 2]), '`for` step must be a number')

stack[A] = init - step
stack[A + 1] = limit
stack[A + 2] = step

pc = pc + inst.sBx

--[[33 TFORLOOP]]
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

--[[34 SETLIST]]
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

--[[35 CLOSE]]
close_lua_upvalues(openupvs, inst.A)

--[[36 CLOSURE]]
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

--[[37 VARARG]]
local A = inst.A
local size = inst.B

if size == 0 then
	size = vargs.size
	stktop = A + size - 1
end

for i = 1, size do stack[A + i - 1] = vargs.list[i] end

