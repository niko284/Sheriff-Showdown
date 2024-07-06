--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contexts = ReplicatedStorage.react.contexts
local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers

local React = require(ReplicatedStorage.packages.React)
local TradeContext = require(Contexts.TradeContext)
local TradingController = require(Controllers.TradingController)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function TradeProvider(props)
	local tradeState, setTradeState = useState({})

	useEffect(function()
		local activeTradeChangedConnection = TradingController.ActiveTradeChanged:Connect(
			function(activeTrade: Types.Trade?)
				setTradeState(function(oldTradeState)
					local newTradeState = table.clone(oldTradeState)
					newTradeState.currentTrade = activeTrade
					return newTradeState
				end)
			end
		)

		return function()
			activeTradeChangedConnection:Disconnect()
		end
	end, {})

	return e(TradeContext.Provider, {
		value = tradeState,
	}, props.children)
end

return TradeProvider
