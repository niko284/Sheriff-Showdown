--!strict

-- Action
-- November 17th, 2022
-- Ron

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages

local Interfaces = require(script.Interfaces)
local Janitor = require(Packages.Janitor)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local IS_SERVER = RunService:IsServer()
local Action = {}

Action.LastActionStates = {} :: {
	[Types.Entity | Player]: {
		[Types.ActionHandler]: {
			ActionState: Types.ActionStateInfo,
			ArgPack: Types.ProcessArgs,
		}?,
		LastActionState: {
			ActionState: Types.ActionStateInfo,
			ArgPack: Types.ProcessArgs,
		}?,
	},
}

-- Builds the parameters to run the action. We build them in a different function to access them while the action is running in different scopes.
function Action.Init(
	Handler: Types.ActionHandler,
	Entity: Types.Entity,
	ActionUUID: string,
	InputObject: InputObject?
): (Types.ProcessArgs, Types.ActionStateInfo)
	local NowMillis = DateTime.now().UnixTimestampMillis
	local ProcessArgs: Types.ProcessArgs = {
		Entity = Entity,
		Finished = Signal.new(),
		Callbacks = Handler.Callbacks,
		Store = {
			OnHit = Signal.new(),
		},
		HitVerifiers = {},
		HandlerData = Handler.Data,
		Interfaces = Interfaces,
		Janitor = Janitor.new(),
		Handler = Handler,
		InputObject = InputObject,
		EntityIsPlayer = Players:GetPlayerFromCharacter(Entity),
	}

	local StateInternal: Types.ActionStateInfo = {
		Finished = false,
		TimestampMillis = NowMillis,
		GlobalCooldownFinishTimeMillis = NowMillis + Handler.Data.GlobalCooldownMillis,
		CooldownFinishTimeMillis = NowMillis + Handler.Data.CooldownMillis,
		ActionHandlerName = Handler.Data.Name,
		ActionSpecific = {},
		Sustaining = Handler.Data.Sustained,
		Interruptable = if Handler.Data.Interruptable == nil then true else Handler.Data.Interruptable,
		Priority = Handler.Data.Priority,
		UUID = ActionUUID,
	}

	return ProcessArgs, StateInternal
end

function Action.CanRunAction(Entity: Types.Entity, Handler: Types.ActionHandler): boolean
	local ProcessArgs, StateInternal = Action.Init(Handler, Entity, "")

	local isEntityAI = not Players:GetPlayerFromCharacter(Entity)

	-- Run through the verify stack to see if we can run the action.

	for _, Verifier in Handler.ProcessStack.VerifyStack do
		-- Run this process only on its respective environment.
		if Verifier.OnAI and (not isEntityAI or not IS_SERVER) then
			continue -- We only want to run OnAI processes on the server for AI entities.
		elseif Verifier.OnAI == false and isEntityAI then
			continue
		end
		if (IS_SERVER and not Verifier.OnServer) or (not IS_SERVER and not Verifier.OnClient) then
			continue
		end
		if Verifier.ProcessName == "ChangeState" then
			-- We don't want to run the ChangeState process here, as it's not a verify process but falls under the verify stack.
			continue
		end

		local isSuccess, DelegateFinished, _ = pcall(Verifier.Delegate, ProcessArgs, StateInternal)
		if not isSuccess or not DelegateFinished then
			return false
		end
	end

	return true
end

function Action.Run(
	Handler: Types.ActionHandler,
	Entity: Types.Entity,
	EntityState: Types.EntityState,
	ProcessArgs: Types.ProcessArgs,
	StateInternal: Types.ActionStateInfo
): (() -> Types.Promise, () -> Types.Promise)
	local RollbackState: Types.EntityState = table.clone(EntityState)

	local isEntityAI = not Players:GetPlayerFromCharacter(Entity)

	return function(): Types.Promise
		return Promise.new(function(resolve, reject, _onCancel)
			for _, Verifier in Handler.ProcessStack.VerifyStack do
				-- Run this process only on its respective environment.
				if isEntityAI and Verifier.OnAI and not IS_SERVER then
					continue -- We only want to run OnAI processes on the server for AI entities.
				elseif isEntityAI and not Verifier.OnAI then -- @note: so, OnServer actions only execute on the server for non-AI entities. must explicitly set OnAI to true to run on the server for AI entities.
					continue
				end
				if
					((IS_SERVER and not Verifier.OnServer) or (not IS_SERVER and not Verifier.OnClient)) and not isEntityAI
				then
					continue
				end

				local isSuccess, DelegateFinished, DelegateResponse = pcall(Verifier.Delegate, ProcessArgs, StateInternal)
				if not isSuccess or not DelegateFinished then
					if not isSuccess then
						warn(isSuccess, DelegateFinished, Verifier.ProcessName)
					end
					reject(
						string.format(
							"Could not verify at [%s] process in action [%s]",
							Verifier.ProcessName,
							Handler.Data.Name
						),
						RollbackState
					)
					break
				elseif DelegateResponse == "Cancelled" then
					break -- skip the rest of the processes, we want to cancel our previous action.
				end
			end

			resolve(RollbackState, ProcessArgs.ActionPayload)
		end)
	end, function(): Types.Promise
		return Promise.new(function(resolve, reject, _onCancel)
			-- Connect once to the finished signal to prevent multiple calls. Might cause undesired behavior.
			ProcessArgs.Finished:Once(function(isSuccess: boolean, FinishedWithProcess: string, fireJanitor: boolean?)
				StateInternal.Finished = true
				StateInternal.Sustaining = false

				-- Rest should be GCed?
				if fireJanitor ~= false then
					ProcessArgs.Janitor:Destroy()
				end

				-- If the action is finished, notify the client that the action is finished if applicable, or the server if applicable.
				local plrEntity = Players:GetPlayerFromCharacter(ProcessArgs.Entity) -- Might be an AI entity so we don't want to send to a client.

				-- We only want to send finished signal if our action succeeded. For example, the client doesn't want to send a finished signal to the server if the server rolled back the action.
				-- (this is because isSuccess will return false if the server rolled back the action the client initiated due to some check/prediction failure)
				if IS_SERVER and ProcessArgs.HandlerData.ServerFinish and plrEntity then
					ProcessArgs.Interfaces.Comm.FinishedServer:SendToPlayer(plrEntity)
				elseif not IS_SERVER and ProcessArgs.HandlerData.ServerFinish ~= true then -- if we cancel the previous action, running it again will already cancel it on the server.
					ProcessArgs.Interfaces.Comm.FinishedClient:SendToServer(StateInternal.UUID)
				end

				-- Update our defense/attack levels when our action is finished.
				if Handler.Data.DefenseLevel then
					EntityState.DefenseLevel -= Handler.Data.DefenseLevel
				end
				if Handler.Data.AttackLevel then
					EntityState.AttackLevel -= Handler.Data.AttackLevel
				end

				if not isSuccess then
					reject(
						string.format(
							"Couldn't complete a process delegate [%s] for action [%s].",
							FinishedWithProcess,
							Handler.Data.Name
						),
						RollbackState
					)
				end

				resolve(StateInternal)
			end)

			for _index, Process in Handler.ProcessStack.ActionStack do
				-- Early exit primarily for async processes
				if StateInternal.Finished then
					break
				end

				-- Run this process only on its respective environment.
				if isEntityAI and Process.OnAI and not IS_SERVER then
					continue -- We only want to run OnAI processes on the server for AI entities.
				elseif isEntityAI and not Process.OnAI then
					continue
				end
				if ((IS_SERVER and not Process.OnServer) or (not IS_SERVER and not Process.OnClient)) and not isEntityAI then
					continue
				end

				if Process.Async then
					task.spawn(function()
						local Success, DelegateFinished, _DelegateResponse =
							pcall(Process.Delegate, ProcessArgs, StateInternal)
						if not DelegateFinished or not Success then
							if not Success then
								warn(DelegateFinished)
							end
							ProcessArgs.Finished:Fire(false, Process.ProcessName)
						end
					end)
				else
					local Success, DelegateFinished, _DelegateResponse = pcall(Process.Delegate, ProcessArgs, StateInternal)
					if not DelegateFinished or not Success then
						if not Success then
							warn(DelegateFinished, debug.traceback())
						end
						ProcessArgs.Finished:Fire(false, Process.ProcessName)
					end
				end
			end
		end)
	end
end

function Action.FinishAction(Entity: Types.Entity, ServerRolledBack: boolean?, HandlerName: Types.ActionHandler?)
	local lastActionStates = Action.LastActionStates[Entity]
	if not lastActionStates then
		return
	end

	local PreviousActionState = lastActionStates.LastActionState
	if HandlerName then
		PreviousActionState = lastActionStates[HandlerName]
	end
	if PreviousActionState and PreviousActionState.ActionState.Finished == false then
		-- If our server is ending the previous action early due to rollback from client-side prediction failure, we want the client to know that so they don't get stuck in an action.
		-- We also don't want them to fire the finished signal back to the server, as the server didn't even process the action.
		local finished = true
		if ServerRolledBack then
			finished = false
		end
		if Janitor.Is(PreviousActionState.ArgPack.Janitor) then
			PreviousActionState.ArgPack.Janitor:Cleanup()
		end
		PreviousActionState.ArgPack.Finished:Fire(finished, PreviousActionState.ActionState.ActionHandlerName, false)
		lastActionStates[(if HandlerName then HandlerName else "LastActionState") :: any] = nil -- cleanup
	end
end

function Action.FinishAll(Entity: Types.Entity)
	local lastActionStates = Action.LastActionStates[Entity]
	if not lastActionStates then
		return
	end

	for _, actionState in pairs(lastActionStates) do
		if actionState and actionState.ActionState.Finished == false then
			if Janitor.Is(actionState.ArgPack.Janitor) then
				actionState.ArgPack.Janitor:Cleanup()
			end
			actionState.ArgPack.Finished:Fire(false, actionState.ActionState.ActionHandlerName, false)
		end
	end

	table.clear(lastActionStates)
end

for _, Entity in CollectionService:GetTagged("Entity") do
	Action.LastActionStates[Entity] = {}
	local PlayerFromCharacter = Players:GetPlayerFromCharacter(Entity)
	if PlayerFromCharacter then
		Action.LastActionStates[PlayerFromCharacter] = {}
	end
end

CollectionService:GetInstanceAddedSignal("Entity"):Connect(function(Entity: Types.Entity)
	local PlayerFromCharacter = Players:GetPlayerFromCharacter(Entity)
	local newStateToUse = PlayerFromCharacter and Action.LastActionStates[PlayerFromCharacter]
	Action.LastActionStates[Entity] = newStateToUse or {}
	if PlayerFromCharacter then
		Action.LastActionStates[PlayerFromCharacter] = Action.LastActionStates[Entity]
	end
end)

CollectionService:GetInstanceRemovedSignal("Entity"):Connect(function(Entity: Types.Entity)
	if Action.LastActionStates[Entity] then
		-- if we're removing an entity, we want to finish the action they were doing to avoid action bugs like hanging.
		Action.FinishAll(Entity)
		Action.LastActionStates[Entity] = nil
	end
end)

Players.PlayerRemoving:Connect(function(Player: Player)
	if Action.LastActionStates[Player] then
		Action.LastActionStates[Player] = nil
	end
end)

return Action
