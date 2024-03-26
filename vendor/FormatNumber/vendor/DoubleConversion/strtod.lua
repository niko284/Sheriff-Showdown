--!strict
local uint64_t = require(script.Parent.uint64_t)
local diy_fp = require(script.Parent.diy_fp)
local bignum = require(script.Parent.bignum)
local cached_power = require(script.Parent.cached_power)
local exact_power_of_ten: { number } = {
	[0] = 1, -- 10^0
	10,
	100,
	1000,
	10000,
	100000,
	1000000,
	10000000,
	100000000,
	1000000000,
	10000000000, -- 10^10
	100000000000,
	1000000000000,
	10000000000000,
	100000000000000,
	1000000000000000,
	10000000000000000,
	100000000000000000,
	1000000000000000000,
	10000000000000000000,
	100000000000000000000, -- 10^20
	1000000000000000000000,
	-- 10^22 = 0x21e19e0c9bab2400000 = 0x878678326eac9 * 2^22
	10000000000000000000000,
}

local function adjust_power_of_ten(expt: number): (number, number)
	-- hardcoded because Google's double conversion also hardcode this
	if expt == 1 then
		return 0xA0000000, -60
	elseif expt == 2 then
		return 0xC8000000, -57
	elseif expt == 3 then
		return 0xFA000000, -54
	elseif expt == 4 then
		return 0x9C400000, -50
	elseif expt == 5 then
		return 0xC3500000, -47
	elseif expt == 6 then
		return 0xF4240000, -44
	elseif expt == 7 then
		return 0x98968000, -40
	end
	-- unreachable
	error("unreachable", 0)
end

local function significand_size_for_order_of_magnitude(order: number): number
	if order >= -1021 then
		return 53
	elseif order <= -1074 then
		return 0
	end
	return order + 1074
end

local function read_diy_fp(trimmed: { number }, len: number): (number, number, number)
	local sigt0, sigt1, read_digits = uint64_t.read(trimmed, 1, len)
	if len ~= read_digits - 1 and trimmed[read_digits] >= 5 then
		-- round the significand
		sigt0, sigt1 = uint64_t.add(sigt0, sigt1, 1)
	end
	return sigt0, sigt1, len - (read_digits - 1)
end

local function double_strtod(trimmed: { number }, len: number, expt: number): number?
	if len <= 15 then
		if expt < 0 and -expt < 23 then
			local read0, read1 = uint64_t.read(trimmed, 1, len)
			return uint64_t.to_double(read0, read1, false) / exact_power_of_ten[-expt]
		end
		if 0 <= expt and expt < 23 then
			local read0, read1 = uint64_t.read(trimmed, 1, len)
			return uint64_t.to_double(read0, read1, false) * exact_power_of_ten[expt]
		end
		local remaining_digits = 15 - len
		if 0 < expt and expt - remaining_digits < 23 then
			local read0, read1 = uint64_t.read(trimmed, 1, len)
			return uint64_t.to_double(read0, read1, false)
				* exact_power_of_ten[remaining_digits]
				* exact_power_of_ten[expt - remaining_digits]
		end
	end
	return nil
end

local function diy_fp_strtod(trimmed: { number }, len: number, expt: number): (boolean, number)
	local input_expt = 0
	local input_sigt0, input_sigt1, rem_decimals = read_diy_fp(trimmed, len)
	expt += rem_decimals
	local err0, err1 = rem_decimals == 0 and 0 or 4, 0

	input_sigt0, input_sigt1, input_expt = diy_fp.normalize(input_sigt0, input_sigt1, input_expt)
	err0, err1 = uint64_t.sal(err0, err1, 0 - input_expt)

	if expt < -348 then
		return true, 0
	end
	local cached_power_sigt0, cached_power_sigt1, cached_power_expt, cached_decimal_expt = cached_power.for_decimal_expt(expt)

	if cached_decimal_expt ~= expt then
		local adjust_expt = expt - cached_decimal_expt
		local adjust_power_sigt1, _adjust_expt = adjust_power_of_ten(adjust_expt)
		input_sigt0, input_sigt1 = diy_fp.mul128(input_sigt0, input_sigt1, 0, adjust_power_sigt1)
		input_expt += adjust_expt + 64
		if 19 - len < adjust_expt then
			err0, err1 = uint64_t.add(err0, err1, 4)
		end
	end

	input_sigt0, input_sigt1 = diy_fp.mul128(input_sigt0, input_sigt1, cached_power_sigt0, cached_power_sigt1)
	input_expt += cached_power_expt + 64

	err0, err1 = uint64_t.add(err0, err1, 8 + (err0 == 0 and err1 == 0 and 0 or 1))

	local old_e = input_expt
	input_sigt0, input_sigt1, input_expt = diy_fp.normalize(input_sigt0, input_sigt1, input_expt)
	err0, err1 = uint64_t.sal(err0, err1, old_e - input_expt)

	local precision_digits_count = 64 - significand_size_for_order_of_magnitude(64 + input_expt)
	if precision_digits_count >= 61 then
		-- for very small subnormals
		-- shift everything to the right
		local shift_amount = precision_digits_count - 62
		input_sigt0, input_sigt1 = uint64_t.sal(input_sigt0, input_sigt1, -shift_amount)
		input_expt += shift_amount
		err0, err1 = uint64_t.add(9, 0, uint64_t.sal(err0, err1, shift_amount))
		precision_digits_count -= shift_amount
	end

	local precision_bits_mask0, precision_bits_mask1 = uint64_t.sal(1, 0, precision_digits_count)
	precision_bits_mask0, precision_bits_mask1 = uint64_t.sub(precision_bits_mask0, precision_bits_mask1, 1)
	local precision_bits0, precision_bits1 =
		bit32.band(input_sigt0, precision_bits_mask0), bit32.band(input_sigt1, precision_bits_mask1)
	local half_way0, half_way1 = uint64_t.sal(1, 0, precision_digits_count - 1)
	precision_bits0, precision_bits1 = uint64_t.sal(precision_bits0, precision_bits1, 3)
	half_way0, half_way1 = uint64_t.sal(half_way0, half_way1, 3)
	local rounded_input_sigt0, rounded_input_sigt1 = uint64_t.sal(input_sigt0, input_sigt1, -precision_digits_count)
	local rounded_input_expt = input_expt + precision_digits_count
	if uint64_t.compare(precision_bits0, precision_bits1, uint64_t.add(half_way0, half_way1, err0, err1)) >= 0 then
		rounded_input_sigt0, rounded_input_sigt1 = uint64_t.add(rounded_input_sigt0, rounded_input_sigt1, 1)
	end

	return uint64_t.compare(precision_bits0, precision_bits1, uint64_t.sub(half_way0, half_way1, err0, err1)) <= 0
		or uint64_t.compare(precision_bits0, precision_bits1, uint64_t.add(half_way0, half_way1, err0, err1)) >= 0,
		diy_fp.to_double(rounded_input_sigt0, rounded_input_sigt1, rounded_input_expt)
end

local function compute_guess(trimmed: { number }, len: number, expt: number): (boolean, number)
	if len <= 0 then
		return true, 0
	end
	if len + expt - 1 >= 309 then
		return true, math.huge
	end
	if len + expt <= -324 then
		return true, 0
	end

	local guess = double_strtod(trimmed, len, expt)
	if guess then
		return true, guess
	end

	return diy_fp_strtod(trimmed, len, expt)
end

local function next_double(double: number): number
	local sigt, expt = math.frexp(double)
	return math.ldexp(sigt + 2 ^ -53, expt)
end

local function double_upper_boundary(double: number): (number, number, number)
	local sigt0, sigt1, expt = diy_fp.create(double)
	sigt0, sigt1 = uint64_t.add(1, 0, uint64_t.sal(sigt0, sigt1, 1))
	return sigt0, sigt1, expt - 106
end

local function compare_buffer_with_diy_fp(
	trimmed: { number },
	len: number,
	expt: number,
	diy_fp_sigt0: number,
	diy_fp_sigt1: number,
	diy_fp_expt: number
): number
	local trimmed_bignum = {}
	trimmed_bignum.expt = 0
	local diy_fp_bignum = {}
	diy_fp_bignum.expt = 0
	bignum.assign_decimal(trimmed_bignum, trimmed, len)
	bignum.assign_uint64_t(diy_fp_bignum, diy_fp_sigt0, diy_fp_sigt1)
	if expt >= 0 then
		bignum.mult_pow10(trimmed_bignum, expt)
	else
		bignum.mult_pow10(diy_fp_bignum, -expt)
	end
	if diy_fp_expt > 0 then
		bignum.sal(diy_fp_bignum, diy_fp_expt)
	else
		bignum.sal(trimmed_bignum, -diy_fp_expt)
	end
	return bignum.compare(trimmed_bignum, diy_fp_bignum)
end

return function(trimmed: { number }, len: number, expt: number): number
	local is_correct, guess = compute_guess(trimmed, len, expt)
	if is_correct or guess == math.huge then
		return guess
	end

	local upper_sigt0, upper_sigt1, upper_expt = double_upper_boundary(guess)
	local cmp = compare_buffer_with_diy_fp(trimmed, len, expt, upper_sigt0, upper_sigt1, upper_expt)
	if cmp < 0 or cmp == 0 and bit32.band(diy_fp.create(guess), 1) == 0 then
		return guess
	end
	return next_double(guess)
end
