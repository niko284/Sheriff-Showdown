--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

local e = React.createElement

type CurrencyPageProps = {
	pageRef: (ref: Frame) -> (),
}

local function CurrencyPage(props: CurrencyPageProps)
	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1.03),
		ref = function(rbx: Frame)
			props.pageRef(rbx)
		end,
	}, {
		currency = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Currency",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 18),
			Size = UDim2.fromOffset(77, 15),
		}),

		packOne = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.113, 0.309),
			Size = UDim2.fromOffset(163, 163),
		}, {
			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			coins = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "$100,000",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 104),
				Size = UDim2.fromOffset(74, 17),
			}),

			robuxPrice = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "555",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 131),
				Size = UDim2.fromOffset(28, 12),
			}),
		}),

		packTwo = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.325, 0.309),
			Size = UDim2.fromOffset(163, 163),
		}, {
			coins1 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "$100,000",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 104),
				Size = UDim2.fromOffset(74, 17),
			}),

			robuxPrice1 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "555",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(15, 129),
				Size = UDim2.fromOffset(28, 12),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),
		}),

		packThree = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.56, 0.309),
			Size = UDim2.fromOffset(201, 163),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
			}),

			coins2 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "$100,000",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 104),
				Size = UDim2.fromOffset(74, 17),
			}),

			robuxPrice2 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "555",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 130),
				Size = UDim2.fromOffset(28, 12),
			}),
		}),

		packFour = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.219, 0.727),
			Size = UDim2.fromOffset(339, 162),
		}, {
			coins3 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "$100,000",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 100),
				Size = UDim2.fromOffset(74, 17),
			}),

			robux = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "555",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(15, 127),
				Size = UDim2.fromOffset(28, 12),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
			}),
		}),

		packFive = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.56, 0.726),
			Size = UDim2.fromOffset(201, 163),
		}, {
			robuxPrice3 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "555",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 127),
				Size = UDim2.fromOffset(28, 12),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
			}),

			coins4 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "$100,000",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 101),
				Size = UDim2.fromOffset(74, 17),
			}),
		}),

		packSix = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.836, 0.517),
			Size = UDim2.fromOffset(231, 338),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
			}),

			coins5 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "$100,000",
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(23, 276),
				Size = UDim2.fromOffset(74, 17),
			}),

			robux1 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "555",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 302),
				Size = UDim2.fromOffset(28, 12),
			}),

			bestDeal = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 229, 87),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(112, 13),
				Size = UDim2.fromOffset(109, 42),
			}, {
				stroke = e("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 1,
				}),

				bestDeal1 = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = "Best Deal",
					TextColor3 = Color3.fromRGB(65, 65, 65),
					TextSize = 16,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(15, 16),
					Size = UDim2.fromOffset(78, 12),
				}),

				corner = e("UICorner", {
					CornerRadius = UDim.new(0, 5),
				}),
			}),
		}),
	})
end

return React.memo(CurrencyPage)
