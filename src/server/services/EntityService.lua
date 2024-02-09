--!strict

-- Entity Service
-- October 1st, 2022
-- Ron

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local ActionShared = ReplicatedStorage.ActionShared
local Services = ServerScriptService.services
local Serde = ReplicatedStorage.serde
local Constants = ReplicatedStorage.constants

local DataService = require(Services.DataService)
local EntityModule = require(ActionShared.Entity)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.Remotes)
local ServerComm = require(ServerScriptService.ServerComm)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local EntityRemotes = Remotes.Server:GetNamespace("Entity")
local StateChanged = EntityRemotes:Get("StateChanged")

local CHARACTERS_FOLDER = Instance.new("Folder")
CHARACTERS_FOLDER.Name = "Characters"
CHARACTERS_FOLDER.Parent = workspace

-- // Service \\

local EntityService = {
	Name = "EntityService",
	PlayerEntityReady = Signal.new(),
	NextRespawnTime = ServerComm:CreateProperty("NextRespawnTime", nil),
	InitialEntityStates = ServerComm:CreateProperty("InitialEntityStates", nil),
}
local EntityStateMap = {
	"DefenseLevel",
	"AttackLevel",
	"Statuses",
	"LastActionState",
	"ActionHistory",
}

-- // Functions \\

function EntityService:Init()
	EntityService.SerdeLayer = require(Serde.EntityStateSerde)
	EntityService.ResourceService = require(Services.ResourceService)
	EntityService.InventoryService = require(Services.InventoryService)
	local function PlayerAdded(Player: Player)
		local function CharacterAdded(Character: Model)
			if not Player:HasAppearanceLoaded() then
				Player.CharacterAppearanceLoaded:Wait()
			end
			Character.Parent = CHARACTERS_FOLDER
			CollectionService:AddTag(Character, "Entity")
			CollectionService:AddTag(Character, "PlayerEntity")
		end

		if Player.Character then
			CharacterAdded(Player.Character)
		end

		Player.CharacterAdded:Connect(CharacterAdded)
	end

	CollectionService:GetInstanceRemovedSignal("Entity"):Connect(function(Entity: Types.Entity)
		EntityModule.EraseState(Entity)
	end)

	DataService.PlayerDataLoaded:Connect(PlayerAdded)

	EntityModule.StateChanged:Connect(function(Entity: Types.Entity, NewState, OldState)
		local changedState = {} :: any
		-- Send state that differs from our entity state map.

		if not OldState then
			return
		end

		for _, key: any in EntityStateMap do
			if key == "ActionHistory" then
				-- if we have an action history change, only send the states that actually changed.
				local changedHistory = {} :: any
				for handlerName, actionState in pairs(NewState.ActionHistory) do
					if OldState.ActionHistory[handlerName] ~= actionState then
						changedHistory[handlerName] = actionState
					end
				end
				changedState.ActionHistory = changedHistory
			end

			if OldState[key] ~= NewState[key] then
				if NewState[key] == nil then
					changedState[key :: any] = "nil" -- We need to indicate that the value is nil.
				else
					changedState[key :: any] = (NewState :: any)[key]
				end
			end
		end

		-- If there is nothing to send, then don't send anything.
		if next(changedState) == nil then
			return
		end

		local Player = Players:GetPlayerFromCharacter(Entity)

		if Player then
			if not changedState.Statuses then
				StateChanged:SendToAllPlayersExcept(Player, Player, EntityService.SerdeLayer.Serialize(changedState))
			else
				StateChanged:SendToAllPlayers(Player, EntityService.SerdeLayer.Serialize(changedState))
			end
		else
			-- NPC or something changed state.
			StateChanged:SendToAllPlayers(Entity, EntityService.SerdeLayer.Serialize(changedState))
		end
	end)
end

function EntityService:GetPlayerEntity(Player: Player)
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

return EntityService
