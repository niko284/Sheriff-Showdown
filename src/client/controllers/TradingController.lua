--!strict

local HttpService = game:GetService("HttpService")

local BlinkClient = require("@client/modules/BlinkClient")
local NotificationController = require("@controllers/NotificationController")
local Signal = require("@packages/Signal")
local TradeRequestNotification = require("@ui/components/trading/TradeRequestNotification")
local TradeSerde = require("@network/serde/TradeSerde")
local Types = require("@constants/Types")

local TradingController = {
	Name = "TradingController",
	ActiveTradeChanged = Signal.new() :: Signal.Signal<Types.Trade?>,
	TradeStateChanged = Signal.new(),
}

function TradingController:OnInit()
	BlinkClient.TradingActiveTradeSync.On(function(SerializedTrade: string)
		local Trade: Types.Trade? = TradeSerde.Deserialize(SerializedTrade)
		TradingController.ActiveTradeChanged:Fire(Trade)
	end)
	BlinkClient.TradingTradeReceived.On(function(SerializedTrade: string)
		local Trade = TradeSerde.Deserialize(SerializedTrade) :: Types.Trade

		local tradeWith = string.format("%s wants to trade with you", Trade.Sender.Name)
		local tradeRequestNotification: Types.Notification = {
			UUID = HttpService:GenerateGUID(false),
			Title = "Trade Request",
			Description = tradeWith,
			Component = TradeRequestNotification,
			Props = {
				playerId = Trade.Sender.UserId,
				tradeUUID = Trade.UUID,
			},
			Duration = 5,
		}
		NotificationController:AddNotification(tradeRequestNotification)
	end)
end

return TradingController
