--!strict
local uint64_t = require(script.Parent.uint64_t)
local bignum = {}
local FIVE_POW: { number } = {
	5,
	25,
	125,
	625,
	3125,
	15625,
	78125,
	390625,
	1953125,
	9765625,
	48828125,
	244140625,
}
export type BigNum = { expt: number, [number]: number }

function bignum.sal(bnum: BigNum, disp: number)
	local local_shift = disp % 28
	bnum.expt += (disp - local_shift) / 28

	local c = 0
	for i, v in ipairs(bnum) do
		bnum[i], c = bit32.band(c + bit32.lshift(v, local_shift), 0xFFFFFFF), bit32.rshift(v, 28 - local_shift)
	end
	if c ~= 0 then
		table.insert(bnum, c)
	end
end

function bignum.clamp(bnum: BigNum): ()
	while bnum[#bnum] == 0 do
		table.remove(bnum)
	end
end

function bignum.align(bnum: BigNum, other: BigNum): ()
	local zero_digits = bnum.expt - other.expt
	for _i = 1, zero_digits do
		table.insert(bnum, 1, 0)
	end
	bnum.expt -= math.max(zero_digits, 0)
end

function bignum.assign_uint64_t(bnum: BigNum, x0: number, x1: number): ()
	bnum[1], bnum[2], bnum[3] =
		bit32.band(x0, 0xFFFFFFF), bit32.rshift(x0, 28) + bit32.lshift(bit32.band(x1, 0xFFFFFF), 4), bit32.rshift(x1, 24)
	bignum.clamp(bnum)
end

function bignum.square(bnum: BigNum): ()
	local accumulator0, accumulator1 = 0, 0
	local bnum_n = #bnum
	for i = 1, bnum_n do
		bnum[bnum_n + i] = bnum[i]
	end
	for i = 1, bnum_n do
		local bnum_index0 = i
		local bnum_index1 = 1
		while bnum_index0 > 0 do
			accumulator0, accumulator1 = uint64_t.add(
				accumulator0,
				accumulator1,
				uint64_t.mul32(bnum[bnum_n + bnum_index0], bnum[bnum_n + bnum_index1])
			)
			bnum_index0 -= 1
			bnum_index1 += 1
		end

		bnum[i] = bit32.band(accumulator0, 0xFFFFFFF)
		accumulator0, accumulator1 = uint64_t.sal(accumulator0, accumulator1, -28)
	end
	for i = bnum_n + 1, bnum_n * 2 do
		local bnum_index0 = bnum_n
		local bnum_index1 = i - bnum_index0 + 1
		while bnum_index1 <= bnum_n do
			accumulator0, accumulator1 = uint64_t.add(
				accumulator0,
				accumulator1,
				uint64_t.mul32(bnum[bnum_n + bnum_index0], bnum[bnum_n + bnum_index1])
			)
			bnum_index0 -= 1
			bnum_index1 += 1
		end
		bnum[i] = bit32.band(accumulator0, 0xFFFFFFF)
		accumulator0, accumulator1 = uint64_t.sal(accumulator0, accumulator1, -28)
	end

	bnum.expt *= 2
	bignum.clamp(bnum)
end

function bignum.add(bnum: BigNum, other: BigNum): ()
	bignum.align(bnum, other)

	local offset = other.expt - bnum.expt
	local carry = 0
	local other_n = #other
	local i = 1
	while i <= other_n or carry ~= 0 do
		local diff = (bnum[i + offset] or 0) + (other[i] or 0) + carry
		bnum[i + offset] = bit32.band(diff, 0xFFFFFFF)
		carry = bit32.rshift(diff, 28)
		i += 1
	end

	bignum.clamp(bnum)
end

function bignum.sub(bnum: BigNum, other: BigNum): ()
	bignum.align(bnum, other)

	local offset = other.expt - bnum.expt
	local carry = 0
	local other_n = #other
	local i = 1
	while i <= other_n or carry ~= 0 do
		local diff = bnum[i + offset] - (other[i] or 0) - carry
		bnum[i + offset] = bit32.band(diff, 0xFFFFFFF)
		carry = bit32.rshift(diff, 31)
		i += 1
	end

	bignum.clamp(bnum)
end

function bignum.sub_times(bnum: BigNum, other: BigNum, factor: number): ()
	if factor < 3 then
		for _ = 1, factor do
			bignum.sub(bnum, other)
		end
		return
	end
	local burrow = 0
	local expt_diff = other.expt - bnum.expt
	local other_n = #other
	for i = 1, other_n do
		local prod0, prod1 = uint64_t.mul32(factor, other[i])
		local rem0, rem1 = uint64_t.add(prod0, prod1, burrow)
		local diff = bnum[i + expt_diff] - bit32.band(rem0, 0xFFFFFFF)
		bnum[i + expt_diff] = bit32.band(diff, 0xFFFFFFF)
		burrow = uint64_t.add(bit32.rshift(diff, 31), 0, uint64_t.sal(rem0, rem1, -28))
	end
	for i = other_n + expt_diff + 1, #bnum do
		if burrow == 0 then
			return
		end
		local diff = bnum[i] - burrow
		bnum[i] = bit32.band(diff, 0xFFFFFFF)
		burrow = bit32.rshift(diff, 31)
	end
	bignum.clamp(bnum)
end

function bignum.mul_uint32_t(bnum: BigNum, factor: number)
	local c0, c1 = 0, 0
	for i, bigit in ipairs(bnum) do
		local prod0, prod1 = uint64_t.add(c0, c1, uint64_t.mul32(factor, bigit))
		bnum[i] = bit32.band(prod0, 0xFFFFFFF)
		c0, c1 = uint64_t.sal(prod0, prod1, -28)
	end
	while c0 ~= 0 or c1 ~= 0 do
		table.insert(bnum, bit32.band(c0, 0xFFFFFFF))
		c0, c1 = uint64_t.sal(c0, c1, -28)
	end
end

function bignum.mul_uint64_t(bnum: BigNum, factor0: number, factor1: number)
	local c0, c1 = 0, 0
	for i, bigit in ipairs(bnum) do
		local prod_lo0, prod_lo1 = uint64_t.mul32(factor0, bigit)
		local prod_hi0, prod_hi1 = uint64_t.mul32(factor1, bigit)
		local tmp0, tmp1 = uint64_t.add(bit32.band(c0, 0xFFFFFFF), 0, prod_lo0, prod_lo1)
		bnum[i] = bit32.band(tmp0, 0xFFFFFFF)
		c0, c1 = uint64_t.sal(c0, c1, -28)
		c0, c1 = uint64_t.add(c0, c1, uint64_t.sal(tmp0, tmp1, -28))
		c0, c1 = uint64_t.add(c0, c1, uint64_t.sal(prod_hi0, prod_hi1, 4))
	end
	while c0 ~= 0 or c1 ~= 0 do
		table.insert(bnum, bit32.band(c0, 0xFFFFFFF))
		c0, c1 = uint64_t.sal(c0, c1, -28)
	end
end

function bignum.from_power(base: number, pow_expt: number)
	if pow_expt == 0 then
		return { expt = 0, 1 }
	end
	local shifts = 0
	while bit32.band(base, 1) == 0 do
		base = bit32.rshift(base, 1)
		shifts += 1
	end
	local bit_size = 0
	local tmp_base = base
	while tmp_base ~= 0 do
		tmp_base = bit32.rshift(tmp_base, 1)
		bit_size += 1
	end
	local final_size = bit_size * pow_expt
	local ret = table.create(final_size / 28 + 2)
	ret.expt = 0

	-- Left to Right exponentiation
	local mask = 1
	while pow_expt >= mask do
		mask *= 2
	end

	-- As per double-conversion/bignum
	-- The mask is now pointing to the bit above the most significant 1-bit of
	-- power_exponent.
	-- Get rid of first 1-bit
	mask = bit32.rshift(mask, 2)
	local this_val0, this_val1 = base, 0

	local delayed_mult = false
	while mask ~= 0 and this_val1 == 0 do
		this_val0, this_val1 = uint64_t.mul(this_val0, this_val1, this_val0, this_val1)
		if bit32.band(pow_expt, mask) ~= 0 then
			local base_bits_mask0, base_bits_mask1 = uint64_t.sal(1, 0, 64 - bit_size)
			base_bits_mask0, base_bits_mask1 = uint64_t.sub(base_bits_mask0, base_bits_mask1, 1)
			if
				bit32.band(this_val0, bit32.bnot(base_bits_mask0)) == 0
				and bit32.band(this_val1, bit32.bnot(base_bits_mask1)) == 0
			then
				this_val0, this_val1 = uint64_t.mul(this_val0, this_val1, base, 0)
			else
				delayed_mult = true
			end
		end
		mask = bit32.rshift(mask, 1)
	end

	bignum.assign_uint64_t(ret, this_val0, this_val1)
	if delayed_mult then
		bignum.mul_uint32_t(ret, base)
	end

	while mask ~= 0 do
		bignum.square(ret)
		if bit32.band(pow_expt, mask) ~= 0 then
			bignum.mul_uint32_t(ret, base)
		end
		mask = bit32.rshift(mask, 1)
	end

	bignum.sal(ret, shifts * pow_expt)
	return ret
end

function bignum.compare(a: BigNum, b: BigNum): number
	local len_a, len_b = #a + a.expt, #b + b.expt
	if len_a < len_b then
		return -1
	elseif len_a > len_b then
		return 1
	end
	for i = len_a, math.min(a.expt, b.expt) + 1, -1 do
		local a_i, b_i = a[i] or 0, b[i] or 0
		if a_i < b_i then
			return -1
		elseif a_i > b_i then
			return 1
		end
	end
	return 0
end

function bignum.plus_compare(a: BigNum, b: BigNum, c: BigNum): number
	local len_a, len_b, len_c = #a + a.expt, #b + b.expt, #c + c.expt
	if len_a < len_b then
		len_a, len_b = len_b, len_a
		a, b = b, a
	end
	if len_a + 1 < len_c then
		return -1
	end
	if len_a > len_c then
		return 1
	end
	if a.expt >= len_b and len_a < len_c then
		return -1
	end

	local burrow = 0
	local min_expt = math.min(a.expt, b.expt, c.expt)
	for i = len_c, min_expt + 1, -1 do
		local chunk_a = a[i - a.expt] or 0
		local chunk_b = b[i - b.expt] or 0
		local chunk_c = c[i - c.expt] or 0
		local sum = chunk_a + chunk_b
		if sum > chunk_c + burrow then
			return 1
		else
			burrow = chunk_c + burrow - sum
			if burrow > 1 then
				return -1
			end
			burrow = bit32.lshift(burrow, 28)
		end
	end
	if burrow == 0 then
		return 0
	end
	return -1
end

function bignum.divmod(bnum: BigNum, other: BigNum): number
	local len, len_other = #bnum + bnum.expt, #other + other.expt
	if len < len_other then
		return 0
	end

	bignum.align(bnum, other)

	local bnum_n = #bnum
	local ret = 0
	while len > len_other do
		ret += bnum[bnum_n]
		bignum.sub_times(bnum, other, bnum[bnum_n])
		bnum_n = #bnum
		len = bnum_n + bnum.expt
	end

	local this_i = bnum[bnum_n]
	local other_i = other[#other]

	if not other[2] then
		-- shortcut for easy and common case
		-- (actually truncate divison but I doubt negative will be
		-- one of the input)
		local quotient = math.floor(this_i / other_i)
		bnum[bnum_n] = this_i - other_i * quotient
		bignum.clamp(bnum)
		return ret + quotient
	end

	-- (actually truncate divison but I doubt negative will be one of the input)
	local div_est = math.floor(this_i / (other_i + 1))
	ret += div_est
	bignum.sub_times(bnum, other, div_est)

	if other_i * (div_est + 1) > this_i then
		return ret
	end

	while bignum.compare(other, bnum) <= 0 do
		bignum.sub(bnum, other)
		ret += 1
	end
	return ret
end

function bignum.mult_pow10(bnum: BigNum, expt: number)
	if expt == 0 then
		return
	end
	local rem_expt = expt
	while rem_expt >= 27 do
		rem_expt -= 27
		bignum.mul_uint64_t(bnum, 0xFA10079D, 0x6765C793)
	end
	while rem_expt >= 13 do
		rem_expt -= 13
		bignum.mul_uint32_t(bnum, 0x48C27395)
	end
	if rem_expt > 0 then
		bignum.mul_uint32_t(bnum, FIVE_POW[rem_expt])
	end
	bignum.sal(bnum, expt)
end

function bignum.assign_decimal(bnum: BigNum, decimal: { number }, len: number)
	local pos = 1
	while pos > 19 do
		local digits_bnum = {}
		digits_bnum.expt = 0
		pos += 19
		len -= 19
		bignum.mult_pow10(bnum, 19)
		local read0, read1 = uint64_t.read(decimal, pos, pos + 18)
		bignum.assign_uint64_t(digits_bnum, read0, read1)
		bignum.add(bnum, digits_bnum)
	end
	local digits_bnum = {}
	local read0, read1 = uint64_t.read(decimal, pos, pos + len - 1)
	digits_bnum.expt = 0
	bignum.mult_pow10(bnum, len)
	bignum.assign_uint64_t(digits_bnum, read0, read1)
	bignum.add(bnum, digits_bnum)
	bignum.clamp(bnum)
end

return bignum
