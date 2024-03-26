-- String Utils
-- June 23rd, 2022
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)
local Sift = require(Packages.Sift)

-- // Util Variables \\

local StringUtils = {}

-- // Functions \\

function StringUtils.RichTextToNormal(RichTextString: string): string?
	return RichTextString:match("<.*>(.*)<.*>")
end

function StringUtils.SecondsToDHMS(Seconds: number): string
	local Days = math.floor(Seconds / 86400)
	local Hours = math.floor((Seconds % 86400) / 3600)
	local Minutes = math.floor(((Seconds % 86400) % 3600) / 60)
	local secs = math.floor(((Seconds % 86400) % 3600) % 60)
	return string.format("%02d:%02d:%02d:%02d", Days, Hours, Minutes, secs)
end

function StringUtils.SecondsToHMS(Seconds: number): string
	local Hours = math.floor(Seconds / 3600)
	local Minutes = math.floor((Seconds % 3600) / 60)
	local secs = math.floor((Seconds % 3600) % 60)
	return string.format("%02d:%02d:%02d", Hours, Minutes, secs)
end

function StringUtils.MapSecondsToStringTime(Seconds: number): string
	local DaysInSeconds = Seconds / 86400
	if DaysInSeconds >= 1 then
		return StringUtils.SecondsToDHMS(Seconds)
	else
		return StringUtils.SecondsToHMS(Seconds)
	end
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

function StringUtils.ContainsOnlySpaces(String: string): ...string?
	return String:match("^%s*$")
end

function StringUtils.GetPlayerFromString(Pattern: string, Exclude: { Player }): Player?
	for _, Player in Players:GetPlayers() do
		if Pattern:lower() == Player.Name:lower() then
			if Exclude and table.find(Exclude, Player) then
				continue
			end
			return Player -- Exact match
		end
		if Player.Name:sub(1, Pattern:len()):lower() == Pattern:lower() then
			if Exclude and table.find(Exclude, Player) then
				continue
			end
			return Player
		end
	end
	return nil
end

function StringUtils.GetReadTime(String: string): number
	return math.max(String:len() / 10, 5)
end

function StringUtils.PromiseReadTime(String: string)
	return Promise.delay(StringUtils.GetReadTime(String))
end

function StringUtils.GetFirstStringInAlphabet(StringList: { string }): (string, number)
	local alphabeticSort = Sift.Array.sort(StringList, function(a: string, b: string)
		return a:lower() < b:lower()
	end)
	return alphabeticSort[1], table.find(StringList, alphabeticSort[1]) :: number
end

return StringUtils
