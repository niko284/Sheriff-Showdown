--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type SlideProps = Types.FrameProps & {
	icon: string,
	slideName: string,
	price: number,
	description: string,
	slideRef: (ref: Frame) -> (),
}

local function Slide(props: SlideProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		ref = function(rbx)
			props.slideRef(rbx)
		end,
	}, {
		slideImage = e("ImageLabel", {
			Image = props.icon,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(54, 50),
			Size = UDim2.fromOffset(150, 150),
		}),

		currentName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.slideName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 243),
			Size = UDim2.fromOffset(92, 12),
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.description or "Description",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 266),
			Size = UDim2.fromOffset(155, 14),
		}),

		price = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.price or "555",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(203, 26),
			Size = UDim2.fromOffset(28, 12),
		}),

		robuxIcon = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Text = utf8.char(0xE002),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(181, 21),
			Size = UDim2.fromOffset(22, 25),
		}),
	})
end

return React.memo(Slide)
