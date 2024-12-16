--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Button = require(ReplicatedStorage.react.components.buttons.Button)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type DaySevenTemplateProps = Types.FrameProps & {
	claimed: boolean,
	canClaim: boolean,
	reward: string,
	icon: number,
	claim: (number) -> (),
	day: number,
}

local function DaySevenTemplate(props: DaySevenTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.689),
		Size = props.size,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 14),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
		}),

		uIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 72, 72)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(43, 43, 43)),
			}),
			Rotation = -90,
		}),

		selectionName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.reward,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0145, 0.1),
			Size = UDim2.fromScale(0.437, 0.233),
		}),

		claim = props.canClaim and not props.claimed and e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Claim",
			textColor3 = Color3.fromRGB(0, 54, 25),
			anchorPoint = Vector2.new(0.5, 0.5),
			textSize = 16,
			size = UDim2.fromScale(0.434, 0.284),
			position = UDim2.fromScale(0.232, 0.768),
			strokeThickness = 1.5,
			layoutOrder = 1,
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(128, 118, 118),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
			}),
			gradientRotation = -90,
			onActivated = function()
				props.claim(props.day)
			end,
		}),

		lockedFrame = props.canClaim == false and not props.claimed and e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(33, 33, 33),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			uICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 14),
			}),

			imageLabel = e("ImageLabel", {
				Image = "http://www.roblox.com/asset/?id=70389927590549",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.457, 0.269),
				Size = UDim2.fromOffset(61, 60),
			}),
		}),

		imageLabel = e("ImageLabel", {
			Image = string.format("rbxassetid://%d", props.icon),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.58, 0.0422),
			Size = UDim2.fromScale(0.369, 0.913),
			ZIndex = 0,
		}),
	})
end

return DaySevenTemplate
