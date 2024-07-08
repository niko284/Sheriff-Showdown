--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Serde = ReplicatedStorage.network.serde
local Components = ReplicatedStorage.react.components

local ClientComm = require(PlayerScripts.ClientComm)
local Net = require(ReplicatedStorage.packages.Net)
local NotificationController = require(PlayerScripts.controllers.NotificationController)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(ReplicatedStorage.packages.Signal)
local TradeRequestNotification = require(Components.trading.TradeRequestNotification)
local TradeSerde = require(Serde.TradeSerde)
local Types = require(ReplicatedStorage.constants.Types)

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
