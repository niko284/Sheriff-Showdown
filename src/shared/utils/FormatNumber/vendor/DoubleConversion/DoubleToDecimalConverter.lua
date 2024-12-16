--!strict
local grisu3 = require(script.Parent.grisu3)
local bignum_dtoa = require(script.Parent.bignum_dtoa)
local DoubleToDecimalConverter = {}

--[[
Returns the shortest decimal representation of double converted to decimal in array of table
with the length and scale by the power of ten. Zero, infinity, and NaN will return nil
]]
function DoubleToDecimalConverter.ToShortest(value: number): ({ number }?, number?, number?)
	value = tonumber(value)
	if not value then
		error("Argument #2 provided must be a number", 2)
	end
	value = math.abs(value)

	if value ~= value or value == 0 or value == math.huge then
		return nil, nil, nil
	end

	local fmt, fmt_n, intg_i = grisu3(value)
	if fmt then
		return fmt, fmt_n, intg_i
	end
	return bignum_dtoa(value, false)
end

--[[
Returns the exact decimal representation of double converted to decimal in array of table
with the length and scale by the power of ten
]]
function DoubleToDecimalConverter.ToExact(value: number): ({ number }?, number?, number?)
	value = tonumber(value)
	if not value then
		error("Argument #2 provided must be a number", 2)
	end
	value = math.abs(value)

	if value ~= value or value == 0 or value == math.huge then
		return nil, nil, nil
	end

	return bignum_dtoa(value, true)
end

return DoubleToDecimalConverter
