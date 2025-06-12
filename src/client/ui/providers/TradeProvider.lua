--!strict

local React = require("@packages/React")
local TradeContext = require("@ui/contexts/TradeContext")
local TradingController = require("@controllers/TradingController")
local Types = require("@constants/Types")

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

		local tradeStateChangedConnection = TradingController.TradeStateChanged:Connect(function(newTradeState)
			setTradeState(newTradeState)
		end)

		return function()
			activeTradeChangedConnection:Disconnect()
			tradeStateChangedConnection:Disconnect()
		end
	end, {})

	return e(TradeContext.Provider, {
		value = tradeState,
	}, props.children)
end

return TradeProvider
