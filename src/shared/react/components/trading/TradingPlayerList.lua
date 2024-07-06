--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Components = ReplicatedStorage.react.components
local Hooks = ReplicatedStorage.react.hooks
local Controllers = LocalPlayer.PlayerScripts.controllers

local InterfaceController = require(Controllers.InterfaceController)
local Net = require(ReplicatedStorage.packages.Net)
local PlayerSelectionList = require(Components.frames.SelectionList.PlayerSelectionList)
local React = require(ReplicatedStorage.packages.React)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Types = require(ReplicatedStorage.constants.Types)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)

local TradingNamespace = Remotes.Client:GetNamespace("Trading")
local SendTradeToPlayer = TradingNamespace:Get("SendTradeToPlayer") :: Net.ClientAsyncCaller

local e = React.createElement
local useCallback = React.useCallback

type TradingPlayerListProps = {}

local function TradingPlayerList(_props: TradingPlayerListProps)
	local _shouldRender, styles = animateCurrentInterface("Trading", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local sendTradeToPlayer = useCallback(function(_rbx: TextButton, player: Player)
		SendTradeToPlayer:CallServerAsync(player)
			:andThen(function(response: Types.NetworkResponse)
				-- @TODO: Implement trade UI
				if response.Success == true then
				else
				end
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, {})

	local onClose = useCallback(function()
		InterfaceController.InterfaceChanged:Fire(nil)
	end, {})

	return e(PlayerSelectionList, {
		position = styles.position,
		listTitle = "Trading",
		selectionText = "Trade",
		subtitle = "Trading",
		selectionDescription = "Select a player to trade with!",
		selectionActivated = sendTradeToPlayer,
		onClose = onClose,
	})
end

return TradingPlayerList
