--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type NotificationElementProps = Types.FrameProps & {
	duration: number,
	id: string,
	removeNotification: (string) -> (),
	creationTime: number,
	padding: UDim,
	onFade: () -> (),
	isActive: boolean,
	options: { any },
	title: string,
	clickToDismiss: boolean,
	onDismiss: () -> (),
	description: string,
	size: UDim2,
}

local function NotificationElement(props: NotificationElementProps)
	return e("ImageLabel", {
		Image = "rbxassetid://18356322141",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.158, 0.21),
	}, {
		topbar = e("ImageLabel", {
			Image = "rbxassetid://18356322260",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.286),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18356322392",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),

			title = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.notificationTitle,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 19,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.0726, 0.385),
				Size = UDim2.fromScale(0.386, 0.246),
			}),
		}),

		notificationDescription = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.SemiBold,
				Enum.FontStyle.Normal
			),
			Text = props.notificationDescription,
			TextColor3 = Color3.fromRGB(93, 207, 227),
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.267, 0.396),
			Size = UDim2.fromScale(0.545, 0.119),
		}),

		iconBackground = e("ImageLabel", {
			Image = "rbxassetid://18356322538",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0627, 0.361),
			Size = UDim2.fromScale(0.162, 0.216),
		}, {
			notifIcon = e("ImageLabel", {
				Image = props.notificationIcon,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18356333672",
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.0627, 0.665),
			Size = UDim2.fromScale(0.878, 0.0176),
		}),
	})
end

return React.memo(NotificationElement)
