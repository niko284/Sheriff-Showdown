local proxy = require(script.Parent.proxy)
local Precision = {}

local Precision_methods = {}
local FractionPrecision_methods = {}

export type Precision = {}
export type FractionPrecision = {
	WithMinDigits: (FractionPrecision, number) -> Precision,
	WithMaxDigits: (FractionPrecision, number) -> Precision,
}

function FractionPrecision_methods:WithMinDigits(min: number): Precision
	local proxy_value = proxy.get(self, "FractionPrecision")
	if not proxy_value then
		error("Argument #1 must be a FractionPrecision object", 2)
	end
	if type(min) ~= "number" then
		error("Argument #2 must be a number", 2)
	elseif min < 0 or min > 999 or math.floor(min) ~= min then
		error("Argument #2 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "fracSigt",
		minFractionDigits = proxy_value.data.min,
		maxFractionDigits = proxy_value.data.max,
		maxSignificantDigits = min,
		roundingPriority = "relaxed",
	}

	return object
end

function FractionPrecision_methods:WithMaxDigits(max: number): Precision
	local proxy_value = proxy.get(self, "FractionPrecision")
	if not proxy_value then
		error("Argument #1 must be a FractionPrecision object", 2)
	end
	if type(max) ~= "number" then
		error("Argument #2 must be a number", 2)
	elseif max < 0 or max > 999 or math.floor(max) ~= max then
		error("Argument #2 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "fracSigt",
		minFractionDigits = proxy_value.data.min,
		maxFractionDigits = proxy_value.data.max,
		maxSignificantDigits = max,
		roundingPriority = "strict",
	}

	return object
end

function Precision.integer(): FractionPrecision
	local object, object_mt = proxy.create()

	object_mt.__index = FractionPrecision_methods
	object_mt.__name = "FractionPrecision"
	object_mt.data = {
		type = "fraction",
		min = 0,
		max = 0,
	}

	return object
end

function Precision.minFraction(min: number): FractionPrecision
	if type(min) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif min < 0 or min > 999 or math.floor(min) ~= min then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = FractionPrecision_methods
	object_mt.__name = "FractionPrecision"
	object_mt.data = {
		type = "fraction",
		min = min,
		max = 0,
	}

	return object
end

function Precision.maxFraction(max: number): FractionPrecision
	if type(max) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif max < 0 or max > 999 or math.floor(max) ~= max then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = FractionPrecision_methods
	object_mt.__name = "FractionPrecision"
	object_mt.data = {
		type = "fraction",
		min = 0,
		max = max,
	}

	return object
end

function Precision.minMaxFraction(min: number, max: number): FractionPrecision
	if type(min) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif min < 0 or min > 999 or math.floor(min) ~= min then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	elseif type(max) ~= "number" then
		error("Argument #2 must be a number", 2)
		-- selene: allow(if_same_then_else)
	elseif max < 0 or max > 999 or math.floor(max) ~= max then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	elseif max < min then
		error("Maximum argument must be greater or equal to the minimum argument", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = FractionPrecision_methods
	object_mt.__name = "FractionPrecision"
	object_mt.data = {
		type = "fraction",
		min = min,
		max = max,
	}

	return object
end

function Precision.fixedFraction(fixed: number): FractionPrecision
	if type(fixed) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif fixed < 0 or fixed > 999 or math.floor(fixed) ~= fixed then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = FractionPrecision_methods
	object_mt.__name = "FractionPrecision"
	object_mt.data = {
		type = "fraction",
		min = fixed,
		max = fixed,
	}

	return object
end

function Precision.minSignificantDigits(min: number): Precision
	if type(min) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif min < 0 or min > 999 or math.floor(min) ~= min then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "significant",
		min = min,
		max = 0,
	}

	return object
end

function Precision.maxSignificantDigits(max: number): Precision
	if type(max) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif max < 0 or max > 999 or math.floor(max) ~= max then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "significant",
		min = 0,
		max = max,
	}

	return object
end

function Precision.minMaxSignificantDigits(min: number, max: number): Precision
	if type(min) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif min < 0 or min > 999 or math.floor(min) ~= min then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	elseif type(max) ~= "number" then
		error("Argument #2 must be a number", 2)
		-- selene: allow(if_same_then_else)
	elseif max < 0 or max > 999 or math.floor(max) ~= max then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	elseif max < min then
		error("Maximum argument must be greater or equal to the minimum argument", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "significant",
		min = min,
		max = max,
	}

	return object
end

function Precision.fixedSignificantDigits(fixed: number): Precision
	if type(fixed) ~= "number" then
		error("Argument #1 must be a number", 2)
	elseif fixed < 0 or fixed > 999 or math.floor(fixed) ~= fixed then
		error("Argument #1 must be an integer in range from 0 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "significant",
		min = fixed,
		max = fixed,
	}

	return object
end

function Precision.unlimited(): Precision
	local object, object_mt = proxy.create()

	object_mt.__index = Precision_methods
	object_mt.__name = "Precision"
	object_mt.data = {
		type = "unlimited",
	}

	return object
end

return Precision
