--!strict
local uint64_t = require(script.Parent.uint64_t)
local diy_fp = {}

function diy_fp.create(val: number): (number, number, number)
	local sigt: number, expt: number = math.frexp(val)
	if expt < -1021 then
		-- subnormal numbers
		sigt *= 2 ^ (expt + 1021)
		expt = -1021
	end
	local sigt1: number, sigt0: number = math.modf(sigt * 0x200000)
	return sigt0 * 0x100000000, sigt1, expt + 52
end

-- AsNormalizedDiyFp
function diy_fp.create_normalized(val: number): (number, number, number)
	local sigt: number, expt: number = math.frexp(val)
	local sigt1: number, sigt0: number = math.modf(sigt * 0x100000000)
	return sigt0 * 0x100000000, sigt1, expt - 64
end

-- DiyFp::Normalize
function diy_fp.normalize(sigt0: number, sigt1: number, expt: number): (number, number, number)
	-- as per double-conversion/diy-fp.h:
	-- This method is mainly called for normalizing boundaries. In general,
	-- boundaries need to be shifted by 10 bits, and we optimize for this case.
	while bit32.band(sigt1, 0xFFC00000) == 0 do
		sigt0, sigt1 = uint64_t.sal(sigt0, sigt1, 10)
		expt -= 10
	end
	-- MSB of signficant
	while bit32.band(sigt1, 0x80000000) == 0 do
		sigt0, sigt1 = uint64_t.sal(sigt0, sigt1, 1)
		expt -= 1
	end
	return sigt0, sigt1, expt
end

function diy_fp.mul128(x0: number, x1: number, y0: number, y1: number): (number, number)
	-- as per double-conversion/diy-fp.h:
	-- Simply "emulates" a 128 bit multiplication.
	-- However: the resulting number only contains 64 bits. The least
	-- significant 64 bits are only used for rounding the most significant 64
	-- bits.
	local x0y1_0, x0y1_1 = uint64_t.mul32(x0, y1)
	local x1y0_0, x1y0_1 = uint64_t.mul32(x1, y0)

	local tmp = select(
		2,
		uint64_t.add(0x80000000, 0, uint64_t.add(x0y1_0, 0, uint64_t.add(x1y0_0, 0, select(2, uint64_t.mul32(x0, y0)))))
	)

	local tmp0, tmp1 = uint64_t.add(tmp, 0, uint64_t.add(x0y1_1, 0, x1y0_1))
	return uint64_t.add(tmp0, tmp1, uint64_t.mul32(x1, y1))
end

function diy_fp.to_double(sigt0: number, sigt1: number, expt: number): number
	return math.ldexp(sigt0 / 0x10000000000000 + sigt1 / 0x100000, expt + 52)
end

return diy_fp
