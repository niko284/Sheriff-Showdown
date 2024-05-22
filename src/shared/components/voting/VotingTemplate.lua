-- Voting Template
-- February 9th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement

-- // Voting Template \\

type VotingTemplateProps = Types.FrameProps & {
	choice: string,
	field: string,
	onActivated: (string, string) -> (),
	backgroundImage: number,
}

local function VotingTemplate(props: VotingTemplateProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		LayoutOrder = props.layoutOrder,
	}, {
		votingButton = e("ImageButton", {
			Image = props.backgroundImage and string.format("rbxassetid://%d", props.backgroundImage),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			[React.Event.Activated] = function()
				props.onActivated(props.field, props.choice)
			end,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0367, 0.0412),
			Size = UDim2.fromOffset(152, 152),
		}, {
			uIGradient = e("UIGradient", {
				Rotation = -90,
			}),

			uIStroke = e("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 2,
				Transparency = 0.7,
			}, {
				uIGradient1 = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
					}),
					Rotation = -90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.498, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),

			uICorner = e("UICorner"),
		}),

		name = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/SourceSansPro.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.choice,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.396, 0.886),
			Size = UDim2.fromOffset(91, 20),
		}),

		uICorner1 = e("UICorner"),

		uIGradient2 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
			}),
			Rotation = -90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),

		uIStroke1 = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2,
			Transparency = 0.7,
		}, {
			uIGradient3 = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
				}),
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.498, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),
	})
end

return React.memo(VotingTemplate)
