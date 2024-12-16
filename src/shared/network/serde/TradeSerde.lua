--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serde = ReplicatedStorage.network.serde
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local ItemSerde = require(Serde.ItemSerde)
local MsgPack = require(ReplicatedStorage.utils.MsgPack)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)
local t = require(Packages.t)

local tradeKeys = {
	"UUID",
	"ReceiverOffer",
	"SenderOffer",
	"Receiver",
	"Sender",
	"MaximumItems",
	"Accepted",
	"Confirmed",
	"Status",
	"CooldownEnd",
}
local tradeStruct = t.strictInterface({
	UUID = t.string,
	ReceiverOffer = t.array(t.table),
	SenderOffer = t.array(t.table),
	Receiver = t.instanceIsA("Player"),
	Sender = t.instanceIsA("Player"),
	MaximumItems = t.numberPositive,
	Accepted = t.array(t.instanceIsA("Player")),
	Confirmed = t.array(t.instanceIsA("Player")),
	Status = t.string,
	CooldownEnd = t.optional(t.numberPositive),
})

return {
	Serialize = function(Trade: Types.Trade): string?
		assert(tradeStruct(Trade))
		if not Trade then
			return nil
		end
		local serializedTrade = {} :: { any }
		for key, value: any in pairs(Trade) do
			local index = table.find(tradeKeys, key)
			if not index then
				continue
			else
				if key == "UUID" then
					serializedTrade[index] = UUIDSerde.Serialize(value)
				elseif key == "ReceiverOffer" or key == "SenderOffer" then
					serializedTrade[index] = {}
					for i, item: Types.Item in Trade[key] do
						serializedTrade[index][i] = ItemSerde.Serialize(item)
					end
				elseif key == "Receiver" or key == "Sender" then
					serializedTrade[index] = value.UserId
				elseif key == "Accepted" or key == "Confirmed" then
					serializedTrade[index] = {}
					for i, player in value do
						serializedTrade[index][i] = player.UserId
					end
				else
					serializedTrade[index] = value
				end
			end
		end
		return MsgPack.encode(serializedTrade)
	end,
	Deserialize = function(Trade: any): Types.Trade?
		if not Trade or typeof(Trade) ~= "string" then
			return nil
		end
		local decodedTrade = MsgPack.decode(Trade)
		local trade = {} :: Types.Trade
		for index, key in tradeKeys do
			local value = decodedTrade[index]
			if not value then
				continue
			end
			if key == "UUID" then
				trade[key] = UUIDSerde.Deserialize(value)
			elseif key == "ReceiverOffer" or key == "SenderOffer" then
				trade[key] = {}
				for i, item in value do
					trade[key][i] = ItemSerde.Deserialize(item)
				end
			elseif key == "Receiver" or key == "Sender" then
				trade[key] = Players:GetPlayerByUserId(value)
			elseif key == "Accepted" or key == "Confirmed" then
				trade[key] = {}
				for i, userId in value do
					trade[key][i] = Players:GetPlayerByUserId(userId)
				end
			else
				trade[key] = value
			end
		end
		return trade
	end,
	SerializeTable = function(self: any, Trades: { Types.Trade })
		local SerializedTrades = {}
		for Key, Trade in Trades do
			SerializedTrades[Key] = self.Serialize(Trade)
		end
		return SerializedTrades
	end,
	DeserializeTable = function(self: any, SerializedTrades: { { any } })
		local Trades = {}
		for Key, SerializedTrade in SerializedTrades do
			Trades[Key] = self.Deserialize(SerializedTrade)
		end
		return Trades
	end,
}
