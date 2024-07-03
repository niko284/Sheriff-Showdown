local proxy = require(script.Parent.proxy)
local Notation = { }

local Notation_methods = { }
local ScientificNotation_methods = { }

export type Notation = { }
export type ScientificNotation = {
	WithExponentSignDisplay: (ScientificNotation, number) -> ScientificNotation,
	WithMinExponentDigits: (ScientificNotation, number) -> ScientificNotation,
}

function ScientificNotation_methods:WithExponentSignDisplay(disp: number): ScientificNotation
	local proxy_value = proxy.get(self, "ScientificNotation")
	if not proxy_value then
		error("Argument #1 must be a ScientificNotation object", 2)
	end
	if type(disp) ~= "number"
		or math.floor(disp) ~= disp or disp < 0 or disp > 4 then
		error("Invalid value for argument #2", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = ScientificNotation_methods
	object_mt.__name = "ScientificNotation"
	object_mt.data = {
		type = "scientific",
		minExponentDigits = proxy_value.data.minExponentDigits,
		exponentSignDisplay = disp,
		engineering = proxy_value.data.engineering,
	}

	return object
end

function ScientificNotation_methods:WithMinExponentDigits(min: number): ScientificNotation
	local proxy_value = proxy.get(self, "ScientificNotation")
	if not proxy_value then
		error("Argument #1 must be a ScientificNotation object", 2)
	end
	if type(min) ~= "number" then
		error("Argument #2 must be a number", 2)
	elseif min < 1 or min > 999 or math.floor(min) ~= min then
		error("Argument #2 must be an integer in range from 1 to (and including) 999", 2)
	end
	local object, object_mt = proxy.create()

	object_mt.__index = ScientificNotation_methods
	object_mt.__name = "ScientificNotation"
	object_mt.data = {
		type = "scientific",
		minExponentDigits = min,
		exponentSignDisplay = proxy_value.data.exponentSignDisplay,
		engineering = proxy_value.data.engineering,
	}

	return object
end

function Notation.scientific(): ScientificNotation
	local object, object_mt = proxy.create()

	object_mt.__index = ScientificNotation_methods
	object_mt.__name = "ScientificNotation"
	object_mt.data = {
		type = "scientific",
		minExponentDigits = 1,
		exponentSignDisplay = 0,
		engineering = false,
	}

	return object
end

function Notation.engineering(): ScientificNotation
	local object, object_mt = proxy.create()

	object_mt.__index = ScientificNotation_methods
	object_mt.__name = "ScientificNotation"
	object_mt.data = {
		type = "scientific",
		minExponentDigits = 1,
		exponentSignDisplay = 0,
		engineering = true,
	}

	return object
end

function Notation.compactWithSuffixThousands(suffix_array: { string }): Notation
	if type(suffix_array) ~= "table" then
		error("Argument #1 must be a table", 2)
	end
	suffix_array = table.move(suffix_array, 1, #suffix_array, 1, table.create(#suffix_array))
	for i = 1, #suffix_array do
		if type(suffix_array[i]) ~= "string" then
			error(string.format("Invalid value (%s) at index %d in table", type(suffix_array[i]), i), 2)
		end
	end

	local object, object_mt = proxy.create()

	object_mt.__index = Notation_methods
	object_mt.__name = "Notation"

	object_mt.data = {
		type = "compact",
		value = suffix_array,
		length = #suffix_array,
	}

	return object
end

function Notation.simple(): Notation
	local object, object_mt = proxy.create()

	object_mt.__index = Notation_methods
	object_mt.__name = "Notation"
	object_mt.data = {
		type ="simple",
	}
	
	return object
end

return Notation