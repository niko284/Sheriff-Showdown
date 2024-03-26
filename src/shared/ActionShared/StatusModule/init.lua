--!strict

-- Status Handler
-- October 11th, 2022
-- Ron

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ActionShared = ReplicatedStorage.ActionShared
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local StatusModules = script:GetDescendants()

local EntityModule = require(ActionShared.Entity)
local Janitor = require(Packages.Janitor)
local Remotes = require(ReplicatedStorage.Remotes)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local IS_SERVER = RunService:IsServer()
local IS_CLIENT = RunService:IsClient()

if IS_SERVER then
	Remotes.Server:GetNamespace("Entity"):Get("ProcessStatusFX")
end

type StatusInternal = { Data: Types.StatusData, EndMillis: number, Cleaner: Types.Janitor? }

local StatusModule = {
	StatusApplied = Signal.new() :: Signal.Signal<Types.Entity, Types.EntityStatus>,
}
local StatusHandlers: { [Types.EntityStatus]: Types.StatusHandler } = {}
local Statuses: { [Types.Entity]: { [Types.EntityStatus]: StatusInternal } } = {}

for _, StatusHandlerModule: Instance in StatusModules do
	if StatusHandlerModule:IsA("ModuleScript") then
		local Success, err = pcall(function()
			local StatusHandler: Types.StatusHandler = require(StatusHandlerModule) :: any

			if StatusHandler then
				StatusHandlers[StatusHandler.Data.Name] = StatusHandler
			end
		end)

		if not Success then
			warn(
				string.format(
					"Could not load handler module '%s' \nError:[%s]",
					StatusHandlerModule.Name,
					tostring(err)
				)
			)
		end
	end
end

function StatusModule.GetStatusHandler(Status: Types.EntityStatus): Types.StatusHandler?
	return StatusHandlers[Status]
end

function StatusModule.HasStatus(Entity: Types.Entity, Status: Types.EntityStatus): boolean
	if IS_SERVER then
		local CurrentStatuses = Statuses[Entity]
		if CurrentStatuses and CurrentStatuses[Status] then
			return true
		end
	elseif IS_CLIENT then
		local EntityState = EntityModule.GetState(Entity)
		if EntityState and EntityState.Statuses then
			for _, statusState in EntityState.Statuses do
				if statusState.Status == Status then
					return true
				end
			end
		end
	end
	return false
end

function StatusModule.IsStatus(Status: string): boolean
	return StatusHandlers[Status :: any] ~= nil
end

function StatusModule.ApplyStatus(
	Entity: Types.Entity,
	Status: Types.EntityStatus,
	IgnoreReplicationFXList: { Player }?,
	DurationMillis: number?,
	...: any
): (boolean, Janitor.Janitor?)
	print("Applying status", Status, "to", Entity.Name)

	if not IS_SERVER then
		warn("Tried applying status from client. Only apply statuses on server.")
		return false
	end

	local CurrentStatuses = Statuses[Entity]
	local NowMillis = DateTime.now().UnixTimestampMillis

	local StatusHandler = StatusModule.GetStatusHandler(Status)
	assert(StatusHandler, string.format("Could not find status handler for status '%s'", tostring(Status)))
	assert(CurrentStatuses, string.format("Could not find status data for entity '%s'", tostring(Entity.Name)))

	-- Clear any statuses that we can't overlap with.
	local StatusIntersections = StatusHandler.Data.CompatibleStatuses
	if StatusIntersections then
		-- If the status can overlap with a specific list of statuses only, then we need to clear all statuses that aren't in the list and only IF that status is not compatible
		-- with everything (i.e. if it's true, then we don't need to clear anything), even if it's not in the overlap list (other than exceptions)
		for CurrentStatus: Types.EntityStatus, _ in CurrentStatuses do
			local ThisStatusHandler = StatusModule.GetStatusHandler(CurrentStatus) :: Types.StatusHandler
			local ThisExceptions = ThisStatusHandler.Data.Exceptions
			if
				typeof(StatusIntersections) == "table"
				and not table.find(StatusIntersections, CurrentStatus)
				and ThisStatusHandler.Data.CompatibleStatuses ~= true
			then
				if ThisStatusHandler.Data.OverlapWithSelf == false and Status == CurrentStatus then
					StatusModule.ClearStatus(Entity, CurrentStatus)
				end
				if CurrentStatus == Status then
					continue -- We don't want to clear the status we're applying if it's supposed to overlap with itself.
				end
				StatusModule.ClearStatus(Entity, CurrentStatus)
			elseif ThisStatusHandler.Data.CompatibleStatuses == true then
				-- if this status is compatible w/ everything but maybe not itself, clear it.
				-- if there's exceptions to being compatible with everything, then we need to check if the status is in the exceptions list.
				if ThisExceptions and table.find(ThisExceptions, Status) then
					-- if the status in the exceptions list, clear it.
					StatusModule.ClearStatus(Entity, CurrentStatus)
				end
				if Status == CurrentStatus and ThisStatusHandler.Data.OverlapWithSelf == false then
					StatusModule.ClearStatus(Entity, CurrentStatus)
				end
			end
		end
	end

	local player = Players:GetPlayerFromCharacter(Entity)

	local entityState = EntityModule.GetState(Entity)
	-- Make any applicable changes to the entity state based on the status.
	if StatusHandler.Process and entityState then
		StatusHandler.Process(Entity, entityState, ...)
		if player then
			Remotes.Server:GetNamespace("Entity"):Get("ProcessStatus"):SendToPlayer(player, Status, ...)
		end
	end

	local didApply, Cleaner = StatusHandler.Apply(Entity, ...)

	if didApply then
		if StatusHandler.ApplyFX then
			local processStatusFX = Remotes.Server:GetNamespace("Entity"):Get("ProcessStatusFX")

			-- Players to ignore the playing of the status FX for. Used in scenarios like when the actor predicts the status of an entity and plays the FX locally.
			if IgnoreReplicationFXList then
				local playersReplicate = Sift.Array.filter(Players:GetPlayers(), function(plr)
					return not table.find(IgnoreReplicationFXList, plr)
				end)
				processStatusFX:SendToPlayers(playersReplicate, Entity, Status)
			else
				processStatusFX:SendToAllPlayers(Entity, Status)
			end
		end

		-- For statuses that have a process function, we want to send a signal to the player entity whose entity state is affected by the status to change their state based on the status.
		-- on their end.

		-- Treat additional occurrences of the same status slightly differently.
		local sameStatus = CurrentStatuses[Status]

		local newDuration = (DurationMillis or StatusHandler.Data.DurationMillis) :: number

		if sameStatus and sameStatus.EndMillis then
			-- If the status is already applied, just refresh the end time to now + duration. Basically, we're just reappling the status.
			sameStatus.EndMillis = NowMillis + newDuration
			EntityModule.AddStatus(
				Entity,
				Status,
				{
					Status = Status,
					EndMillis = sameStatus.EndMillis, -- refresh the end time on our entity state.
				} :: Types.EntityStatusState
			)
			return true
		end

		local StatusData = table.clone(StatusHandlers[Status].Data)

		-- override the duration if one was specified when applying the status.
		if StatusData and DurationMillis then
			StatusData.DurationMillis = DurationMillis
		end

		CurrentStatuses[Status] = {
			Data = StatusData,
			EndMillis = (newDuration and NowMillis + newDuration or nil) :: any,
		}

		if Cleaner then
			CurrentStatuses[Status]["Cleaner"] = Cleaner
		end

		EntityModule.AddStatus(
			Entity,
			Status,
			{
				Status = Status,
				EndMillis = CurrentStatuses[Status].EndMillis,
			} :: Types.EntityStatusState
		)

		StatusModule.StatusApplied:Fire(Entity, Status)

		return true, Cleaner
	end

	return false
end

function StatusModule.ClearStatus(Entity: Types.Entity, Status: Types.EntityStatus): boolean
	local CurrentStatuses = Statuses[Entity]

	if CurrentStatuses and CurrentStatuses[Status] then
		local CurrentStatus = CurrentStatuses[Status]
		Statuses[Entity][Status] = nil
		task.spawn(function()
			StatusHandlers[CurrentStatus.Data.Name].Clear(Entity, CurrentStatus.Cleaner)
		end)
		EntityModule.ClearStatus(Entity, Status)
		return true
	end

	return false
end

function StatusModule.ClearAllStatuses(Entity: Types.Entity): boolean
	local CurrentStatuses = Statuses[Entity]

	if CurrentStatuses then
		for Status: Types.EntityStatus, _ in CurrentStatuses do
			StatusModule.ClearStatus(Entity, Status)
		end
	end

	return true
end

function StatusModule.GetStatusHandlers()
	return StatusHandlers
end

if IS_SERVER then
	RunService.Stepped:Connect(function()
		local NowMillis = DateTime.now().UnixTimestampMillis

		for Entity, EntityStatuses in Statuses do
			for StatusName: Types.EntityStatus, Status in EntityStatuses do
				if Status.EndMillis and NowMillis > Status.EndMillis then
					StatusModule.ClearStatus(Entity, StatusName)
				end
			end
		end
	end)
	CollectionService:GetInstanceAddedSignal("Entity"):Connect(function(Entity: Types.Entity)
		Statuses[Entity] = {}
	end)
	CollectionService:GetInstanceRemovedSignal("Entity"):Connect(function(Entity: Types.Entity)
		--StatusModule.ClearAllStatuses(Entity) -- clear all statuses on the entity when it's removed.
		Statuses[Entity] = nil
	end)
	for _, Entity in CollectionService:GetTagged("Entity") do
		Statuses[Entity] = {}
	end
else
	Remotes.Client
		:GetNamespace("Entity")
		:Get("ProcessStatusFX")
		:Connect(function(Entity: Types.Entity, Status: Types.EntityStatus)
			local applyFX = StatusHandlers[Status].ApplyFX
			assert(applyFX, "Must have a function for applying FX.")
			applyFX(Entity)
		end)
end

return StatusModule
