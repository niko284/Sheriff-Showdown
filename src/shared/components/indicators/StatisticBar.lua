--!strict

-- Statistic Bar
-- June 6th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local e = React.createElement

type StatisticBarProps = Types.FrameProps & {
	barColor: Color3,
	maxValue: number,
	formatter: any?,
	value: number,
	backgroundColor: Color3,
	round: boolean?,
	unit: string?,
	showPercentage: boolean?,
	statisticName: string,
	statisticIcon: string,
	percentageTextAlignment: Enum.TextXAlignment?,
	children: any,
}
local defaultProps = {
	unit = "",
	showPercentage = true,
}

-- // Statistic Bar \\

local function StatisticBar(props: StatisticBarProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local styles = ReactSpring.useSpring({
		barColor = props.barColor,
		barSize = props.value and props.maxValue and UDim2.fromScale(props.value / props.maxValue, 1)
			or UDim2.fromScale(0, 1),
		barValue = props.value,
		config = { clamp = true },
	}, { props.barColor, props.value, props.maxValue } :: { any })
	return e("Frame", {
		AnchorPoint = props.anchorPoint,
		BackgroundColor3 = props.backgroundColor,
		Position = props.position,
		LayoutOrder = props.layoutOrder,
		Size = props.size,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.5, 0),
		}),
		uIStroke = e("UIStroke", {
			Thickness = 2,
		}),
		text = props.showPercentage and e("TextLabel", {
			Font = Enum.Font.FredokaOne,
			Text = styles.barValue:map(function(value)
				local maxVal = props.maxValue
				if props.round then
					value = math.round(value)
					if maxVal then
						maxVal = math.round(maxVal)
					end
				end
				if props.formatter then
					value = props.formatter:Format(value)
					if maxVal then
						maxVal = props.formatter:Format(maxVal)
					end
				end
				if maxVal then
					return value .. "/" .. maxVal .. " " .. (props.unit :: string)
				else
					return value .. " " .. (props.unit :: string)
				end
			end),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = props.percentageTextAlignment or Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.95, 0.9),
			ZIndex = 2,
		}, {
			stroke = e("UIStroke", {
				Thickness = 2,
				Transparency = 0.4,
				Color = Color3.fromRGB(0, 0, 0),
			}),
		}),
		text2 = props.statisticName and e("TextLabel", {
			Font = Enum.Font.FredokaOne,
			Text = props.statisticName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.78, 0.7),
			ZIndex = 2,
		}),
		icon = e("ImageLabel", {
			Image = props.statisticIcon,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Position = UDim2.fromScale(0.03, 0.5),
			Size = UDim2.fromOffset(22, 22),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}),
		statBarProgress = e("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0, 0.5),
			Size = styles.barSize,
		}, {
			uICorner1 = e("UICorner", {
				CornerRadius = UDim.new(0.5, 0),
			}),
			uIGradient = e("UIGradient", {
				Color = styles.barColor:map(function(color)
					color = Color3.new(math.clamp(color.R, 0, 1), math.clamp(color.G, 0, 1), math.clamp(color.B, 0, 1))
					local barHue, barSaturation, barValue = color:ToHSV()
					return ColorSequence.new({
						ColorSequenceKeypoint.new(0, color),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(barHue, barSaturation, barValue * 0.7)),
					})
				end),
				Rotation = 90,
			}),
		}),
		children = React.createElement(React.Fragment, nil, props.children),
	})
end

return StatisticBar
