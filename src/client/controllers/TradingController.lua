--!strict

local HttpService = game:GetService("HttpService")

local ClientComm = require("../ClientComm")
local Net = require("@packages/Net")
local NotificationController = require("@controllers/NotificationController")
local Remotes = require("@network/Remotes")
local Signal = require("@packages/Signal")
local TradeRequestNotification = require("@ui/components/trading/TradeRequestNotification")
local TradeSerde = require("@network/serde/TradeSerde")
local Types = require("@constants/Types")

local TradingNamespace = Remotes.Client:GetNamespace("Trading")
local TradeReceived = TradingNamespace:Get("TradeReceived") :: Net.ClientListenerEvent

local ActiveTradeProperty = ClientComm:GetProperty("ActiveTrade")

local TradingController = {
	Name = "TradingController",
	ActiveTradeChanged = Signal.new() :: Signal.Signal<Types.Trade?>,
	TradeStateChanged = Signal.new(),
}

function TradingController:OnInit()
	ActiveTradeProperty:Observe(function(SerializedTrade: string)
		local Trade: Types.Trade? = TradeSerde.Deserialize(SerializedTrade)
		TradingController.ActiveTradeChanged:Fire(Trade)
	end)
	TradeReceived:Connect(function(SerializedTrade: string)
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
