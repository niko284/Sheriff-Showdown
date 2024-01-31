--strict

-- Table Utils
-- November 23rd, 2022
-- Ron

local TableUtils = {}

function TableUtils.RecursiveFreeze(t: { any }): { any }
	for _, v in t do
		if typeof(v) == "table" then
			TableUtils.RecursiveFreeze(v)
		end
	end

	return not table.isfrozen(t) and table.freeze(t) or t
end

local function deepCopy(original)
	local copy = {}
	for k, v in pairs(original) do
		if type(v) == "table" then
			v = deepCopy(v)
		end
		copy[k] = v
	end
	return copy
end

TableUtils.DeepCopy = deepCopy

return TableUtils
