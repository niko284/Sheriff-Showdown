--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.react.components
local Constants = ReplicatedStorage.constants

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Types = require(Constants.Types)

local e = React.createElement

type TooltipProps = Types.FrameProps & {
	name: string,
	startPosition: UDim2,
	endPosition: UDim2,
	size: UDim2,
	strokeTransparencyEnd: number,
	textSize: number,
}

-- // Tooltip \\

local function Tooltip(props: TooltipProps)
	local styles = ReactSpring.useSpring({
		from = {
			hoverPosition = props.startPosition,
			hoverTransparency = 1,
			strokeTransparency = 1,
		},
		to = {
			hoverPosition = props.endPosition,
			hoverTransparency = 0,
			strokeTransparency = props.strokeTransparencyEnd or 0.8,
		},
		reset = true,
		config = {
			duration = 0.15, -- seconds
			easing = ReactSpring.easings.easeInOutQuad,
		},
	}, { props.startPosition, props.endPosition, props.strokeTransparencyEnd } :: { any })

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
		Position = styles.hoverPosition,
		Size = props.size,
	}, {
		uiCorner = e("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
		}),
		text = e(AutomaticFrame, {
			instanceProps = {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = props.textSize,
				Rotation = props.rotation or 20,
				TextTransparency = styles.hoverTransparency,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.765, 0.42),
				Size = UDim2.fromScale(0.9, 0.65),
			},
			className = "TextLabel",
		}, {
			stroke = e("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 2,
				Transparency = styles.strokeTransparency,
			}),
		}),
	})
end

return React.memo(Tooltip)
