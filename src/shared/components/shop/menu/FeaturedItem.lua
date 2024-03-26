-- Featured Item
-- February 24th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement

-- // Featured Item \\

type FeaturedItemProps = Types.FrameProps & {
	itemInfo: Types.ItemInfo,
	onActivated: (Types.ItemInfo) -> (),
}
local function FeaturedItem(props: FeaturedItemProps)
	return e("ImageButton", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		[React.Event.Activated] = function()
			props.onActivated(props.itemInfo)
		end,
	}, {
		inv = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(184, 170),
		}, {
			image = e("ImageButton", {
				Image = string.format("rbxassetid://%d", props.itemInfo.Image),
				ScaleType = Enum.ScaleType.Fit,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.195, 0.201),
				[React.Event.Activated] = function()
					props.onActivated(props.itemInfo)
				end,
				Size = UDim2.fromOffset(133, 133),
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
				Text = props.itemInfo.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextTransparency = 0.3,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0636, 0.0417),
				Size = UDim2.fromOffset(120, 27),
			}),

			uICorner = e("UICorner"),
		}),
	})
end

return React.memo(FeaturedItem)
