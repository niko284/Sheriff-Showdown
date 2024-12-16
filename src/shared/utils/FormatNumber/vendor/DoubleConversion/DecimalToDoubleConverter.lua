--!strict
local strtod = require(script.Parent.strtod)
local DecimalToDoubleConverter = {}

--[[
Converts decimal array from i to j to a double with scale in power of tens
]]
function DecimalToDoubleConverter.ToDouble(value: { number }, scale: number?, i: number?, j: number?): number?
	if type(value) ~= "table" then
		error("Argument #1 provided must be a table", 2)
	end
	local i1, j1, rscale
	if scale == nil then
		rscale = 1
	else
		scale = tonumber(scale)
		if not scale then
			error("Argument #1 provided must be a number", 2)
		end
		rscale = scale :: number
	end
	if i == nil then
		i1 = 1
	else
		i = tonumber(i)
		if not i then
			error("Argument #3 provided must be a number", 2)
		end
		i1 = i :: number
	end
	if j == nil then
		j1 = 1
	else
		j = tonumber(j)
		if not j then
			error("Argument #4 provided must be a number", 2)
		end
		j1 = j :: number
	end
	local len = j1 - i1 + 1

	local decimal = table.create(len)
	local i2 = 0
	for d_i = i1, j1 do
		local d: number = tonumber(rawget(decimal, d_i))
		if not d then
			error(string.format("Index %d in table must be a number", d_i), 2)
		elseif d <= -1 or d >= 10 then
			error(string.format("Index %d in table must be in the bounds of 0 and 10", d_i), 2)
		end
		i2 += 1
		value[i2] = d < 0 and math.ceil(d) or math.floor(d)
	end

	return strtod(decimal, len, len + rscale)
end

return DecimalToDoubleConverter
