--!strict
local uint64_t = require(script.Parent.uint64_t)
local diy_fp = require(script.Parent.diy_fp)
local cached_power = require(script.Parent.cached_power)
local ieee = require(script.Parent.ieee)
local function round_weed(
	buffer: { number },
	length: number,
	distance_too_high_w0: number,
	distance_too_high_w1: number,
	unsafe_interval0: number,
	unsafe_interval1: number,
	rest0: number,
	rest1: number,
	ten_kappa0: number,
	ten_kappa1: number,
	unit0: number,
	unit1: number
): boolean
	local small_distance0, small_distance1 = uint64_t.sub(distance_too_high_w0, distance_too_high_w1, unit0, unit1)
	local big_distance0, big_distance1 = uint64_t.add(distance_too_high_w0, distance_too_high_w1, unit0, unit1)
	while
		uint64_t.compare(rest0, rest1, small_distance0, small_distance1) < 0
		and uint64_t.compare(ten_kappa0, ten_kappa1, uint64_t.sub(unsafe_interval0, unsafe_interval1, rest0, rest1)) <= 0
	do
		local sd0, sd1 = uint64_t.add(rest0, rest1, ten_kappa0, ten_kappa1)
		sd0, sd1 = uint64_t.sub(sd0, sd1, small_distance0, small_distance1)
		if
			uint64_t.compare(small_distance0, small_distance1, uint64_t.add(rest0, rest1, ten_kappa0, ten_kappa1)) <= 0
			and uint64_t.compare(sd0, sd1, uint64_t.sub(small_distance0, small_distance1, rest0, rest1)) > 0
		then
			break
		end
		buffer[length] -= 1
		rest0, rest1 = uint64_t.add(rest0, rest1, ten_kappa0, ten_kappa1)
	end

	if
		uint64_t.compare(rest0, rest1, big_distance0, big_distance1) < 0
		and uint64_t.compare(ten_kappa0, ten_kappa1, uint64_t.sub(unsafe_interval0, unsafe_interval1, rest0, rest1)) <= 0
	then
		local sd0, sd1 = uint64_t.add(rest0, rest1, ten_kappa0, ten_kappa1)
		sd0, sd1 = uint64_t.sub(sd0, sd1, big_distance0, big_distance1)
		local _t0, _t1 = uint64_t.sub(big_distance0, big_distance1, rest0, rest1)
		if
			uint64_t.compare(big_distance0, big_distance1, uint64_t.add(rest0, rest1, ten_kappa0, ten_kappa1)) > 0
			or uint64_t.compare(sd0, sd1, uint64_t.sub(big_distance0, big_distance1, rest0, rest1)) < 0
		then
			return false
		end
	end

	return uint64_t.compare(rest0, rest1, uint64_t.sal(unit0, unit1, 1)) >= 0
		and uint64_t.compare(rest0, rest1, uint64_t.sub(unsafe_interval0, unsafe_interval1, uint64_t.sal(unit0, unit1, 2)))
			<= 0
end

local small_powers_of_ten = { [0] = 0, 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000 }
local function biggest_power_10(val: number, val_bits: number): (number, number)
	local exponent_plus_one_guess = bit32.rshift((val_bits + 1) * 1233, 12) + 1
	if val < small_powers_of_ten[exponent_plus_one_guess] then
		exponent_plus_one_guess -= 1
	end
	return small_powers_of_ten[exponent_plus_one_guess], exponent_plus_one_guess
end

local function digit_gen(
	low_sigt0: number,
	low_sigt1: number,
	_low_expt: number,
	w_sigt0: number,
	w_sigt1: number,
	w_expt: number,
	high_sigt0: number,
	high_sigt1: number,
	_high_expt: number
): (boolean, { number }, number, number)
	local unit0, unit1 = 1, 0
	local too_low_sigt0, too_low_sigt1 = uint64_t.sub(low_sigt0, low_sigt1, unit0)
	local too_high_sigt0, too_high_sigt1 = uint64_t.add(high_sigt0, high_sigt1, unit0)

	local unsafe_interval0, unsafe_interval1 = uint64_t.sub(too_high_sigt0, too_high_sigt1, too_low_sigt0, too_low_sigt1)

	local one0, one1 = uint64_t.sal(1, 0, -w_expt)
	local one_decr0, one_decr1 = uint64_t.sub(one0, one1, 1)
	local frac0, frac1 = bit32.band(too_high_sigt0, one_decr0), bit32.band(too_high_sigt1, one_decr1)
	local intg = uint64_t.sal(too_high_sigt0, too_high_sigt1, w_expt)
	local divisor, divisor_exponent_plus_one = biggest_power_10(intg, 64 + w_expt)

	local kappa = divisor_exponent_plus_one
	local length = 0

	local buffer = table.create(17)
	while kappa > 0 do
		length += 1
		buffer[length] = math.floor(intg / divisor)
		intg %= divisor
		kappa -= 1

		local rest0, rest1 = uint64_t.add(frac0, frac1, uint64_t.sal(intg, 0, -w_expt))

		if uint64_t.compare(rest0, rest1, unsafe_interval0, unsafe_interval1) < 0 then
			local dth0, dth1 = uint64_t.sub(too_high_sigt0, too_high_sigt1, w_sigt0, w_sigt1)
			local ten_kappa0, ten_kappa1 = uint64_t.sal(divisor, 0, -w_expt)
			return round_weed(
				buffer,
				length,
				dth0,
				dth1,
				unsafe_interval0,
				unsafe_interval1,
				rest0,
				rest1,
				ten_kappa0,
				ten_kappa1,
				unit0,
				unit1
			),
				buffer,
				length,
				kappa
		end
		divisor /= 10
	end

	while true do
		frac0, frac1 = uint64_t.mul(frac0, frac1, 10, 0)
		unit0, unit1 = uint64_t.mul(unit0, unit1, 10, 0)
		unsafe_interval0, unsafe_interval1 = uint64_t.mul(unsafe_interval0, unsafe_interval1, 10, 0)

		length += 1
		buffer[length] = uint64_t.sal(frac0, frac1, w_expt)
		frac0, frac1 = bit32.band(frac0, one_decr0), bit32.band(frac1, one_decr1)
		kappa -= 1
		if uint64_t.compare(frac0, frac1, unsafe_interval0, unsafe_interval1) < 0 then
			local dth0, dth1 = uint64_t.mul(unit0, unit1, uint64_t.sub(too_high_sigt0, too_high_sigt1, w_sigt0, w_sigt1))
			return round_weed(
				buffer,
				length,
				dth0,
				dth1,
				unsafe_interval0,
				unsafe_interval1,
				frac0,
				frac1,
				one0,
				one1,
				unit0,
				unit1
			),
				buffer,
				length,
				kappa
		end
	end
end

return function(val): ({ number }?, number?, number?)
	local w_sigt0: number, w_sigt1: number, w_expt: number = diy_fp.create_normalized(val)
	local boundary_minus_sigt0, boundary_minus_sigt1, boundary_minus_expt, boundary_plus_sigt0, boundary_plus_sigt1, boundary_plus_expt =
		ieee.normalized_boundaries(
			diy_fp.create(val)
		)

	-- per double-conversion/fast-dtoa.cc:
	-- cached power of ten: 10^-k
	local ten_mk_sigt0, ten_mk_sigt1, ten_mk_expt, mk = cached_power.bin_expt_range(-60 - (w_expt + 64))

	-- exponent = w_expt + 64
	local scaled_w_sigt0, scaled_w_sigt1 = diy_fp.mul128(w_sigt0, w_sigt1, ten_mk_sigt0, ten_mk_sigt1)

	local scaled_boundary_minus_sigt0, scaled_boundary_minus_sigt1 = diy_fp.mul128(
		boundary_minus_sigt0,
		boundary_minus_sigt1,
		ten_mk_sigt0,
		ten_mk_sigt1
	)

	local scaled_boundary_plus_sigt0, scaled_boundary_plus_sigt1 = diy_fp.mul128(
		boundary_plus_sigt0,
		boundary_plus_sigt1,
		ten_mk_sigt0,
		ten_mk_sigt1
	)

	local result, buffer, length, kappa = digit_gen(
		scaled_boundary_minus_sigt0,
		scaled_boundary_minus_sigt1,
		boundary_minus_expt + ten_mk_expt + 64,

		scaled_w_sigt0,
		scaled_w_sigt1,
		w_expt + ten_mk_expt + 64,
		scaled_boundary_plus_sigt0,
		scaled_boundary_plus_sigt1,

		boundary_plus_expt + ten_mk_expt + 64
	)

	if result then
		return buffer, length, -mk + kappa
	end

	-- fallback
	return nil
end
