--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Hooks = ReplicatedStorage.react.hooks
local Components = ReplicatedStorage.react.components

local React = require(Packages.React)
local Sift = require(Packages.Sift)
local Tooltip = require(Components.other.Tooltip)
local Types = require(Constants.Types)
local usePlayerThumbnail = require(Hooks.usePlayerThumbnail)

local e = React.createElement
local useState = React.useState

type PlayerIconProps = Types.FrameProps & {
	player: Player,
	thumbnailType: Enum.ThumbnailType,
	thumbnailSize: Enum.ThumbnailSize,
	scaleType: Enum.ScaleType,
	showNameTooltip: boolean?,
	children: any,
}
local defaultProps = {
	thumbnailType = Enum.ThumbnailType.HeadShot,
	thumbnailSize = Enum.ThumbnailSize.Size60x60,
}

local function PlayerIcon(props: PlayerIconProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local playerIcon = usePlayerThumbnail(props.player.UserId, props.thumbnailType, props.thumbnailSize)
	local hovered, setHovered = useState(false)

	return e(
		"ImageLabel",
		{
			Size = props.size,
			Position = props.position,
			SizeConstraint = props.sizeConstraint,
			BackgroundTransparency = props.backgroundTransparency,
			BackgroundColor3 = props.backgroundColor3,
			AnchorPoint = props.anchorPoint,
			ScaleType = props.scaleType,
			LayoutOrder = props.layoutOrder,
			ClipsDescendants = props.clipsDescendants,
			Image = playerIcon,
			ZIndex = props.zIndex,
		},
		Sift.Dictionary.merge(props.children, {
			hoverButton = e("ImageButton", {
				ImageTransparency = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 3,
				[React.Event.MouseEnter] = function()
					setHovered(true)
				end,
				[React.Event.MouseLeave] = function()
					setHovered(false)
				end,
			}),
			tip = props.showNameTooltip and hovered and e(Tooltip, {
				name = props.player.Name,
				size = UDim2.fromOffset(77, 26),
				startPosition = UDim2.fromScale(0.5, 0.4),
				endPosition = UDim2.fromScale(0.5, 0.05),
				strokeTransparencyEnd = 0,
				textSize = 18,
			}),
		})
	)
end

return React.memo(PlayerIcon)