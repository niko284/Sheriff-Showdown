--!strict

local AutomaticFrame = require("@ui/components/frames/AutomaticFrame")
local React = require("@packages/React")
local ReactSpring = require("@packages/ReactSpring")
local Types = require("@constants/Types")
local UIStroke = require("./UIStroke")

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
			stroke = e(UIStroke, {
				applyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				color = Color3.fromRGB(0, 0, 0),
				thickness = 2,
				transparency = styles.strokeTransparency :: any,
			}),
		}),
	})
end

return React.memo(Tooltip)
