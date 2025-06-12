--!strict

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local PlayerSelectionTemplate = require("@ui/components/frames/SelectionList/PlayerSelectionTemplate")
local React = require("@packages/React")
local SelectionList = require("@ui/components/frames/SelectionList")
local usePlayers = require("@ui/hooks/usePlayers")

local e = React.createElement

type PlayerSelectionListProps = {
	position: any,
	listTitle: string,
	subtitle: string,
	selectionText: string,
	selectionDescription: string,
	selectionActivated: (TextButton, Player) -> (),
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
