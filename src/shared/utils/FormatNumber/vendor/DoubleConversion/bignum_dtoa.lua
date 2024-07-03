--!strict
local uint64_t = require(script.Parent.uint64_t)
local bignum = require(script.Parent.bignum)
local diy_fp = require(script.Parent.diy_fp)
local xnil
xnil = nil
local RECIPROCAL_LOG2_10 = 0.30102999566398114 -- 1 / math.log2(10)

type BigNum = bignum.BigNum

local function normalized_exponent(sigt0: number, sigt1: number, expt: number): number
	while bit32.band(sigt1, 0x100000) == 0 do
		sigt0, sigt1 = uint64_t.sal(sigt0, sigt1, 1)
		expt -= 1
	end
	return expt
end

local function estimate_power(norm_expt: number): number
	return math.ceil((norm_expt + 52) * RECIPROCAL_LOG2_10 - 1e-10)
end

local function initial_scaled_start_values_positive_exponent(
	sigt0: number,
	sigt1: number,
	expt: number,
	estimated_power: number,
	need_boundary_deltas: boolean
): (BigNum, BigNum, BigNum?, BigNum?)
	local expt_div_28 = expt / 28
	local numerator = table.create(expt_div_28 + 2)
	numerator.expt = 0
	bignum.assign_uint64_t(numerator, sigt0, sigt1)
	bignum.sal(numerator, expt)
	local denominator = bignum.from_power(10, estimated_power)

	if need_boundary_deltas then
		bignum.sal(numerator, 1)
		bignum.sal(denominator, 1)

		local delta_plus = table.create(expt_div_28)
		delta_plus.expt = 0
		delta_plus[1] = 1
		bignum.sal(delta_plus, expt)
		local delta_minus: BigNum = {
			expt = delta_plus.expt,
			table.unpack(delta_plus),
		}

		return numerator, denominator, delta_minus, delta_plus
	end

	return numerator, denominator
end

local function initial_scaled_start_values_negative_exponent_positive_power(
	sigt0: number,
	sigt1: number,
	expt: number,
	estimated_power: number,
	need_boundary_deltas: boolean
): (BigNum, BigNum, BigNum?, BigNum?)
	local numerator = {}
	numerator.expt = 0
	bignum.assign_uint64_t(numerator, sigt0, sigt1)

	local denominator = bignum.from_power(10, estimated_power)
	bignum.sal(denominator, -expt)

	if need_boundary_deltas then
		bignum.sal(numerator, 1)
		bignum.sal(denominator, 1)
		return numerator, denominator, { expt = 0, 1 }, { expt = 0, 1 }
	end

	return numerator, denominator
end

local function initial_scaled_start_values_negative_exponent_negative_power(
	sigt0: number,
	sigt1: number,
	expt: number,
	estimated_power: number,
	need_boundary_deltas: boolean
): (BigNum, BigNum, BigNum?, BigNum?)
	local pow10 = bignum.from_power(10, -estimated_power)

	local delta_plus = nil
	local delta_minus = nil
	if need_boundary_deltas then
		delta_plus = { expt = pow10.expt, table.unpack(pow10) }
		delta_minus = { expt = pow10.expt, table.unpack(pow10) }
	end

	bignum.mul_uint64_t(pow10, sigt0, sigt1)

	local denominator = { expt = 0, 1 }
	bignum.sal(denominator, -expt)

	if need_boundary_deltas then
		bignum.sal(pow10, 1)
		bignum.sal(denominator, 1)
	end

	return pow10, denominator, delta_minus, delta_plus
end

local function initial_scaled_start_values(
	sigt0: number,
	sigt1: number,
	expt: number,
	lower_boundary_is_closer: boolean,
	estimated_power: number,
	need_boundary_deltas: boolean
): (BigNum, BigNum, BigNum?, BigNum?)
	local numerator: BigNum, denominator: BigNum
	local delta_minus: BigNum?, delta_plus: BigNum?
	if expt >= 0 then
		numerator, denominator, delta_minus, delta_plus = initial_scaled_start_values_positive_exponent(
			sigt0,
			sigt1,
			expt,
			estimated_power,
			need_boundary_deltas
		)
	elseif estimated_power >= 0 then
		numerator, denominator, delta_minus, delta_plus = initial_scaled_start_values_negative_exponent_positive_power(
			sigt0,
			sigt1,
			expt,
			estimated_power,
			need_boundary_deltas
		)
	else
		numerator, denominator, delta_minus, delta_plus = initial_scaled_start_values_negative_exponent_negative_power(
			sigt0,
			sigt1,
			expt,
			estimated_power,
			need_boundary_deltas
		)
	end
	if need_boundary_deltas and lower_boundary_is_closer then
		bignum.sal(denominator, 1)
		bignum.sal(numerator, 1)
		bignum.sal(delta_plus :: BigNum, 1)
	end
	return numerator, denominator, delta_minus, delta_plus
end

local function fixup_mult_10(
	estimated_power: number,
	is_even: boolean,
	numerator: BigNum,
	denominator: BigNum,
	delta_minus: BigNum?,
	delta_plus: BigNum?
): (number, BigNum, BigNum, BigNum?, BigNum?)
	local in_range = (
			delta_plus and bignum.plus_compare(numerator, delta_plus :: BigNum, denominator)
			or bignum.compare(numerator, denominator)
		) >= (is_even and 0 or 1)

	if in_range then
		return estimated_power + 1, numerator, denominator, delta_minus, delta_plus
	end
	bignum.mul_uint32_t(numerator, 10)
	if delta_minus then
		bignum.mul_uint32_t(delta_minus :: BigNum, 10)
	end
	if delta_plus then
		bignum.mul_uint32_t(delta_plus :: BigNum, 10)
	end
	return estimated_power, numerator, denominator, delta_minus, delta_plus
end

local function digit_gen(
	is_even: boolean,
	marker: number,
	numerator: BigNum,
	denominator: BigNum,
	delta_minus: BigNum,
	delta_plus: BigNum
): ({ number }, number, number)
	-- Tiny optimisation where delta_plus and delta_minus is reused if
	-- they're the same
	if bignum.compare(delta_minus, delta_plus) == 0 then
		delta_plus = delta_minus
	end
	local buffer = table.create(17)
	local buffer_n = 0

	while true do
		buffer_n += 1
		buffer[buffer_n] = bignum.divmod(numerator, denominator)

		local in_delta_room_minus, in_delta_room_plus =
			bignum.compare(numerator, delta_minus) <= (is_even and 0 or -1),
			bignum.plus_compare(numerator, delta_plus, denominator) >= (is_even and 0 or 1)

		if not in_delta_room_minus and not in_delta_room_plus then
			bignum.mul_uint32_t(numerator, 10)
			bignum.mul_uint32_t(delta_minus, 10)
			if delta_minus ~= delta_plus then
				bignum.mul_uint32_t(delta_plus, 10)
			end
		elseif in_delta_room_minus and in_delta_room_plus then
			local cmp = bignum.plus_compare(numerator, numerator, denominator)
			if cmp > 0 or cmp == 0 and buffer[buffer_n] % 2 ~= 0 then
				buffer[buffer_n] += 1
			end
			break
		elseif in_delta_room_minus then
			break
		else --if in_delta_room_plus then
			buffer[buffer_n] += 1
			break
		end
	end
	return buffer, buffer_n, marker - buffer_n
end

local function digit_gen_long(marker: number, numerator: BigNum, denominator: BigNum): ({ number }, number, number)
	local buffer = { bignum.divmod(numerator, denominator) }
	local buffer_n = 1
	while numerator[1] do
		buffer_n += 1
		bignum.mul_uint32_t(numerator, 10)
		buffer[buffer_n] = bignum.divmod(numerator, denominator)
	end

	-- just in case 10 appears (usually at the end)
	for i = buffer_n, 2, -1 do
		if buffer[i] ~= 10 then
			break
		end
		buffer[i] = 0
		buffer[i - 1] += 1
	end

	if buffer[1] == 10 then
		-- propgate a carry past the top place
		buffer[1] = 0
		buffer_n += 1
		table.insert(buffer, 1, 1)
		marker += 1
	end

	-- clear trailing zeroe
	while buffer[buffer_n] == 0 do
		buffer[buffer_n] = xnil
		buffer_n -= 1
	end

	return buffer, buffer_n, marker - buffer_n
end

return function(val, long): ({ number }, number, number)
	local sigt0, sigt1, expt = diy_fp.create(val)
	expt -= 105
	local lower_boundary_is_closer = sigt0 == 0 and sigt1 == 0

	local is_even = bit32.band(sigt0, 1) == 0
	local norm_expt = normalized_exponent(sigt0, sigt1, expt)
	-- estimated_power might be too low by 1.
	local estimated_power = estimate_power(norm_expt)
	local numerator, denominator, delta_minus, delta_plus = initial_scaled_start_values(
		sigt0,
		sigt1,
		expt,
		lower_boundary_is_closer,
		estimated_power,
		not long
	)

	estimated_power, numerator, denominator, delta_minus, delta_plus = fixup_mult_10(
		estimated_power,
		is_even,
		numerator,
		denominator,
		delta_minus,
		delta_plus
	)

	if long then
		return digit_gen_long(estimated_power, numerator, denominator)
	end
	return digit_gen(is_even, estimated_power, numerator, denominator, delta_minus :: BigNum, delta_plus :: BigNum)
end
