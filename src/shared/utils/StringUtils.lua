--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.packages.Freeze)

local StringUtils = {}

function StringUtils.GetFirstStringInAlphabet(StringList: { string }): (string, number)
	local alphabeticSort = Freeze.List.sort(StringList, function(a: string, b: string)
		return a:lower() < b:lower()
	end)
	return alphabeticSort[1], table.find(StringList, alphabeticSort[1]) :: number
end

return StringUtils
