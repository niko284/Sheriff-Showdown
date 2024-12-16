--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.constants.Types)

local TradeUtils = {}

function TradeUtils.IsItemInTrade(Trade: Types.Trade, Item: Types.Item)
	for _, tradeItem in Trade.ReceiverOffer do
		if tradeItem.UUID == Item.UUID then
			return true
		end
	end
	for _, tradeItem in Trade.SenderOffer do
		if tradeItem.UUID == Item.UUID then
			return true
		end
	end
	return false
end

return TradeUtils
