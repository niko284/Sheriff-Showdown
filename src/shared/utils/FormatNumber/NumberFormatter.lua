-- Edit the path to double conversion here --
local DoubleToDecimalConverter = require(script.Parent.vendor.DoubleConversion.DoubleToDecimalConverter)
-- --
local proxy = require(script.Parent.proxy)
local Notation = require(script.Parent.Notation)
local Precision = require(script.Parent.Precision)
local IntegerWidth = require(script.Parent.IntegerWidth)
local NumberFormatter = {}

local NumberFormatter_methods = {}

export type Notation = Notation.Notation
export type Precision = Precision.Precision
export type IntegerWidth = IntegerWidth.IntegerWidth
export type NumberFormatter = {
	Notation: (NumberFormatter, Notation) -> NumberFormatter,
	Precision: (NumberFormatter, Precision) -> NumberFormatter,
	RoundingMode: (NumberFormatter, number) -> NumberFormatter,
	Grouping: (NumberFormatter, number) -> NumberFormatter,
	IntegerWidth: (NumberFormatter, IntegerWidth) -> NumberFormatter,
	Sign: (NumberFormatter, number) -> NumberFormatter,

	Format: (NumberFormatter, number) -> string,
}

local function NumberFormatter_with_setting(setting, typ)
	local type_enum = type(typ) == "number"

	return function(self, value)
		local proxy_value = proxy.get(self, "NumberFormatter")
		if not proxy_value or proxy_value.__name ~= "NumberFormatter" then
			error("Argument #1 must be a NumberFormatter object", 2)
		end
		if type_enum then
			if type(value) ~= "number" or math.floor(value) ~= value or value < 0 or value > typ then
				error("Invalid value for argument #2", 2)
			end
		else
			local proxy_setting = proxy.get(value, typ)
			if not proxy_setting then
				error("Argument #2 must be a " .. typ .. " object", 2)
			end
			value = proxy_setting.data
		end
		local object, object_mt = proxy.create()

		object_mt.__index = NumberFormatter_methods
		object_mt.__name = "NumberFormatter"
		object_mt.resolved = nil
		object_mt.data = {
			key = setting,
			value = value,
			parent = proxy_value.data,
		}

		return object
	end
end

NumberFormatter_methods.Notation = NumberFormatter_with_setting("notation", "Notation")
NumberFormatter_methods.Precision = NumberFormatter_with_setting("precision", "Precision")
NumberFormatter_methods.RoundingMode = NumberFormatter_with_setting("roundingMode", 2)
NumberFormatter_methods.Grouping = NumberFormatter_with_setting("grouping", 2)
NumberFormatter_methods.IntegerWidth = NumberFormatter_with_setting("integerWidth", "IntegerWidth")
NumberFormatter_methods.Sign = NumberFormatter_with_setting("sign", 3)

local function round_fmt(fmt, fmt_n, intg_i, prec, rounding_mode)
	if fmt_n == 0 then
		return 0, 0, false
	end
	local intg_i_incr
	if prec.type ~= "unlimited" then
		local ro_i, midpoint_cmp, is_even
		if prec.type == "fracSigt" then
			local frac_i = prec.maxFractionDigits
			local sigt_i = prec.maxSignificantDigits
			if not frac_i then
				ro_i = sigt_i
			elseif prec.roundingPriority == "strict" then
				ro_i = math.min(intg_i + frac_i, sigt_i)
			elseif prec.roundingPriority == "relaxed" then
				ro_i = math.max(intg_i + frac_i, sigt_i)
			end
		elseif not prec.max then
			return fmt_n, intg_i, false
		elseif prec.type == "fraction" then
			ro_i = intg_i + prec.max
		elseif prec.type == "significant" then
			ro_i = prec.max
		end

		if ro_i < 0 then
			intg_i_incr = -ro_i + 1
			midpoint_cmp = -1
			fmt_n = 0
			is_even = true
		elseif ro_i < fmt_n then
			intg_i_incr = 1
			midpoint_cmp = fmt[ro_i + 1] == 5 and (ro_i + 1 == fmt_n and 0 or 1) or fmt[ro_i + 1] < 5 and -1 or 1
			fmt_n = ro_i
			is_even = ro_i == 0 or fmt[ro_i] % 2 == 0
		else
			midpoint_cmp = -2
		end

		local incr
		if rounding_mode == 1 then
			incr = midpoint_cmp >= 0
		elseif rounding_mode == 0 then
			incr = midpoint_cmp > 0 or midpoint_cmp == 0 and not is_even
		end
		if incr then
			for ro_i1 = fmt_n, 0, -1 do
				if ro_i1 == 0 then
					fmt[1] = 1
					fmt_n = 1
					intg_i += intg_i_incr
					return fmt_n, intg_i, true
				else
					local c = (fmt[ro_i1] or 0) + 1
					if c == 10 then
						fmt[ro_i1] = nil
						fmt_n -= 1
					else
						fmt[ro_i1] = c
						break
					end
				end
			end
		end

		-- trailing zero
		while fmt[fmt_n] == 0 do
			fmt_n -= 1
		end
	end

	return fmt_n, intg_i, false
end

local function format_numberformatter(self, is_negt, fmt, fmt_n, intg_i)
	local ret
	local resolved = self.resolved
	local disp_sign
	local is_zero

	-- compile formatter
	if not resolved then
		resolved = {
			notation = nil,
			precision = nil,
			roundingMode = nil,
			grouping = nil,
			integerWidth = nil,
			sign = nil,
		}

		local ll = self.data
		while ll do
			if not resolved[ll.key] then
				resolved[ll.key] = ll.value
			end
			ll = ll.parent
		end

		-- defaults
		if not resolved.notation then
			resolved.notation = { type = "simple" }
		end
		if not resolved.precision then
			resolved.precision = resolved.notation.type == "compact"
					and {
						type = "fracSigt",
						minFractionDigits = 0,
						maxFractionDigits = 0,
						maxSignificantDigits = 2,
						roundingPriority = "relaxed",
					}
				or {
					type = "fraction",
					min = 0,
					max = 6,
				}
		end
		if not resolved.roundingMode then
			resolved.roundingMode = resolved.notation.type == "simple" and 0 or 2
		end
		if not resolved.grouping then
			-- compact notation use MIN2 by default
			resolved.grouping = resolved.notation.type == "compact" and 1 or 2
		end
		if not resolved.integerWidth then
			resolved.integerWidth = {
				zeroFillTo = 1,
				truncateAt = nil,
			}
		end
		if not resolved.sign then
			resolved.sign = 0
		end

		self.resolved = resolved
	end

	-- Infinity and NaN
	if fmt == "nan" then
		ret = "NaN"
		-- Internationally set to true
		is_zero = true
	elseif fmt == "inf" then
		ret = "∞"
		is_zero = false
	else
		local intg, frac, expt
		local expt_i = 0
		local rescale
		local prec = resolved.precision
		local notation = resolved.notation
		local intg_w, min_frac_w

		-- exponent
		if notation.type ~= "simple" and fmt_n ~= 0 then
			expt_i = intg_i - 1

			if notation.engineering then
				intg_i = expt_i % 3 + 1
				expt_i = math.floor(expt_i / 3) * 3
			elseif notation.type == "compact" then
				intg_i = expt_i % 3 + 1
				expt_i = math.floor(expt_i / 3)

				if expt_i > notation.length then
					intg_i += 3 * (expt_i - notation.length)
					expt_i = notation.length
				elseif expt_i < 0 then
					intg_i += 3 * expt_i
					expt_i = 0
				end
			else
				intg_i = 1
			end
		end

		fmt_n, intg_i, rescale = round_fmt(fmt, fmt_n, intg_i, prec, resolved.roundingMode)

		if rescale and (notation.type ~= "compact" or expt_i ~= notation.length) then
			expt_i += notation.engineering and 3 or 1
			intg_i = 1
		end

		if notation.type == "scientific" then
			local is_expt_negt = expt_i < 0
			if is_expt_negt then
				expt = string.format("%d", -expt_i)
			else
				expt = string.format("%d", expt_i)
			end

			expt = string.rep("0", notation.minExponentDigits - #expt) .. expt

			if
				(notation.exponentsign == 0 or notation.exponentsign == 4) and is_expt_negt
				or notation.exponentsign == 2
				or notation.exponentsign == 3 and expt_i ~= 0
			then
				expt = (is_expt_negt and "-" or "+") .. expt
			end

			expt = "E" .. expt
		elseif notation.type == "compact" and expt_i ~= 0 then
			expt = notation.value[expt_i]
		else
			expt = ""
		end

		is_zero = fmt_n == 0

		for i = 1, fmt_n do
			fmt[i] += 0x30
		end

		-- integer
		if fmt then
			intg = string.char(table.unpack(fmt, nil, math.min(intg_i, fmt_n))) .. string.rep("0", intg_i - fmt_n)
		else
			intg = ""
		end

		if resolved.integerWidth.truncateAt then
			intg = string.gsub(string.sub(intg, -resolved.integerWidth.truncateAt), "^0+", "")
		end
		intg = string.rep("0", resolved.integerWidth.zeroFillTo - #intg) .. intg
		intg_w = #intg

		if resolved.grouping ~= 0 and intg_w > 5 - resolved.grouping then
			intg = string.reverse((string.gsub(string.reverse(intg), "(...)", "%1,", (intg_w - 1) / 3)))
		end

		-- fraction
		if prec.type == "fraction" then
			min_frac_w = prec.min
		elseif prec.type == "fracSigt" then
			min_frac_w = prec.minFractionDigits
		elseif prec.type == "significant" then
			min_frac_w = math.max(prec.min - intg_w, 0)
		else
			min_frac_w = 0
		end

		if fmt_n ~= 0 then
			frac = string.rep("0", -intg_i) .. string.char(table.unpack(fmt, math.max(intg_i + 1, 1), fmt_n))
		else
			frac = ""
		end
		frac ..= string.rep("0", min_frac_w - #frac)

		if frac ~= "" then
			frac = "." .. frac
		end

		ret = intg .. frac .. expt
	end

	local raw_sign = resolved.sign
	if raw_sign == 1 then
		disp_sign = true
	elseif raw_sign == 2 then
		disp_sign = false
	elseif raw_sign == 3 then
		-- despite 'except zero'
		-- it also includes numbers that round to zero
		-- and NaN
		disp_sign = not is_zero
	elseif raw_sign == 4 then
		-- do not display signed zero
		-- nor numbers that round to signed zero
		-- nor signed NaN
		disp_sign = is_negt and not is_zero
	else
		disp_sign = is_negt
	end

	if disp_sign then
		ret = (is_negt and "-" or "+") .. ret
	end

	return ret
end

function NumberFormatter_methods:Format(value: number): string
	local proxy_value = proxy.get(self, "NumberFormatter")
	if not proxy_value or proxy_value.__name ~= "NumberFormatter" then
		error("Argument #1 must be a NumberFormatter object", 2)
	end
	if type(value) ~= "number" then
		error("Argument #2 must be a number", 2)
	end
	local is_negt, fmt, fmt_n, intg_i
	if value == 0 then
		is_negt = math.atan2(value, -1) < 0
		fmt, fmt_n, intg_i = nil, 0, 0
	elseif value ~= value then
		-- Sign bit detection for NaN
		-- NaN payload ignored
		is_negt = string.byte(string.pack(">d", value)) >= 0x80
		fmt = "nan"
	elseif value == math.huge then
		is_negt = false
		fmt = "inf"
	elseif value == -math.huge then
		is_negt = true
		fmt = "inf"
	elseif math.floor(value) == value and math.abs(value) < 0x40000000000008 then
		-- optimisation
		if value < 0 then
			is_negt = true
			value = -value
		end
		if value < 10 then
			fmt, fmt_n, intg_i = { value }, 1, 1
		else
			local int_str = string.format("%d", value)
			fmt = { string.byte(int_str, nil, -1) }
			intg_i = #fmt
			for i = intg_i, 1, -1 do
				if not fmt_n and fmt[i] ~= 0x30 then
					fmt_n = i
				end
				fmt[i] -= 0x30
			end
		end
	else
		is_negt = value < 0
		fmt, fmt_n, intg_i = DoubleToDecimalConverter.ToShortest(math.abs(value))
		intg_i += fmt_n
	end

	return format_numberformatter(proxy_value, is_negt, fmt, fmt_n, intg_i)
end

function NumberFormatter.with(): NumberFormatter
	local object, object_mt = proxy.create()

	object_mt.__index = NumberFormatter_methods
	object_mt.__name = "NumberFormatter"
	object_mt.resolved = nil
	object_mt.data = nil

	return object
end

return NumberFormatter
