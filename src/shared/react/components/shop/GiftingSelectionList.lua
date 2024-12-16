--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Hooks = ReplicatedStorage.react.hooks

local InterfaceController = require(Controllers.InterfaceController)
local PlayerSelectionList = require(Components.frames.SelectionList.PlayerSelectionList)
local React = require(ReplicatedStorage.packages.React)
local ShopContext = require(Contexts.ShopContext)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local e = React.createElement
local useContext = React.useContext
local useCallback = React.useCallback

type GiftingSelectionListProps = {}

local function GiftingSelectionList(_props: GiftingSelectionListProps)
	local shouldRender, styles =
		animateCurrentInterface("GiftingSelection", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local shopState = useContext(ShopContext)

	local giftPlayer = useCallback(function(_rbx: TextButton, player: Player)
		local newShopState = table.clone(shopState)
		newShopState.giftRecipient = player
		InterfaceController.UpdateShopState:Fire(newShopState)
		InterfaceController.InterfaceChanged:Fire("Shop")
	end, { shopState })

	local onClose = useCallback(function()
		InterfaceController.InterfaceChanged:Fire("Shop")
	end, {})

	return shouldRender
		and e(PlayerSelectionList, {
			position = styles.position,
			listTitle = "Gifting",
			selectionText = "Gift",
			subtitle = "Players",
			selectionDescription = "Select a player to gift to!",
			selectionActivated = giftPlayer,
			onClose = onClose,
		})
end

return React.memo(GiftingSelectionList)
