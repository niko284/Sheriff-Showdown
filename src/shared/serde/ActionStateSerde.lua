--!strict
-- Action State Serde
-- August 18th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local Vendor = ReplicatedStorage.vendor

local MsgPack = require(Vendor.MsgPack)
local Types = require(Constants.Types)
local t = require(Packages.t)

local actionStateStruct = t.strictInterface({
	TimestampMillis = t.optional(t.number),
	GlobalCooldownFinishTimeMillis = t.optional(t.number),
	CooldownFinishTimeMillis = t.optional(t.number),
	CancelPreviousAction = t.optional(t.boolean),
	Sustaining = t.boolean,
	Priority = t.string,
	Interruptable = t.boolean,
	ActionHandlerName = t.string,
	ActionSpecific = t.optional(
		t.strictInterface({ Combo = t.optional(t.numberPositive), MaxCombo = t.optional(t.numberPositive) })
	),
	Finished = t.boolean,
	UUID = t.optional(t.string),
})

-- anything commented out is not sent over the network because other entities don't need to know about it.
local actionStateMap = {
	--"TimestampMillis",
	--"GlobalCooldownFinishTimeMillis",
	--"CooldownFinishTimeMillis",
	--"CancelPreviousAction",
	-- "Sustaining",
	-- "Priority",
	--"ActionPayload",
	"ActionHandlerName",
	"Finished",
	"ActionSpecific",
	"Interruptable",
	--"UUID",
}

local actionSpecificMap = {
	"Combo",
	"MaxCombo",
}

return {
	Serialize = function(State: Types.ActionStateInfo): string
		assert(actionStateStruct(State))

		local serializedState = {}
		for index, key in actionStateMap do
			serializedState[index] = State[key]
			if key == "ActionSpecific" and State.ActionSpecific then
				local actionSpecific = {}
				for actionSpecificIndex, actionSpecificKey in actionSpecificMap do
					if State.ActionSpecific[actionSpecificKey] then
						actionSpecific[actionSpecificIndex] = State.ActionSpecific[actionSpecificKey]
					end
				end
				serializedState[index] = actionSpecific
			end
		end

		return MsgPack.encode(serializedState)
	end,
	Deserialize = function(SerializedState: string): Types.ActionStateInfo
		local deserializedState = MsgPack.decode(SerializedState)
		local State = {}

		for index, key in actionStateMap do
			State[key] = deserializedState[index]
			if key == "ActionSpecific" and State.ActionSpecific then
				local actionSpecific = {}
				for actionSpecificIndex, actionSpecificKey in actionSpecificMap do
					actionSpecific[actionSpecificKey] = State.ActionSpecific[actionSpecificIndex]
				end
			end
		end

		return State
	end,
	SerializeTable = function(self: any, States: { Types.ActionStateInfo }): { string }
		local SerializedStates = {}
		for _, State in States do
			table.insert(SerializedStates, self.Serialize(State))
		end
		return SerializedStates
	end,
	DeserializeTable = function(self: any, SerializedStates: { string }): { Types.ActionStateInfo }
		local DeserializedStates = {}
		for _, SerializedState in SerializedStates do
			table.insert(DeserializedStates, self.Deserialize(SerializedState))
		end
		return DeserializedStates
	end,
	Struct = actionStateStruct,
}
