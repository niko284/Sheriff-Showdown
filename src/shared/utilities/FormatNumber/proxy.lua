local proxy_data = setmetatable({}, { __mode = "k" })
local function to_string_object(self)
	return proxy_data[self].__name
end

local class_parents = {
	Notation = "any",
	ScientificNotation = "Notation",

	Precision = "any",
	FractionPrecision = "Precision",

	IntegerWidth = "any",

	NumberFormatter = "any",
}

return {
	create = function()
		local object = newproxy(true)
		local object_mt = getmetatable(object)

		proxy_data[object] = object_mt

		object_mt.__tostring = to_string_object

		return object, object_mt
	end,

	get = function(value, typ)
		local proxy_value = proxy_data[value]
		if proxy_value and proxy_value.__name ~= typ then
			local current_type = proxy_value.__name
			repeat
				current_type = class_parents[current_type]
			until current_type == "any" or current_type == typ
			if current_type == "any" then
				return nil
			end
		end
		return proxy_value
	end,

	type = function(value)
		local proxy_value = proxy_data[value]
		return proxy_value and proxy_value.__name
	end,

	is_a = function(value, typ)
		if not class_parents[typ] then
			error("Argument #2 must be a valid FormatNumber type", 2)
		end
		local proxy_value = proxy_data[value]
		if not proxy_value then
			return false
		end
		local current_type = proxy_value.__name
		repeat
			if current_type == typ then
				return true
			end
			current_type = class_parents[current_type]
		until current_type == "any"
		return false
	end,
}
