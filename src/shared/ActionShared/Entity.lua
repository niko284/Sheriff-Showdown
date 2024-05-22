--!strict

-- Entity System
-- November 17th, 2022
-- Ron

-- // Module Variables \\

local EntityModule = {}

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils

local AnimationShared = require(Utils.AnimationShared)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local BUSY_STATUSES = { "Killed" }
local States: { [Types.Entity]: Types.EntityState } = {}
local PlayerStates: { [Player]: Types.EntityState } = {}

-- // Events \\
EntityModule.StateChanged = Signal.new()

-- // Module Functions \\
function EntityModule.GetState(Entity: Types.Entity): Types.EntityState?
	return States[Entity]
end

function EntityModule.ChangeState(Entity: Types.Entity, State: Types.EntityState): boolean
	local oldState = EntityModule.GetState(Entity)
	if typeof(Entity) == "Instance" then
		local PlayerFromEntity = Players:GetPlayerFromCharacter(Entity)
		if PlayerFromEntity then
			PlayerStates[PlayerFromEntity] = State
		end
	end
	States[Entity] = State
	EntityModule.StateChanged:Fire(Entity, State, oldState)
	return true
end

function EntityModule.GetAllEntityStates(): { [Types.Entity]: Types.EntityState }
	return States
end

function EntityModule.EraseState(Entity: Types.Entity?): ()
	if Entity then
		States[Entity] = nil
	end
end

function EntityModule.ChangeDefenseLevel(Entity: Types.Entity, NewDefenseLevel: number): Types.EntityState?
	local oldState = EntityModule.GetState(Entity)
	if not oldState then
		return nil
	else
		local newState = table.clone(oldState)
		newState.DefenseLevel = NewDefenseLevel
		States[Entity] = newState

		EntityModule.StateChanged:Fire(Entity, newState, oldState)

		return newState
	end
end

function EntityModule.ChangeActionState(Entity: Types.Entity, NewActionState: Types.ActionStateInfo): Types.EntityState?
	local oldState = EntityModule.GetState(Entity)
	if not oldState then
		return nil
	else
		local newState = table.clone(oldState)
		newState.LastActionState = NewActionState
		newState[NewActionState.ActionHandlerName] = newState.LastActionState
		States[Entity] = newState

		EntityModule.StateChanged:Fire(Entity, newState, oldState)

		return newState
	end
end

function EntityModule.AddStatus(
	Entity: Types.Entity,
	StatusName: Types.EntityStatus,
	StatusState: Types.EntityStatusState
): Types.EntityState?
	local oldState = EntityModule.GetState(Entity)
	if not oldState then
		return nil
	else
		local newState = table.clone(oldState)

		newState.Statuses = table.clone(newState.Statuses)

		newState.Statuses[StatusName] = StatusState

		States[Entity] = newState

		EntityModule.StateChanged:Fire(Entity, newState, oldState)

		return newState
	end
end

function EntityModule.ClearStatus(Entity: Types.Entity, StatusName: Types.EntityStatus): Types.EntityState?
	local oldState = EntityModule.GetState(Entity)
	if not oldState then
		return nil
	else
		local newState = table.clone(oldState)

		newState.Statuses = table.clone(newState.Statuses)

		newState.Statuses[StatusName] = nil

		States[Entity] = newState

		EntityModule.StateChanged:Fire(Entity, newState, oldState)

		return newState
	end
end

function EntityModule.IsBusy(Entity: Types.Entity): boolean
	local EntityState = EntityModule.GetState(Entity)
	assert(EntityState, "Entity State doesn't exist. Should've been made?")

	-- If our entity is busy, or if our entity is sustaining an action, we are currently busy. Mainly used as a check for Common.Verify delegate.

	local busyStatuses = {}
	for _, StatusState: Types.EntityStatusState in EntityState.Statuses do
		if table.find(BUSY_STATUSES, StatusState.Status) then
			table.insert(busyStatuses, StatusState)
		end
	end

	-- If we have any busy statuses, we are busy.
	if #busyStatuses > 0 and Entity:HasTag("Boss") ~= true then
		return true
	end

	return false
end

function EntityModule.MakeEntityState(CharacterModel: Model?): Types.Entity?
	assert(CharacterModel, "Character model doesn't exist.")
	local Entity = EntityModule.GetEntity(CharacterModel)
	if not Entity then
		return nil
	end
	local State = EntityModule.GetState(Entity)

	local PlayerFromEntity = Players:GetPlayerFromCharacter(Entity)
	local newStateToUse = PlayerFromEntity and PlayerStates[PlayerFromEntity]

	if State then
		return Entity
	else
		--@TODO retrieve relevant data for construction.
		States[Entity] = newStateToUse
			or {
				DefenseLevel = 0,
				AttackLevel = 0,
				Statuses = {},
				ActionHistory = {},
				LastActionState = nil,
			}

		if PlayerFromEntity then
			PlayerStates[PlayerFromEntity] = States[Entity]
		end

		AnimationShared.MakeAnimationInfo(Entity)

		return Entity
	end
end

function EntityModule.GetEntity(CharacterModel: Model?): Types.Entity?
	-- Type narrow our character model into an entity, if necessary.
	if
		CharacterModel
		and CharacterModel:FindFirstChild("HumanoidRootPart")
		and CharacterModel:FindFirstChild("Humanoid")
		and CollectionService:HasTag(CharacterModel, "Entity")
		and CharacterModel:IsDescendantOf(workspace)
	then
		return CharacterModel :: Types.Entity
	end

	return nil
end

function EntityModule.GetNestedEntity(EntityInstance: Instance?): Types.Entity?
	-- Find our first parent that is potentially an entity.
	if EntityModule.GetEntity(EntityInstance :: Model) then
		return EntityInstance :: Types.Entity
	end
	repeat
		EntityInstance = EntityInstance and EntityInstance.Parent or nil
	until EntityInstance == nil or EntityModule.GetEntity(EntityInstance :: Model)

	return EntityInstance ~= nil and EntityInstance :: Types.Entity or nil
end

function EntityModule.GetEntitiesInRange(
	ReferenceEntity: Types.Entity,
	Range: number,
	IgnoreEntities: { Types.Entity }?
): { Types.Entity }
	local EntitiesInRange: { Types.Entity } = {}

	for _, Entity in CollectionService:GetTagged("Entity") do
		if IgnoreEntities and table.find(IgnoreEntities, Entity) then
			continue
		end
		local EntityState = EntityModule.GetState(Entity)
		if EntityState then
			local EntityPosition = Entity.HumanoidRootPart.Position
			local ReferencePosition = ReferenceEntity.HumanoidRootPart.Position
			local Distance = (EntityPosition - ReferencePosition).Magnitude
			if Distance <= Range then
				table.insert(EntitiesInRange, Entity)
			end
		end
	end

	return EntitiesInRange
end

function EntityModule.GetEntityAndState(CharacterModel: Model?): (Types.Entity?, Types.EntityState?)
	-- Type narrow our character model into an entity, if necessary.
	local Entity = EntityModule.GetEntity(CharacterModel)
	local State: Types.EntityState? = nil

	if Entity then
		State = EntityModule.GetState(Entity)
	else
		return nil, nil
	end

	local charModel = CharacterModel :: Model

	if not Entity then
		warn(string.format("Couldn't grab entity for model '%s'", charModel.Name))
	end

	if not State and Entity then
		warn(string.format("Couldn't grab state for model '%s'", charModel.Name))
	end

	return Entity, State
end

Players.PlayerRemoving:Connect(function(Player: Player)
	if PlayerStates[Player] then
		PlayerStates[Player] = nil
	end
end)

return EntityModule
