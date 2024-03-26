--!strict

-- Combat Service
-- November 17th, 2022
-- Ron

-- // Variables \\

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local ActionShared = ReplicatedStorage.ActionShared
local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants
local Wrappers = ReplicatedStorage.wrappers
local Serde = ReplicatedStorage.serde

local Action = require(ActionShared.Action)
local AudioService = require(Services.AudioService)
local EntityModule = require(ActionShared.Entity)
local EntityService = require(Services.EntityService)
local Handlers = require(ActionShared.Handlers)
local HitFXSerde = require(Serde.HitFXSerde)
local Interfaces = require(ActionShared.Action.Interfaces)
local InventoryService = require(Services.InventoryService)
local ItemService = require(Services.ItemService)
local Remotes = require(ReplicatedStorage.Remotes)
local ServerComm = require(ServerScriptService.ServerComm)
local Sift = require(Packages.Sift)
local Signal = require(Packages.Signal)
local StatusModule = require(ActionShared.StatusModule)
local Types = require(Constants.Types)
local withEntityAndState = require(Wrappers.withEntityAndState)

local EntityRemotes = Remotes.Server:GetNamespace("Entity")
local ClientReady = EntityRemotes:Get("ClientReady")
local ProcessAction = EntityRemotes:Get("ProcessAction")
local FinishedClient = EntityRemotes:Get("FinishedClient")
local ProcessFX = EntityRemotes:Get("ProcessFX")

local HANDLER_NAMES = table.create(Sift.Dictionary.count(Handlers))
for _, Handler in pairs(Handlers) do
	table.insert(HANDLER_NAMES, Handler.Data.Name)
end

-- // Service \\
local ActionService = {
	Name = "ActionService",
	FinishedHooks = {},
	OnAction = Signal.new(),
	OnHit = Signal.new(),
	OnDamage = Signal.new(),
	CombatToggle = ServerComm:CreateProperty("CombatToggle", false),
}

-- // Functions \\
function ActionService:Init()
	self.RoundService = require(Services.RoundService) :: any

	EntityService.PlayerEntityReady:Connect(function(Player: Player, Entity: Types.Entity)
		ActionService:ToggleCombatSystem(false, Player) -- Disable combat for all players by default, and when they die.

		ClientReady:SendToPlayer(Player, Entity)
	end)

	Interfaces.Server.ProcessHit:Connect(function(...)
		local hitSuccess = ActionService:ProcessHitClient(...)
		if hitSuccess == false then
			-- Notify the client that the hit failed for any necessary rollback.
			local args = { ... }
			local _Player = args[1]
			local _ActionUUID = args[2]
			--ProcessHit:SendToPlayer(Player, ActionUUID, false)
		end
	end)

	ProcessAction:SetCallback(
		withEntityAndState(
			function(
				Player: Player,
				Entity: Types.Entity,
				EntityState: Types.EntityState,
				ActionType: string,
				ActionUUID: string,
				ActionPayload: { [string]: any }?
			)
				assert(Player.Character, "Player character does not exist yet.")
				local Handler = Handlers[ActionType]

				if not Handler then
					return false
				end

				if
					not ActionService.CombatToggle:GetFor(Player)
					and (Handler.Data.AlwaysOn and not Handler.Data.AlwaysOn() or not Handler.Data.AlwaysOn)
				then
					return false
				end -- Combat is disabled, don't do anything, no action processing.

				--[[if game.PlaceId == PlaceIds.Lobby and Handler.Data.IsBaseAction ~= true then
					return false -- No abilities in the lobby, except for base actions.
				end--]]

				-- Ensure that this action is currently equipped in our inventory if not a base action.
				if not Handler.Data.IsBaseAction then
					-- check if handler is associated w/ an item.
					local itemInfo = ItemService:GetItemFromName(Handler.Data.Name)
					if itemInfo then -- if it is, check to make sure it's equipped.
						local equippedItems = InventoryService:GetItemsOfId(Player, itemInfo.Id, true)
						if #equippedItems == 0 then -- if we don't have any equipped, don't let them do this action.
							return false
						end
					end
				end

				local processArgs, stateInfo = Action.Init(Handler, Entity, ActionUUID)
				if ActionPayload then
					processArgs.ActionPayload = ActionPayload -- Store the initial server load in the process args store, if it exists.
				end

				-- We'll verify the data sent from the client through the handler's verify function.
				local Verify, DoAction = Action.Run(Handler, Entity, EntityState, processArgs, stateInfo)

				local didResolve, _rollbackState = Verify():await()

				if didResolve then
					DoAction():catch(function(err: any, RollbackState: Types.EntityState)
						warn(tostring(err))
						EntityModule.ChangeState(Entity, RollbackState)
					end)
					return true
				else
					--warn(rollbackState)
					return false
				end
			end
		)
	)

	FinishedClient:Connect(function(Player: Player, ActionUUID: string)
		if not Player.Character then
			return false
		end

		local Entity, EntityState = EntityModule.GetEntityAndState(Player.Character :: Model)

		if not EntityState or not Entity then
			return false
		end

		if not EntityState.LastActionState then -- we can't finish an action if we don't have any potential action to finish.
			return false
		end

		local specifiedActionState = nil :: Types.ActionStateInfo?
		for _actionName, actionState in EntityState.ActionHistory do
			if actionState and actionState.UUID == ActionUUID then
				specifiedActionState = actionState
			end
		end

		-- can't finish an action that was already finished or doesn't exist.
		if not specifiedActionState or (specifiedActionState and specifiedActionState.Finished ~= false) then
			return false
		else
			-- satisfy luau type checker.
			assert(specifiedActionState, "Action state does not exist.")
			local Handler = Handlers[specifiedActionState.ActionHandlerName]

			local wasLastAction = EntityState.LastActionState == specifiedActionState

			if Handler and specifiedActionState then
				local HandlerData = Handler.Data
				if not specifiedActionState.Sustaining and HandlerData.Sustained then
					-- Action is a sustained action but finished is called while it is not being sustained.
					return false
				end

				-- If this is an action that is finished when the server finishes it, don't let the client finish it.
				if HandlerData.ServerFinish then
					return false
				end

				-- @CRITICAL LINE: We need to mark the action as finished before we update the entity state.
				specifiedActionState.Finished = true -- mark the initial action state as finished before updating entity state. this is important for our Common.ServerWaitForFinished process
				-- so that we don't get stuck waiting for an action that has already finished. we want to do this before cloning the action history so that the memory reference is the same.

				local actionHistory = table.clone(EntityState.ActionHistory)
				local newState = table.clone(EntityState)
				actionHistory[HandlerData.Name] = table.clone(specifiedActionState) :: Types.ActionStateInfo

				actionHistory[HandlerData.Name].Finished = true

				if HandlerData.Sustained then
					(actionHistory[HandlerData.Name] :: Types.ActionStateInfo).Sustaining = false
				end

				if wasLastAction then
					newState.LastActionState = actionHistory[HandlerData.Name] -- if this was our last action, update the last action state to the changed action state as well.
				end

				newState.ActionHistory = actionHistory

				EntityModule.ChangeState(Entity, newState)

				return true
			end
		end

		-- Realistically, if this fails, something will mess up.
		return false
	end)
end

function ActionService:ToggleCombatSystem(Toggle: boolean, Player: Player?)
	if Player then
		ActionService.CombatToggle:SetFor(Player, Toggle)
	else
		ActionService.CombatToggle:Set(Toggle)
	end
end

function ActionService:PlayAction(
	Entity: Types.Entity,
	Handler: Types.ActionHandler,
	AIPayload: { [string]: any }?
): boolean -- Returns whether or not the action was played (aka did the server process stack verify the action).
	local EntityState = EntityModule.GetState(Entity)
	assert(EntityState, "Entity does not have a state.")
	if EntityState then
		local ActionUUID = HttpService:GenerateGUID(false)
		local processArgs, stateInfo = Action.Init(Handler, Entity, ActionUUID)
		if AIPayload then -- If we have an AI payload, store it in the process args store.
			processArgs.Store.AIPayload = AIPayload
		end
		local Verify, DoAction = Action.Run(Handler, Entity, EntityState, processArgs, stateInfo)
		local didResolve, _rollbackState = Verify():await()

		if didResolve then
			if stateInfo.CancelPreviousAction then
				return true -- We don't want to do anything else. We just wanted to cancel the previous action.
			end
			DoAction():catch(function(_err: any, _RollbackState: Types.EntityState)
				--warn(tostring(err))
			end)
		end
		return didResolve
	end
	return false
end

function ActionService:ProcessHitClient(
	Player: Player,
	ActionUUID: string,
	ArgPack: Types.ProcessArgs,
	StateInfo: Types.ActionStateInfo,
	FromEntity: Types.Entity,
	FromState: Types.EntityState,
	Entry: Types.CasterEntry
)
	-- We do our general checks here.
	-- First, we check if this processhit is for our entity since we have multiple connections to the same callback.
	local entityPlayer = Players:GetPlayerFromCharacter(ArgPack.Entity)
	if (entityPlayer and Player ~= entityPlayer) or not Entry.Entity or not entityPlayer then
		print("H")
		return false
	end

	-- Then, we want to make sure that this action is the same action the entity wants to register a hit for by the UUID given to us.
	if StateInfo.UUID ~= ActionUUID then
		print("C")
		return false
	end

	local toEntity, toState = EntityModule.GetEntityAndState(Entry.Entity :: any)
	if not toState or not toEntity then
		print("D")
		return false
	end

	-- Then, we want to use the handler-specific sanity checks to make sure that this hit is valid before the general ActionService.ProcessHit logic.
	local runHandlerChecks = ArgPack.Callbacks.VerifyHits
	if runHandlerChecks then
		local checksPassed = runHandlerChecks(ArgPack, Entry.DetectionType, Entry)
		if not checksPassed then
			print("F")
			return false
		end
	end

	print("A")

	local didRun, processed = pcall(
		ActionService.ProcessHit,
		ActionService :: any,
		FromEntity,
		FromState,
		toEntity,
		toState,
		Entry,
		StateInfo,
		ArgPack
	)

	local wasHit = didRun and processed or didRun

	if not didRun then
		warn(tostring(processed))
	end

	if wasHit then
		local hitProcessed = ArgPack.Interfaces.Server.HitProcessed :: Signal.Signal<string, Types.CasterEntry>
		hitProcessed:Fire(StateInfo.UUID, Entry)
	end

	return wasHit
end

function ActionService:ProcessHit(
	Actor: Types.Entity,
	ActorState: Types.EntityState,
	Target: Types.Entity,
	_TargetState: Types.EntityState,
	Entry: Types.CasterEntry,
	StateInfo: Types.ActionStateInfo,
	ArgPack: Types.ProcessArgs
): boolean
	assert(ActorState.LastActionState, "No current action for acting entity.")

	local Handler = Handlers[StateInfo.ActionHandlerName]

	if (Actor :: any) == Target then
		return false
	end

	if Handler.Data.AttackLevel == 0 then -- we can't hit without an attack level.
		return false
	end

	-- We can't hit ourselves.

	local humanoidTarget = Target:FindFirstChildOfClass("Humanoid")

	if not humanoidTarget then
		return false
	end

	-- We can't hit entities on our team.
	if self.RoundService:OnSameTeam(Players:GetPlayerFromCharacter(Actor), Players:GetPlayerFromCharacter(Target)) then
		return false
	end

	local playerActor = Players:GetPlayerFromCharacter(Actor)

	local baseDamage = typeof(Handler.Data.BaseDamage) == "function" and Handler.Data.BaseDamage(Entry)
		or Handler.Data.BaseDamage

	local _canHit, props = ActionService:GetHitProps(Actor, Target, Handler, baseDamage :: number, nil, false)

	local hitProps = props :: Types.HitProps

	if playerActor then -- AI entities already fire this event on the server (because they live on the server), re-firing it will cause a "maximum C stack size exceeded" error. (inf fire loop)
		ArgPack.Store.OnHit:Fire(Entry) -- Fire the server on hit event.
	end

	if hitProps.DelayedDamage then
		for _, delayedDamageInfo in hitProps.DelayedDamage do
			task.delay(delayedDamageInfo.Delay, function()
				ActionService:DamageEntityFromHandler(Actor, Target, Handler, Entry, StateInfo, delayedDamageInfo)
			end)
		end
	else
		if hitProps.StoreInHitQueue == true then
			if not ArgPack.Store.HitQueue then
				ArgPack.Store.HitQueue = {}
			end
			-- If we want to store the hit in the hit queue, do that. If we're already in the hit queue, damage the entity.
			if table.find(ArgPack.Store.HitQueue, Entry.Entity) then
				ActionService:DamageEntityFromHandler(Actor, Target, Handler, Entry, StateInfo)
				table.remove(ArgPack.Store.HitQueue, table.find(ArgPack.Store.HitQueue, Entry.Entity))
			else
				table.insert(ArgPack.Store.HitQueue, Entry.Entity)
			end
		else
			ActionService:DamageEntityFromHandler(Actor, Target, Handler, Entry, StateInfo) -- Otherwise, damage the entity immediately.
		end
	end

	local hasOnHitFX = Handler.Callbacks["OnHit"] ~= nil
	if hasOnHitFX then
		local hitCFrame = Entry.RaycastResult and CFrame.new(Entry.RaycastResult.Position)
			or Entry.HitPart and Entry.HitPart:GetPivot()
			or Target and Target:GetPivot()
		local vfxArgs: Types.VFXArguments = {
			TargetEntity = Target,
			Actor = Actor,
			CFrame = hitCFrame,
		}

		if playerActor then
			-- Only send to other players. Our actor will handle the hit effects on their end.
			ProcessFX:SendToAllPlayersExcept(playerActor, Handler.Data.Name, "OnHit", HitFXSerde.Serialize(vfxArgs))
		else
			-- No player actor, so we can assume this is a server-side action.
			ProcessFX:SendToAllPlayers(Handler.Data.Name, "OnHit", HitFXSerde.Serialize(vfxArgs))
		end
	end

	return true
end

function ActionService:GetHitProps(
	FromEntity: Types.Entity,
	TargetEntity: Types.Entity,
	Handler: Types.ActionHandler,
	Damage: number,
	DelayedDamageProps: Types.DelayedDamageProps?,
	ApplyStatusEffects: boolean?
): (boolean, Types.HitProps?)
	local ToState = EntityModule.GetState(TargetEntity)
	local FromState = EntityModule.GetState(FromEntity)

	-- if blocking
	if ToState and FromState and Handler.Callbacks.ProcessHit then
		local handlerSpecificProcess = Handler.Callbacks.ProcessHit

		local canHit, hitProps =
			handlerSpecificProcess(FromEntity, TargetEntity, Damage, DelayedDamageProps, ApplyStatusEffects)

		return canHit, hitProps -- Can the player get hit by this attack?
	end

	if not Handler.Callbacks.ProcessHit then
		warn("Handler " .. Handler.Data.Name .. " does not have a ProcessHit callback.")
	end

	return false, nil -- The player wasn't hit by the attack.
end

function ActionService:DamageEntityFromHandler(
	Actor: Types.Entity,
	TargetEntity: Types.Entity,
	Handler: Types.ActionHandler,
	Entry: Types.CasterEntry,
	_StateInfo: Types.ActionStateInfo,
	DelayedDamageProps: Types.DelayedDamageProps?
): ()
	if StatusModule.HasStatus(TargetEntity, "Killed") then -- if the target is already killed, don't do anything.
		return
	end

	local humanoidTarget = TargetEntity:FindFirstChildOfClass("Humanoid") :: Humanoid

	local hitCFrame = Entry.RaycastResult and CFrame.new(Entry.RaycastResult.Position)
		or Entry.HitPart and Entry.HitPart:GetPivot()
		or TargetEntity and TargetEntity:GetPivot()
	local vfxArgs: Types.VFXArguments = {
		TargetEntity = TargetEntity,
		Actor = Actor,
		CFrame = hitCFrame,
	}

	-- @NOTE: Our canHit function will handle status effect logic as a side effect.

	local baseDamage = DelayedDamageProps and DelayedDamageProps.BaseDamage
		or typeof(Handler.Data.BaseDamage) == "function" and Handler.Data.BaseDamage(Entry)
		or Handler.Data.BaseDamage :: number

	if baseDamage >= humanoidTarget.Health then
		baseDamage = math.floor(humanoidTarget.Health - 1) -- we just want to take their damage away, not completely kill them due to humanoid behavior.
		-- apply the killed status effect.
		StatusModule.ApplyStatus(TargetEntity, "Killed", nil, nil, Actor)
	end

	humanoidTarget:TakeDamage(baseDamage)

	ActionService.OnDamage:Fire(Actor, TargetEntity, baseDamage, Handler)

	local hitNoise = Handler.Callbacks["HitNoise"]
	if hitNoise then -- Hit noise will return a preset name.
		AudioService:PlayPreset(hitNoise(), TargetEntity.PrimaryPart)
	end

	-- Show other clients any client-sided hit effects (specifically on damage hit effect callbacks) the handler may have.

	local hasOnDamageFX = Handler.Callbacks["OnDamage"] ~= nil
	if hasOnDamageFX then
		-- no client side prediction for damage effects, so we just send it to all clients. (we don't want some weird desync where client plays effects before indicator shows up)
		ProcessFX:SendToAllPlayers(Handler.Data.Name, "OnDamage", HitFXSerde.Serialize(vfxArgs))
	end
end

return ActionService
