--!strict

local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)

local PlayerUtils = {}

type Friend = {
	Id: number,
	Username: string,
	IsOnline: boolean,
}
type Group = {
	Name: string,
	Id: number,
	EmblemUrl: string,
	EmblemId: number,
	Rank: number,
	Role: string,
	IsPrimary: boolean,
	IsInClan: boolean,
}

function PlayerUtils.GetFriendsAsync(UserId: number)
	return Promise.new(function(resolve, reject)
		local success, friendPages = pcall(function()
			return Players:GetFriendsAsync(UserId)
		end)
		if success and friendPages then
			local friends: { Friend } = {}
			while true do
				local currentPage = friendPages:GetCurrentPage()
				for _, friend: Friend in currentPage do
					table.insert(friends, friend)
				end
				if friendPages.IsFinished then
					break
				end
				friendPages:AdvanceToNextPageAsync()
			end
			resolve(friends)
		else
			reject(success) -- success is the error message
		end
	end)
end

function PlayerUtils.PromiseMagnitudeMinimumPlayer(Player: Player, Part: BasePart, Magnitude: number)
	return Promise.new(function(resolve, reject)
		local connection
		if (Player.Character and not Player.Character.PrimaryPart) or not Part then
			reject()
			return
		end
		connection = RunService.Heartbeat:Connect(function()
			if
				Player.Character
				and Player.Character.PrimaryPart
				and Part
				and (Player.Character.PrimaryPart.Position - Part.Position).Magnitude <= Magnitude
			then
				connection:Disconnect()
				resolve()
			elseif Player:IsDescendantOf(Players) == false or not Player.Character then
				connection:Disconnect()
				reject()
			end
		end)
	end)
end

function PlayerUtils.IsFriendsWith(Friends: { Friend }, UserId: number): boolean
	for _, Friend in Friends do
		if Friend.Id == UserId then
			return true
		end
	end
	return false
end

function PlayerUtils.GetRankInGroup(Player: Player, GroupId: number): number
	local success, rank = pcall(function()
		return Player:GetRankInGroup(GroupId)
	end)
	if success then
		return rank
	else
		return 0
	end
end

function PlayerUtils.GetPlayerFromName(Name: string): Player?
	for _, Player in Players:GetPlayers() do
		if Player.Name:lower() == Name:lower() then
			return Player
		end
	end
	return nil
end

function PlayerUtils.GetNameFromUserId(UserId: number): string?
	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(UserId)
	end)
	if success then
		return name
	else
		return nil
	end
end

function PlayerUtils.GetDisplayNamesFromUserIds(UserIds: { number }): { string }?
	local success, result = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(UserIds)
	end)
	if success then
		local displayNames = {}
		for index, info in ipairs(result) do
			displayNames[UserIds[index]] = info.DisplayName
		end
		return displayNames
	else
		return nil
	end
end

function PlayerUtils.GetPlayerGroups(UserId: number): { Group }
	local Success, GroupInfo = pcall(function()
		return GroupService:GetGroupsAsync(UserId)
	end)
	if Success then
		return GroupInfo
	else
		return {}
	end
end

return PlayerUtils
