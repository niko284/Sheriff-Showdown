--!strict

-- Entity Controller
-- October 1st, 2022
-- Nick

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local ActionShared = ReplicatedStorage.ActionShared
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde
local Packages = ReplicatedStorage.packages
local PlayerScripts = LocalPlayer.PlayerScripts

local ClientComm = require(PlayerScripts.ClientComm)
local EntityModule = require(ActionShared.Entity)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local EntityRemotes = Remotes.Client:GetNamespace("Entity")
local StateChanged = EntityRemotes:Get("StateChanged")
local InitialEntityStates = ClientComm:GetProperty("InitialEntityStates")
local NextRespawnTime = ClientComm:GetProperty("NextRespawnTime")

-- // Service \\

local EntityController = {
	Name = "EntityController",
	RespawnTimeChanged = Signal.new(), -- Fires when the respawn time changes for our local player/entity.
}

-- // Functions \\

function EntityController:Init()
	EntityController.SerdeLayer = require(Serde.EntityStateSerde)

	local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	Character:WaitForChild("HumanoidRootPart")
	Character:WaitForChild("Humanoid")

	local isTagged = CollectionService:HasTag(Character, "Entity")
	-- If the server already tagged the character, then we can just make the entity state.
	if isTagged then
		EntityModule.MakeEntityState(Character)
	end

	InitialEntityStates:Observe(function(EntityStates: { [Types.Entity]: string }?)
		if EntityStates then
			EntityStates = EntityController.SerdeLayer:DeserializeTable(EntityStates) :: any
			for Entity, State: any in EntityStates do
				EntityModule.ChangeState(Entity, State)
			end
		end
	end)

	NextRespawnTime:Observe(function(RespawnTime: number)
		EntityController.RespawnTimeChanged:Fire(RespawnTime)
	end)

	CollectionService:GetInstanceAddedSignal("Entity"):Connect(function(Entity: Types.Entity)
		EntityController:GetPlayerEntity(LocalPlayer)
			:andThen(function(LocalEntity)
				if Entity.Name == LocalEntity.Name then
					for _, fullEntity in CollectionService:GetTagged("Entity") do
						if fullEntity.Name == LocalEntity.Name then
							fullEntity:WaitForChild("HumanoidRootPart")
							fullEntity:WaitForChild("Humanoid")
							EntityModule.MakeEntityState(fullEntity)
						end
					end
				end
			end)
			:catch(function() end)
	end)

	CollectionService:GetInstanceRemovedSignal("Entity"):Connect(function(Entity: Types.Entity)
		EntityModule.EraseState(Entity)
	end)

	StateChanged:Connect(function(PlayerOrEntity: Player | Model, partialState: Types.EntityState)
		partialState = EntityController.SerdeLayer.Deserialize(partialState :: any)
		local character = PlayerOrEntity :: Model -- assume we're given a character model initially.

		if typeof(PlayerOrEntity) == "Instance" and PlayerOrEntity:IsA("Player") then
			character = (PlayerOrEntity :: any).Character -- get the player's character if we're given a player
		end

		local plrEntity = EntityModule.GetEntity(character)
		if plrEntity then
			local currentState = EntityModule.GetState(plrEntity) or {}
			if currentState then
				local newState = table.clone(currentState) :: Types.EntityState
				for key, value in pairs(partialState) do
					if (value :: any) == "nil" then
						value = nil
					end
					newState[key :: any] = value
				end
				-- If this is not our local player or it's an AI, we can change all the state since we just read from it, not write to it.
				if not PlayerOrEntity:IsA("Player") or (PlayerOrEntity:IsA("Player") and PlayerOrEntity ~= LocalPlayer) then
					EntityModule.ChangeState(plrEntity, newState)
				else
					-- If this is our local player, we set only change the status if it's different. We write to the state and our client is the source of truth in this case because their state
					-- might be ahead of the server's state due to network latency till it gets processed by the server.
					local partialStatuses = partialState.Statuses
					if partialStatuses then
						for statusName: Types.EntityStatus, status in partialState.Statuses do
							EntityModule.AddStatus(plrEntity, statusName, status)
						end
					end
					-- Remove statuses that are no longer active. We type cast to EntityState because on the local player, our state will always be an EntityState.
					local currentStatuses = (currentState :: Types.EntityState).Statuses
					if currentStatuses then
						for statusName: Types.EntityStatus, _status in currentStatuses do
							if not partialState.Statuses[statusName] then
								EntityModule.ClearStatus(plrEntity, statusName)
							end
						end
					end
				end
			end
		end
	end)
end

function EntityController:GetPlayerEntity(Player: Player)
	local Character = Player.Character

	if Character and CollectionService:HasTag(Character, "Entity") then
		return Promise.resolve(Character)
	end

	return Promise.race({
		Promise.fromEvent(CollectionService:GetInstanceAddedSignal("Entity"), function(Entity: Types.Entity)
			return Player == Players:GetPlayerFromCharacter(Entity) -- If this entity is associated with the player, it will return true and the promise will resolve.
		end),
		Promise.fromEvent(Players.PlayerRemoving, function(LeavingPlayer: Player)
			return Player == LeavingPlayer -- If the player leaves, the promise will reject.
		end):andThen(function()
			return Promise.reject()
		end),
	})
end

return EntityController
