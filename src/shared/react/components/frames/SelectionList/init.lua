--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CloseButton = require(Components.buttons.CloseButton)
local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)

local e = React.createElement

type SelectionListProps = {
	listTitle: string,
	subtitle: string,
	children: any,
	selectionDescription: string,
	position: React.Binding<UDim2> | UDim2,
	onClose: () -> (),
}

local function SelectionList(props: SelectionListProps)
	return e("ImageLabel", {
		Image = "rbxassetid://18180704447",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = props.position,
		Size = UDim2.fromOffset(848, 608),
	}, {
		separator = e(Separator, {
			position = UDim2.fromOffset(26, 188),
			size = UDim2.fromOffset(797, 3),
		}),

		subtitle = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.subtitle,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 123),
			Size = UDim2.fromOffset(88, 21),
		}),

		selectAPlayer = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = props.selectionDescription,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.663,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 153),
			Size = UDim2.fromOffset(176, 11),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18180720082",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18180720217",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			title = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.listTitle,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(64, 35),
				Size = UDim2.fromOffset(88, 21),
			}),

			close = e(CloseButton, {
				position = UDim2.fromScale(0.946, 0.517),
				size = UDim2.fromOffset(42, 42),
				onActivated = props.onClose,
			}),

			icon3 = e("ImageLabel", {
				Image = "rbxassetid://18180704894",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(32, 30),
				Size = UDim2.fromOffset(8, 8),
			}),

			icon2 = e("ImageLabel", {
				Image = "rbxassetid://18180705022",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(30, 36),
				Size = UDim2.fromOffset(12, 17),
			}),

			icon1 = e("ImageLabel", {
				Image = "rbxassetid://18180705178",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 42),
				Size = UDim2.fromOffset(27, 15),
			}),
		}),

		selectionScrolling = e(AutomaticScrollingFrame, {
			scrollBarThickness = 9,
			anchorPoint = Vector2.new(0, 0),
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0106, 0.334),
			size = UDim2.fromOffset(831, 384),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 15),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 7),
				PaddingTop = UDim.new(0, 5),
			}),
			selections = e(React.Fragment, nil, props.children),
		}),
	})
end

return React.memo(SelectionList)
