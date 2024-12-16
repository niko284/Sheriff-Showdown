--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Contexts = ReplicatedStorage.react.contexts
local Controllers = LocalPlayer.PlayerScripts.controllers

local InterfaceController = require(Controllers.InterfaceController)
local React = require(ReplicatedStorage.packages.React)
local ShopContext = require(Contexts.ShopContext)

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
