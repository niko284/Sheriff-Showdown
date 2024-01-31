--!strict

-- Entity State Serde
-- August 18th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionShared = ReplicatedStorage.ActionShared
local Serde = script.Parent

local ActionStateSerde = require(Serde.ActionStateSerde)
local Handlers = require(ActionShared.Handlers)
local MsgPack = require(ReplicatedStorage.vendor.MsgPack)
local StatusModule = require(ActionShared.StatusModule)
local Types = require(ReplicatedStorage.constants.Types)
local t = require(ReplicatedStorage.packages.t)

local simpleStateMap = {
	"LastActionState",
	"AttackLevel",
	"DefenseLevel",
	"Statuses",
	"ActionHistory",
}
local statusMap = {}
for _, statusHandler in StatusModule.GetStatusHandlers() do
	table.insert(statusMap, statusHandler.Data.Name)
end

-- insert all action-handler names to our simpleStateMap.
local handlerNames = {}
for _, handler in Handlers do
	table.insert(handlerNames, handler.Data.Name)
end

local statusInterface = {}
for _, statusName in statusMap do
	statusInterface[statusName] = t.optional(t.strictInterface({
		Status = t.string,
		EndMillis = t.optional(t.numberPositive),
	}))
end

local statusInternalStruct = {
	"Status",
	"EndMillis",
}

local baseStruct = {
	LastActionState = t.union(t.optional(ActionStateSerde.Struct), t.optional(t.literal("nil"))),
	AttackLevel = t.optional(t.integer),
	DefenseLevel = t.optional(t.integer),
	Statuses = t.optional(t.interface(statusInterface)),
}
-- add all action-handler names to our baseStruct.
local ActionHistoryStruct = {}
for _, handlerName in handlerNames do
	ActionHistoryStruct[handlerName] = t.optional(ActionStateSerde.Struct)
end
baseStruct.ActionHistory = t.optional(t.interface(ActionHistoryStruct))

local simpleEntityStateStruct = t.strictInterface(baseStruct)

-- // Serde Layer \\

return {
	Serialize = function(State: Types.EntityState): string
		assert(simpleEntityStateStruct(State))
		local serializedState = {} :: { any }

		for index, key in simpleStateMap do
			serializedState[index] = State[key :: any] -- luau limitation (we need keyof here)

			if State[key :: any] == "nil" then
				continue -- skip "nil" strings
			end
			if (key == "LastActionState") and State[key :: any] then -- this is an action state struct
				serializedState[index] = ActionStateSerde.Serialize(State[key :: any] :: Types.ActionStateInfo) -- luau limitation (we need keyof here)
			elseif key == "Statuses" and State[key :: any] then
				local entityStatuses = State.Statuses
				local serializedStatuses = {}
				for statusIndex, statusKey: any in statusMap do
					if entityStatuses[statusKey] then
						local statusStruct = {}
						for statusStructIndex, statusStructKey in statusInternalStruct do
							statusStruct[statusStructIndex] = entityStatuses[statusKey][statusStructKey]
						end
						serializedStatuses[statusIndex] = statusStruct
					end
				end
				serializedState[index] = serializedStatuses
				--[[elseif key == "ActionHistory" and State[key :: any] then
				local serializedActionHistory = {}
				for actionIndex, actionKey in handlerNames do
					if State.ActionHistory[actionKey] then
						serializedActionHistory[actionIndex] =
							ActionStateSerde.Serialize(State.ActionHistory[actionKey] :: Types.ActionStateInfo) -- luau limitation (we need keyof here)
					end
				end--]]
			end
		end

		return MsgPack.encode(serializedState)
	end,
	SerializeTable = function(self: any, items: { [any]: Types.EntityState }): { string }
		local SerializedStates = {}

		for key, item in items do
			SerializedStates[key] = self.Serialize(item)
		end

		return SerializedStates
	end,
	Deserialize = function(SerializedState: string): Types.EntityState
		local decodedItem = MsgPack.decode(SerializedState)
		local State = {}

		for index, key in simpleStateMap do
			State[key :: any] = decodedItem[index]
			if (key == "PreviousActionState") and decodedItem[index] then -- this is an action state struct
				State[key :: any] = ActionStateSerde.Deserialize(decodedItem[index] :: string) -- luau limitation (we need keyof here)
			elseif key == "Statuses" and decodedItem[index] then
				local entityStatuses = {}
				for statusIndex, statusKey in statusMap do
					if decodedItem[index][statusIndex] then
						local structEncoded = decodedItem[index][statusIndex]
						local structDecoded = {}
						for statusStructIndex, statusStructKey in statusInternalStruct do
							structDecoded[statusStructKey] = structEncoded[statusStructIndex]
						end
						entityStatuses[statusKey] = structDecoded
					end
				end
				State[key :: any] = entityStatuses
			elseif key == "ActionHistory" and decodedItem[index] then
				local actionHistory = {}
				for actionIndex, actionKey in handlerNames do
					if decodedItem[index][actionIndex] then
						actionHistory[actionKey] = ActionStateSerde.Deserialize(decodedItem[index][actionIndex] :: string) -- luau limitation (we need keyof here)
					end
				end
				State[key :: any] = actionHistory
			end
		end

		return State
	end,
	DeserializeTable = function(self: any, SerializedTable: { [any]: string }): { Types.EntityState }
		local deserialize = {}

		for key, SerializedState in SerializedTable do
			deserialize[key] = self.Deserialize(SerializedState)
		end

		return deserialize
	end,
}
