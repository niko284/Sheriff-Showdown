-- Input Bar
-- February 13th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement

-- // Input Bar \\

type InputBarProps = Types.FrameProps & {
	onTextChanged: (rbx: TextBox) -> (),
	strokeTransparency: number,
	placeHolderText: string,
}

local function InputBar(props: InputBarProps)
	return e("TextBox", {
		CursorPosition = -1,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		PlaceholderColor3 = Color3.fromRGB(213, 213, 213),
		PlaceholderText = props.placeHolderText or "Search",
		Text = "",
		TextColor3 = Color3.fromRGB(213, 213, 213),
		TextSize = 16,
		TextWrapped = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
		[React.Change.Text] = props.onTextChanged,
	}, {
		uICorner = e("UICorner", {
			CornerRadius = UDim.new(1, 1),
		}),

		uIStroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2,
			Transparency = props.strokeTransparency or 0.7,
		}, {
			uIGradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
				}),
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),

		uIGradient1 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(94, 94, 94)),
			}),
			Rotation = -90,
		}),
	})
end

return React.memo(InputBar)
