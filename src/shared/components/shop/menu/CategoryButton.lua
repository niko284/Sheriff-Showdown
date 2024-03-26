-- Category Button
-- February 24th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement

-- // Category Button \\

type CategoryButtonProps = Types.FrameProps & {
	categoryImage: number,
	categoryName: string,
	onActivated: (string) -> (),
}
local function CategoryButton(props: CategoryButtonProps)
	return e("ImageButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = function()
			props.onActivated(props.categoryName)
		end,
	}, {
		crateframe = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			image = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", props.categoryImage),
				ScaleType = Enum.ScaleType.Fit,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.383, -1.66),
				Size = UDim2.fromOffset(345, 345),
			}),
			imageButton = e("ImageButton", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				ZIndex = 2,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				[React.Event.Activated] = function()
					props.onActivated(props.categoryName)
				end,
			}),

			uIGradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(116, 116, 116)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(116, 116, 116)),
				}),
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.814),
					NumberSequenceKeypoint.new(0.702, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
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

			name = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.categoryName,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextTransparency = 0.3,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0139, 0.272),
				Size = UDim2.fromOffset(147, 59),
			}),

			uICorner = e("UICorner"),
		}),
	})
end

return React.memo(CategoryButton)
