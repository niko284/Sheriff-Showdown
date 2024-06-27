--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Hooks = ReplicatedStorage.react.hooks
local Components = ReplicatedStorage.react.components

local PlayerSelectionTemplate = require(Components.frames.SelectionList.PlayerSelectionTemplate)
local React = require(ReplicatedStorage.packages.React)
local SelectionList = require(Components.frames.SelectionList)
local usePlayers = require(Hooks.usePlayers)

local e = React.createElement

type PlayerSelectionListProps = {
	position: React.Binding<UDim2> | UDim2,
	listTitle: string,
	subtitle: string,
	selectionText: string,
	selectionDescription: string,
	selectionActivated: (TextButton) -> (),
	onClose: () -> (),
}

local function PlayerSelectionList(props: PlayerSelectionListProps)
	local players = usePlayers()

	local playerSelectionElements = {}
	for _, player in players do
		if LocalPlayer.UserId ~= player.UserId then
			playerSelectionElements[player.UserId] = e(PlayerSelectionTemplate, {
				player = player,
				selectionActivated = props.selectionActivated,
				selectionText = props.selectionText,
			})
		end
	end

	return e(SelectionList, {
		position = props.position,
		listTitle = props.listTitle,
		subtitle = props.subtitle,
		onClose = props.onClose,
		selectionDescription = props.selectionDescription,
	}, playerSelectionElements)
end

return React.memo(PlayerSelectionList)
