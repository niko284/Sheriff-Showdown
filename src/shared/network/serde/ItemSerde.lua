--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MsgPack = require(ReplicatedStorage.utils.MsgPack)
local Types = require(ReplicatedStorage.constants.Types)
local UUIDSerde = require(ReplicatedStorage.network.serde.UUIDSerde)
local t = require(ReplicatedStorage.packages.t)

local itemMap = {
	"Id",
	"UUID",
	"Locked",
	"Favorited",
	-- Optional fields vv
	"Serial",
	"Kills",
}
local itemStruct = t.strictInterface({
	Id = t.numberPositive,
	UUID = t.string,
	Locked = t.boolean,
	Favorited = t.boolean,
	Serial = t.optional(t.numberPositive),
	Level = t.optional(t.numberPositive),
	StatisticMultiplier = t.optional(t.numberPositive),
	Cosmetified = t.optional(t.boolean),
	Kills = t.optional(t.numberMin(0)),
})

-- // Serde Layer \\

return {
	Serialize = function(Item: Types.Item): string
		assert(itemStruct(Item))
		local serializedItem = {}
		-- Serialize the UUID
		for index, key in itemMap do
			serializedItem[index] = (Item :: any)[key]
			if key == "UUID" then
				-- Serialize
				serializedItem[index] = UUIDSerde.Serialize((Item :: any)[key])
			end
		end
		return MsgPack.encode(serializedItem)
	end,
	SerializeTable = function(self: any, items: { Types.Item }): { string }
		local serializedItems = {}
		for _, item in items do
			table.insert(serializedItems, self.Serialize(item))
		end
		return serializedItems
	end,
	Deserialize = function(SerializedItem: string): Types.Item
		local decodedItem = MsgPack.decode(SerializedItem)
		local item = {}
		for index, key in itemMap do
			item[key] = decodedItem[index]
		end
		if item.UUID then
			item.UUID = UUIDSerde.Deserialize(item.UUID)
		end
		return item
	end,
	DeserializeTable = function(self: any, SerializedTable: { string }): { Types.Item }
		local deserialize = {}
		for _i, serializedItem in SerializedTable do
			table.insert(deserialize, self.Deserialize(serializedItem))
		end
		return deserialize
	end,
}
