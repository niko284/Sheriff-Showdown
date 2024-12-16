--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Hooks = ReplicatedStorage.react.hooks

local React = require(ReplicatedStorage.packages.React)
local SelectionTemplate = require(Components.frames.SelectionList.SelectionTemplate)
local usePlayerThumbnail = require(Hooks.usePlayerThumbnail)

local e = React.createElement

type PlayerSelectionTemplateProps = {
	player: Player,
	selectionActivated: (TextButton, Player) -> (),
	selectionText: string,
}

local function PlayerSelectionTemplate(props: PlayerSelectionTemplateProps)
	local playerThumbnail =
		usePlayerThumbnail(props.player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)

	return e(SelectionTemplate, {
		icon = playerThumbnail,
		primaryText = props.player.DisplayName,
		selectionText = props.selectionText,
		secondaryText = "@" .. props.player.Name,
		selectionActivated = function(rbx: TextButton)
			props.selectionActivated(rbx, props.player)
		end,
	})
end

return React.memo(PlayerSelectionTemplate)
