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

function StringUtils.ContainsOnlySpaces(String: string): ...string?
	return String:match("^%s*$")
end

function StringUtils.GetReadingTime(str: string): number
	return math.max(1, math.min(10, #str / 10))
end

function StringUtils.MatchesSearch(Word: string, SearchPattern: string): boolean
	if StringUtils.ContainsOnlySpaces(SearchPattern) then
		return true
	end
	local patternIndex = 1
	local patternLength = #SearchPattern
	local strIndex = 1
	local strLength = #Word
	while patternIndex <= patternLength and strIndex <= strLength do
		local patternChar = SearchPattern:sub(patternIndex, patternIndex):lower()
		local strChar = Word:sub(strIndex, strIndex):lower()
		if patternChar == strChar then
			patternIndex = patternIndex + 1
		end
		strIndex = strIndex + 1
	end
	return patternLength > 0 and strLength > 0 and (patternIndex - 1) == patternLength
end

return StringUtils
