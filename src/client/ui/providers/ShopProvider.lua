--!strict

local Players = game:GetService("Players")

local InterfaceController = require("@controllers/InterfaceController")
local React = require("@packages/React")
local ShopContext = require("@ui/contexts/ShopContext")

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function ShopProvider(props)
	local shopState, setShopState = useState({} :: any)

	useEffect(function()
		local shopStateUpdated = InterfaceController.UpdateShopState:Connect(function(newState)
			setShopState(newState)
		end)

		local recipientLeft = Players.PlayerRemoving:Connect(function(Player: Player)
			if shopState.giftRecipient == Player then
				setShopState(function(oldState)
					local newState = table.clone(oldState)
					newState.giftRecipient = nil
					return newState
				end)
			end
		end)

		return function()
			recipientLeft:Disconnect()
			shopStateUpdated:Disconnect()
		end
	end, { shopState })

	return e(ShopContext.Provider, {
		value = shopState,
	}, props.children)
end

return ShopProvider
