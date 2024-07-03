local proxy = require(script.Parent.proxy)
local IntegerWidth = {}

local IntegerWidth_methods = {}

export type IntegerWidth = {
	TruncateAt: (IntegerWidth, number) -> IntegerWidth,
}

function IntegerWidth_methods:TruncateAt(max: number): IntegerWidth
	local proxy_value = proxy.get(self, "IntegerWidth")
	if not proxy_value or proxy_value.__name ~= "IntegerWidth" then
		error("Argument #1 must be a IntegerWidth object", 2)
	end
	if max == -1 then
		max = nil
	elseif type(max) ~= "number" then
		error("Argument #2 must be a number", 2)
	elseif max < 1 or max > 999 or math.floor(max) ~= max then
		error("Argument #2 must be an integer in range from 1 to (and including) 999", 2)
	elseif max < proxy_value.data.zeroFillTo then
		error("Argument must be greater or equal to the zeroFillTo setting", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = IntegerWidth_methods
	object_mt.__name = "IntegerWidth"
	object_mt.data = {
		zeroFillTo = proxy_value.data.zeroFillTo,
		truncateAt = max,
	}

	return object
end

function IntegerWidth.zeroFillTo(min: number): IntegerWidth
	if type(min) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif min < 1 or min > 999 or math.floor(min) ~= min then
		error("Argument #1 must be an integer in range from 1 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = IntegerWidth_methods
	object_mt.__name = "IntegerWidth"
	object_mt.data = {
		zeroFillTo = min,
		truncateAt = nil,
	}

	return object
end

return IntegerWidth
