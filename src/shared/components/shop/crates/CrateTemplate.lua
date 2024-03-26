-- Crate Template
-- February 23rd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components
local ShopOther = Components.shop.other

local PriceIndicator = require(ShopOther.PriceIndicator)
local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement

-- // Crate Template \\

type CrateTemplateProps = Types.FrameProps & {
	name: string,
	image: number,
	purchaseInfo: { Types.CratePurchaseInfo },
	onActivated: () -> (),
}

local function CrateTemplate(props: CrateTemplateProps)
	local priceIndicatorElements = {}
	for _, purchaseInfo in props.purchaseInfo do
		table.insert(
			priceIndicatorElements,
			e(PriceIndicator, {
				PurchaseType = purchaseInfo.PurchaseType,
				size = UDim2.fromOffset(67, 23),
				Price = purchaseInfo.Price,
				ProductId = purchaseInfo.ProductId,
				key = purchaseInfo.PurchaseType,
			})
		)
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {

		priceList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(-3.27e-07, 0.485),
			Size = UDim2.fromOffset(92, 79),
		}, {
			uIListLayout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
			}),
			elements = e(React.Fragment, nil, priceIndicatorElements),
		}),

		button = e("TextButton", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 14,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.fromScale(1, 1),
			[React.Event.Activated] = props.onActivated,
		}, {
			uICorner = e("UICorner"),

			uIStroke = e("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Thickness = 2,
				Transparency = 0.7,
			}, {
				uIGradient = e("UIGradient", {
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
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = props.name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTransparency = 0.3,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.025, 0.0915),
				Size = UDim2.fromOffset(149, 33),
			}),

			backdrop = e("ImageLabel", {
				Image = "rbxassetid://16420178360",
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.284, 0.168),
				Size = UDim2.fromOffset(197, 197),
			}, {
				crateImage = e("ImageLabel", {
					Image = string.format("rbxassetid://%d", props.image),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
				}, {
					uIGradient1 = e("UIGradient", {
						Rotation = 90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.545, 0),
							NumberSequenceKeypoint.new(0.625, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),

				uIGradient2 = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 225, 0)),
					}),
					Offset = Vector2.new(0.4, 0),
					Rotation = 38,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.847),
						NumberSequenceKeypoint.new(0.121, 0.727),
						NumberSequenceKeypoint.new(0.194, 0.656),
						NumberSequenceKeypoint.new(0.32, 0.191),
						NumberSequenceKeypoint.new(0.473, 0.874),
						NumberSequenceKeypoint.new(0.677, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),

			uIGradient3 = e("UIGradient", {
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
		}),
	})
end

return React.memo(CrateTemplate)
