--!strict
local proxy = require(script.Parent.proxy)
local grisu3 = require(script.Parent.grisu3)
local bignum_dtoa = require(script.Parent.bignum_dtoa)
local DoubleToStringConverter = {}
local DoubleToStringConverter_methods = {}
export type DoubleToStringConverter = {
	ToShortest: (DoubleToStringConverter, number, number?) -> string?,
	ToExact: (DoubleToStringConverter, number, number?) -> string?,
}

type DoubleToStringConverterProxy = {
	__index: DoubleToStringConverter,
	__name: string,
	__metatable: string,
	flags: number,
	infinity_symbol: string?,
	nan_symbol: string?,
	exponent_symbol: string,
	decimal_in_shortest_low: number,
	decimal_in_shortest_high: number,
	min_exponent_width: number,
}

local function double_to_ascii(value: number, converter: DoubleToStringConverterProxy, long: boolean, format: number): string?
	if value ~= value then
		return converter.nan_symbol
	elseif value == math.huge then
		return converter.infinity_symbol
	elseif value == -math.huge then
		local infinity_symbol: string? = converter.infinity_symbol
		if not infinity_symbol then
			return nil
		end
		return "-" .. infinity_symbol :: string
	end

	local abs_value: number = math.abs(value)
	local ret: string
	local flags: number = converter.flags
	local sign: boolean
	local exponential: boolean = format == 2
	if abs_value == 0 then
		ret = exponential and "0E0" or "0"
		sign = bit32.band(flags, 0x0001) == 0 and math.atan2(value, -1) < 0
	else
		local fmt: { number }, fmt_n: number, intg_i: number
		if long then
			fmt, fmt_n, intg_i = bignum_dtoa(abs_value, true)
		else
			local grisu3_fmt, grisu3_fmt_n, grisu3_intg_i = grisu3(abs_value)
			if grisu3_fmt then
				fmt = grisu3_fmt :: { number }
				fmt_n = grisu3_fmt_n :: number
				intg_i = grisu3_intg_i :: number
			else
				fmt, fmt_n, intg_i = bignum_dtoa(abs_value, false)
			end
		end
		intg_i += fmt_n
		sign = value ~= abs_value

		for i = 1, fmt_n do
			fmt[i] += 0x30
		end

		if format == 0 then
			exponential = intg_i <= converter.decimal_in_shortest_low or intg_i > converter.decimal_in_shortest_high
		end

		if exponential then
			local expt = string.format("%d", math.abs(intg_i - 1))
			expt = string.rep("0", converter.min_exponent_width - #expt) .. expt
			if intg_i <= 0 then
				expt = "-" .. expt
			elseif bit32.band(flags, 0x0001) ~= 0 then
				expt = "+" .. expt
			end

			ret = string.char(fmt[1], 0x2E, table.unpack(fmt, 2, fmt_n))
			if fmt_n < 2 then
				ret = string.sub(ret, 1, 1)
			end
			ret ..= converter.exponent_symbol .. expt
		else
			ret = string.char(table.unpack(fmt, 1, math.min(intg_i, fmt_n))) .. string.rep("0", intg_i - fmt_n)

			if fmt_n <= intg_i then
				if bit32.band(flags, 0x0002) ~= 0 then
					ret ..= bit32.band(flags, 0x0004) == 0 and "." or ".0"
				end
			else
				ret ..= "." .. string.rep("0", -intg_i) .. string.char(table.unpack(fmt, math.max(intg_i + 1, 1), fmt_n))
			end
		end
	end

	return sign and "-" .. ret or ret
end

--[[
Converts the double to its shortest decimal representation that correctly represents the double
]]
function DoubleToStringConverter_methods:ToShortest(value: number, format: number?): string?
	self = proxy[self]
	if not self or self.__name ~= "DoubleToStringConverter" then
		error("Argument #1 provided must be a DoubleToStringConverter", 2)
	end
	value = tonumber(value)
	if not value then
		error("Argument #2 provided must be a number", 2)
	end
	if format == nil then
		format = 0
	else
		format = tonumber(format)
		if not format then
			error("Argument #3 provided must be a number", 2)
		elseif format < 0 or format > 2 then
			error("Invalid argument #3", 2)
		end
	end
	return double_to_ascii(value, self, false, format :: number)
end

--[[
Converts the double to its exact decimal representation
]]
function DoubleToStringConverter_methods:ToExact(value: number, format: number?): string?
	self = proxy[self]
	if not self or self.__name ~= "DoubleToStringConverter" then
		error("Argument #1 provided must be a DoubleToStringConverter", 2)
	end
	value = tonumber(value)
	if not value then
		error("Argument #2 provided must be a number", 2)
	end
	if format == nil then
		format = 0
	else
		format = tonumber(format)
		if not format then
			error("Argument #3 provided must be a number", 2)
		elseif format < 0 or format > 2 then
			error("Invalid argument #3", 2)
		end
	end
	return double_to_ascii(value, self, true, format :: number)
end

--[[
NO_FLAGS - No flags
EMIT_POSITIVE_EXPONENT_SIGN - When the number is in the exponential format,
it emits the "+" sign for positive exponents.
EMIT_TRAILING_DECIMAL_POINT - When the number is in the decimal format,
it emits a trailing decimal point ".".
EMIT_TRAILING_ZERO_AFTER_POINT - When the number is in the decimal format,
it emits a trailing "0" after the point, EMIT_TRAILING_DECIMAL_POINT must
be enabled
UNIQUE_ZERO - -0.0 does not display the minus sign "-"
]]
DoubleToStringConverter.Flags = {
	NO_FLAGS = 0x0000,
	EMIT_POSITIVE_EXPONENT_SIGN = 0x0001,
	EMIT_TRAILING_DECIMAL_POINT = 0x0002,
	EMIT_TRAILING_ZERO_AFTER_POINT = 0x0004,
	UNIQUE_ZERO = 0x0008,
}

--[[
AUTO - Determine whether to print in decimal or exponential format based on the
argument decimal_in_shortest_low and decimal_in_shortest_high
DECIMAL - Print in the decimal format, no E notation.
EXPONENTIAL - Print in the exponential format, the E notation.
]]
DoubleToStringConverter.Format = {
	AUTO = 0,
	DECIMAL = 1,
	EXPONENTIAL = 2,
}

--[[
flags - The flags see DoubleToStringConverter.Flags
infinity_symbol - Symbol for infinity, if nil then infinity returns nil
nan_symbol - Symbol for NaN, if nil then NaN returns nil
exponent_symbol - Symbol to represent exponent, usually 'e' or 'E'
decimal_in_shortest_low and decimal_in_shortest_high - print the decimal format
beteween [10^decimal_in_shortest_low; 10^decimal_in_shortest_high[ if the
format argument is provided as DoubleToStringConverter.Format.AUTO
min_exponent_width - Zero fills the exponent integer digits
]]
function DoubleToStringConverter.new(
	flags: number,
	infinity_symbol: string?,
	nan_symbol: string?,
	exponent_symbol: string,
	decimal_in_shortest_low: number,
	decimal_in_shortest_high: number,
	min_exponent_width: number
): DoubleToStringConverter
	flags = tonumber(flags)
	if not flags then
		error("Argument #1 provided must be a number", 2)
	elseif flags < 0 or flags > 0x00FF or bit32.band(flags, 0x0006) == 0x0004 then
		error("Invalid argument #1", 2)
	end
	if type(infinity_symbol) ~= "string" and infinity_symbol ~= nil then
		error("Argument #2 provided must be a string", 2)
	end
	if type(nan_symbol) ~= "string" and nan_symbol ~= nil then
		error("Argument #3 provided must be a string", 2)
	end
	if type(exponent_symbol) ~= "string" then
		error("Argument #4 provided must be a string", 2)
	end
	decimal_in_shortest_low = tonumber(flags)
	if not decimal_in_shortest_low then
		error("Argument #5 provided must be a number", 2)
	elseif decimal_in_shortest_low <= -1000 or decimal_in_shortest_low >= 1000 then
		error("Argument #5 provided must be in the bounds of -999 to 999", 2)
	end
	decimal_in_shortest_high = tonumber(flags)
	if not decimal_in_shortest_high then
		error("Argument #6 provided must be a number", 2)
	elseif decimal_in_shortest_high <= -1000 or decimal_in_shortest_high >= 1000 then
		error("Argument #6 provided must be in the bounds of -999 to 999", 2)
	end
	min_exponent_width = tonumber(min_exponent_width)
	if not min_exponent_width then
		error("Argument #7 provided must be a number", 2)
	elseif min_exponent_width < 1 or min_exponent_width >= 6 then
		error("Argument #7 provided must be in the bounds of 1 to 5", 2)
	end

	local object = newproxy(true) :: any
	local object_mt = getmetatable(object)

	object_mt.__index = DoubleToStringConverter_methods
	object_mt.__name = "DoubleToStringConverter"
	object_mt.__metatable = "The metatable is locked"
	object_mt.flags = flags
	object_mt.infinity_symbol = infinity_symbol
	object_mt.nan_symbol = nan_symbol
	object_mt.exponent_symbol = exponent_symbol
	object_mt.decimal_in_shortest_low = decimal_in_shortest_low
	object_mt.decimal_in_shortest_high = decimal_in_shortest_high
	object_mt.min_exponent_width = min_exponent_width

	proxy[object] = object_mt

	return object :: DoubleToStringConverter
end

return DoubleToStringConverter
