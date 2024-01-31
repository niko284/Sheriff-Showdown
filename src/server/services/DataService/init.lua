--!strict

-- Data Service
-- January 22nd, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPackages = ServerScriptService.ServerPackages
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local ProfileSchema = require(script.ProfileSchema)
local ProfileService = require(ServerPackages.ProfileService)
local Promise = require(Packages.Promise)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local MAX_LOAD_RETRIES = 10
local PROFILE_STORE = ProfileService.GetProfileStore("SheriffShowdownPlayerData", ProfileSchema) :: any

-- // Service Variables \\

local DataService = {
	Name = "DataService",
	Profiles = {},
	BeforeReleaseCallbacks = {},
	DataSessionLock = {},
	PlayerDataLoaded = Signal.new(),
	PlayerDataReleasing = Signal.new(),
}

type BeforeReleaseCallback = {
	Callback: (Player) -> (),
}
type releaseHandlerType = "Repeat" | "Cancel" | "Steal" | "ForceLoad"
export type PlayerProfile = ProfileService.Profile<Types.PlayerData, any, any>

-- // Functions \\

function DataService:Init()
	print("Initializing " .. self.Name)
	DataService.ProfileStore = PROFILE_STORE
	if RunService:IsStudio() then
		DataService.ProfileStore = DataService.ProfileStore.Mock -- Mock the profile store if we are in studio.
	end
end

function DataService:GetProfileStore()
	return PROFILE_STORE
end

function DataService:OnPlayerAdded(Player: Player)
	print("Added")
	-- Award the player the welcome badge if they don't have it.
	--[[BadgeUtils.PromiseHasBadgeAsync(Player.UserId, Badges.Welcome)
		:andThen(function(HasBadge: boolean)
			if not HasBadge then
				return BadgeUtils.PromiseAwardBadgeAsync(Player.UserId, Badges.Welcome)
			end
			return Promise.resolve()
		end)
		:catch(function(_err) end)--]]

	DataService:LoadData(Player)
end

function DataService:OnPlayerRemoving(Player: Player)
	if not DataService:IsSessionLocked(Player) then
		DataService:SaveData(Player)
	end
end

function DataService:LockSession(Player: Player)
	DataService.DataSessionLock[Player] = true
	return Promise.resolve()
end

function DataService:UnlockSession(Player: Player)
	DataService.DataSessionLock[Player] = nil
	return Promise.resolve()
end

function DataService:IsSessionLocked(Player: Player): boolean
	return DataService.DataSessionLock[Player] == true
end

function DataService:LoadProfile(PlayerDataKey: string, ReleaseHandler: ((number, number) -> releaseHandlerType)?)
	return Promise.new(function(resolve, reject)
		local Success, Profile = pcall(function()
			return DataService.ProfileStore:LoadProfileAsync(PlayerDataKey, ReleaseHandler)
		end)
		if Success and Profile then
			resolve(Profile)
		elseif Success and not Profile then
			reject("Profile not found") -- Profile not found, profileservice call returned nil.
		else
			reject(Profile) -- LoadProfileAsync errored and returned an error message.
		end
	end)
end

function DataService:LoadData(Player: Player)
	print("Loading")
	local PlayerDataKey = "PlayerData_" .. Player.UserId
	return Promise.retryWithDelay(DataService.LoadProfile, MAX_LOAD_RETRIES, 3, DataService, PlayerDataKey, function()
		-- We return repeat since we want to retry if the profile is not found, but not steal it since it might have a trade session lock.
		return "ForceLoad"
	end):andThen(function(PlayerProfile: any)
		-- Our promise might resolve with nil if the profile is not found, so we need to check for that.
		if not PlayerProfile then
			return
		else
			PlayerProfile:Reconcile()
			PlayerProfile:AddUserId(Player.UserId)
			PlayerProfile:ListenToRelease(function()
				if DataService:GetData(Player) then
					DataService.Profiles[Player.UserId] = nil
				end
				-- Player:Kick("Your data has been disconnected from the server.")
			end)

			for _, update in ipairs(PlayerProfile.GlobalUpdates:GetActiveUpdates()) do
				PlayerProfile.GlobalUpdates:LockActiveUpdate(update[1])
			end

			PlayerProfile.GlobalUpdates:ListenToNewActiveUpdate(function(update_id, _update_data)
				PlayerProfile.GlobalUpdates:LockActiveUpdate(update_id)
			end)
			PlayerProfile.GlobalUpdates:ListenToNewLockedUpdate(function(update_id, updateData)
				DataService:HandleGlobalUpdate(PlayerProfile, updateData);

				(PlayerProfile :: any).GlobalUpdates:ClearLockedUpdate(update_id)
			end)

			for _, update in ipairs((PlayerProfile :: any).GlobalUpdates:GetLockedUpdates()) do
				local updateId = update[1]
				local updateData = update[2]
				DataService:HandleGlobalUpdate(PlayerProfile, updateData);
				(PlayerProfile :: any).GlobalUpdates:ClearLockedUpdate(updateId)
			end

			if Player:IsDescendantOf(Players) then
				DataService.Profiles[Player.UserId] = PlayerProfile
				print("Firing")
				DataService.PlayerDataLoaded:Fire(Player, PlayerProfile)
			else
				PlayerProfile:Release()
			end
		end
	end)
end

function DataService:GetData(Player: Player): PlayerProfile
	return DataService.Profiles[Player.UserId]
end

function DataService:ViewProfile(ProfileKey: string)
	return DataService.ProfileStore:ViewProfileAsync(ProfileKey)
end

function DataService:HandleGlobalUpdate(PlayerProfile: PlayerProfile, UpdateData: { Type: string, [string]: any })
	if UpdateData.Type == "WipeData" then
		PlayerProfile.Data = ProfileSchema -- Set the data to the default schema, we're wiping it.
	elseif UpdateData.Type == "TransferData" then
		if UpdateData.ProfileData then
			PlayerProfile.Data = UpdateData.ProfileData
		end
	end
end

function DataService:AwaitData(Player: Player)
	local PlayerData = DataService:GetData(Player)
	if PlayerData then
		return Promise.resolve(PlayerData)
	else
		return Promise.race({
			Promise.fromEvent(DataService.PlayerDataLoaded, function(LoadedPlayer: Player)
				return Player.UserId == LoadedPlayer.UserId
			end):andThen(function(_, Data: PlayerProfile)
				return Data
			end),
			Promise.fromEvent(DataService.PlayerDataReleasing, function(ReleasingPlayer: Player)
				return Player.UserId == ReleasingPlayer.UserId
			end):andThen(function()
				return Promise.reject("Player data is being released.")
			end),
		})
	end
end

function DataService:SaveData(Player: Player)
	local PlayerData = DataService:GetData(Player) :: PlayerProfile
	if PlayerData then
		DataService.PlayerDataReleasing:Fire(Player, PlayerData)
		local promiseReleaseCallbacks = Sift.Array.map(
			DataService.BeforeReleaseCallbacks,
			function(callbackInfo: BeforeReleaseCallback)
				return callbackInfo.Callback(Player)
			end
		)
		Promise.allSettled(promiseReleaseCallbacks)
			:finally(function()
				PlayerData:Release()
			end)
			:catch(function(err)
				warn("Error in release callbacks: " .. tostring(err))
			end)
	end
end

return DataService
