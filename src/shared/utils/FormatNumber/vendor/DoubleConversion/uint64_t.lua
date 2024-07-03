--!strict
-- Custom 64-bit unsigned integer data type for double_conversion
local uint64_t = {}
local UINT32_T_MAX: number = 0xFFFFFFFF

function uint64_t.add(x0: number, x1: number, y0: number, y1: number?): (number, number)
	x0 += y0
	if x0 > UINT32_T_MAX then
		x0 -= UINT32_T_MAX + 1
		x1 += 1
	end
	if y1 then
		x1 += y1
		if x1 > UINT32_T_MAX then
			x1 -= UINT32_T_MAX + 1
		end
	elseif x1 == UINT32_T_MAX + 1 then
		x1 = 0
	end
	return x0, x1
end

function uint64_t.sub(x0: number, x1: number, y0: number, y1: number?): (number, number)
	x0 -= y0
	if x0 < 0 then
		x0 += UINT32_T_MAX + 1
		x1 -= 1
	end
	if y1 then
		x1 -= y1
		if x1 < 0 then
			x1 += UINT32_T_MAX + 1
		end
	elseif x1 == -1 then
		x1 = UINT32_T_MAX + 1
	end
	return x0, x1
end

function uint64_t.sal(x0: number, x1: number, y: number): (number, number)
	if y < 0 then
		return bit32.rshift(x1, -32 - y) + bit32.lshift(x0, y), bit32.lshift(x1, y)
	end
	return bit32.lshift(x0, y), bit32.rshift(x0, 32 - y) + bit32.lshift(x1, y)
end

function uint64_t.mul32(x: number, y: number): (number, number)
	local a: number, b: number, c: number, d: number =
		bit32.rshift(x, 16), bit32.band(x, 0xFFFF), bit32.rshift(y, 16), bit32.band(y, 0xFFFF)
	local s0, s1 = uint64_t.add(a * d, 0, b * c)
	return uint64_t.add(b * d, a * c, uint64_t.sal(s0, s1, 16))
end

function uint64_t.mul(x0: number, x1: number, y0: number, y1: number): (number, number)
	local x1y0_0: number, x1y0_1: number = uint64_t.mul32(x1, y0)
	return uint64_t.add(0, (uint64_t.add(x1y0_0, x1y0_1, uint64_t.mul32(x0, y1))), uint64_t.mul32(x0, y0))
end

function uint64_t.compare(x0: number, x1: number, y0: number, y1: number): number
	return x1 == y1 and (x0 == y0 and 0 or (x0 < y0 and -1 or 1)) or (x1 < y1 and -1 or 1)
end

function uint64_t.to_double(x0: number, x1: number, twos: boolean): number
	if twos and x1 >= 0x80000000 then
		x0, x1 = uint64_t.add(bit32.bnot(x0), bit32.bnot(x1), 1)
		if x0 == 0 and x1 == 0 then
			return -0x8000000000000000
		end
		return -(x0 + x1 * 0x100000000)
	end
	return x0 + x1 * 0x100000000
end

function uint64_t.read(decimal, i: number, j: number): (number, number, number)
	local ret0, ret1 = 0, 0
	while i <= j and (ret1 < 0x19999999 or ret1 == 0x19999999 and ret0 <= 0x99999998) do
		ret0, ret1 = uint64_t.add(decimal[i], 0, uint64_t.mul(ret0, ret1, 10, 0))
		i += 1
	end
	return ret0, ret1, i
end

return uint64_t
