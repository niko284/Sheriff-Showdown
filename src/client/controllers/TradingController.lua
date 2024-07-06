--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Serde = ReplicatedStorage.network.serde

local ClientComm = require(PlayerScripts.ClientComm)
local Signal = require(ReplicatedStorage.packages.Signal)
local TradeSerde = require(Serde.TradeSerde)
local Types = require(ReplicatedStorage.constants.Types)

local ActiveTradeProperty = ClientComm:GetProperty("ActiveTrade")

local TradingController = {
	Name = "TradingController",
	ActiveTradeChanged = Signal.new() :: Signal.Signal<Types.Trade?>,
}

function TradingController:OnInit()
	ActiveTradeProperty:Observe(function(SerializedTrade: string)
		local Trade: Types.Trade? = TradeSerde.Deserialize(SerializedTrade)
		TradingController.ActiveTradeChanged:Fire(Trade)
	end)
end

return TradingController
