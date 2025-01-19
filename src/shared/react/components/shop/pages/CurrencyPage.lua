--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Currencies = require(ReplicatedStorage.constants.Currencies)
local FormatNumber = require(ReplicatedStorage.utils.FormatNumber)
local Freeze = require(ReplicatedStorage.packages.Freeze)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)
local UIStroke = require(ReplicatedStorage.react.components.other.UIStroke)
local useProductInfoFromIds = require(ReplicatedStorage.react.hooks.useProductInfoFromIds)

local NumberFormatter = FormatNumber.NumberFormatter

local e = React.createElement
local useRef = React.useRef
local useMemo = React.useMemo

local DEFAULT_RATIO = 10 -- 10:1 coin to robux ratio

type CurrencyPageProps = {
	pageRef: (ref: Frame) -> (),
}

local currencyInfo = (Currencies :: any).Coins :: Types.CurrencyData
local productIds = Freeze.Dictionary.map(currencyInfo.Packs, function(pack)
	return Enum.InfoType.Product, pack.ProductId
end) :: { [number]: Enum.InfoType }

local function CurrencyPage(props: CurrencyPageProps)
	local formatter = useRef(NumberFormatter.with():Precision(FormatNumber.Precision.integer()))

	local productInfo = useProductInfoFromIds(productIds)

	local packData = useMemo(function()
		local data = {}
		for index, pack in currencyInfo.Packs do
			local devProductInfo = productInfo[currencyInfo.Packs[index].ProductId]
			local robuxPrice = devProductInfo and devProductInfo.PriceInRobux or 0
			local defaultRatioAmount = robuxPrice * DEFAULT_RATIO

			local gain = pack.Amount - defaultRatioAmount -- if we can't find a price our gain will just be equal to amount

			local coinAmountText = nil
			if gain ~= pack.Amount and gain > 0 then
				coinAmountText = string.format(
					`%s + <stroke color="#000000"><font weight="heavy" color="#83f28f">%s</font></stroke> Coins`,
					formatter.current:Format(pack.Amount - gain),
					formatter.current:Format(gain)
				)
			else
				coinAmountText = string.format("%s Coins", formatter.current:Format(pack.Amount))
			end

			data[index] = {
				coinAmount = coinAmountText,
				packPrice = robuxPrice > 0 and string.format("%d", robuxPrice) or "???",
				onActivated = function()
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, pack.ProductId)
				end,
			}
		end
		return data
	end, { productInfo })

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

		packOne = e("ImageButton", {
			Image = "",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(72, 72, 72),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.113, 0.309),
			Size = UDim2.fromOffset(163, 163),
			[React.Event.Activated] = packData[1].onActivated,
		}, {
			stroke = e(UIStroke, {
				color = Color3.fromRGB(255, 255, 255),
			}),

			icon = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", currencyInfo.Packs[1].Image),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.117, 0.153),
				Size = UDim2.fromScale(0.755, 0.684),
				ZIndex = 0,
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			coins = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.ExtraBold,
					Enum.FontStyle.Normal
				),
				Text = packData[1].coinAmount,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 104),
				RichText = true,
				Size = UDim2.fromOffset(74, 17),
			}, {
				stroke = e(UIStroke, {
					color = Color3.fromRGB(0, 0, 0),
				}),
			}),

			robuxPrice = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = packData[1].packPrice,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 131),
				Size = UDim2.fromOffset(28, 12),
			}),
		}),

		packTwo = e("ImageButton", {
			Image = "",
			[React.Event.Activated] = packData[2].onActivated,
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
					Enum.FontWeight.ExtraBold,
					Enum.FontStyle.Normal
				),
				Text = packData[2].coinAmount,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 20,
				RichText = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(16, 104),
				Size = UDim2.fromOffset(74, 17),
			}, {
				stroke = e(UIStroke, {
					color = Color3.fromRGB(0, 0, 0),
				}),
			}),

			icon = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", currencyInfo.Packs[2].Image),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.117, 0.153),
				Size = UDim2.fromScale(0.755, 0.684),
				ZIndex = 0,
			}),

			robuxPrice1 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = packData[2].packPrice,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(15, 129),
				Size = UDim2.fromOffset(28, 12),
			}),

			stroke = e(UIStroke, {
				color = Color3.fromRGB(255, 255, 255),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),
		}),

		packThree = e("ImageButton", {
			Image = "",
			[React.Event.Activated] = packData[3].onActivated,
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

			stroke = e(UIStroke, {
				color = Color3.fromRGB(255, 255, 255),
			}),

			icon = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", currencyInfo.Packs[3].Image),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.117, 0.153),
				Size = UDim2.fromScale(0.755, 0.684),
				ZIndex = 0,
			}),

			coins2 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.ExtraBold,
					Enum.FontStyle.Normal
				),
				Text = packData[3].coinAmount,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				RichText = true,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 104),
				Size = UDim2.fromOffset(74, 17),
			}, {
				stroke = e(UIStroke, {
					color = Color3.fromRGB(0, 0, 0),
				}),
			}),

			robuxPrice2 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = packData[3].packPrice,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 130),
				Size = UDim2.fromOffset(28, 12),
			}),
		}),

		packFour = e("ImageButton", {
			Image = "",
			[React.Event.Activated] = packData[4].onActivated,
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
					Enum.FontWeight.ExtraBold,
					Enum.FontStyle.Normal
				),
				Text = packData[4].coinAmount,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 100),
				Size = UDim2.fromOffset(74, 17),
				RichText = true,
			}, {
				stroke = e(UIStroke, {
					color = Color3.fromRGB(0, 0, 0),
				}),
			}),

			icon = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", currencyInfo.Packs[4].Image),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.129, -0.0116),
				Size = UDim2.fromScale(0.76, 0.981),
				ZIndex = 0,
			}),

			robux = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = packData[4].packPrice,
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

			stroke = e(UIStroke, {
				color = Color3.fromRGB(255, 255, 255),
			}),
		}),

		packFive = e("ImageButton", {
			Image = "",
			[React.Event.Activated] = packData[5].onActivated,
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
				Text = packData[5].packPrice,
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

			stroke = e(UIStroke, {
				color = Color3.fromRGB(255, 255, 255),
			}),

			icon = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", currencyInfo.Packs[5].Image),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.117, 0.153),
				Size = UDim2.fromScale(0.755, 0.684),
				ZIndex = 0,
			}),

			coins4 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = packData[5].coinAmount,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				RichText = true,
				Position = UDim2.fromOffset(18, 101),
				Size = UDim2.fromOffset(74, 17),
			}, {
				stroke = e(UIStroke, {
					color = Color3.fromRGB(0, 0, 0),
				}),
			}),
		}),

		packSix = e("ImageButton", {
			Image = "",
			[React.Event.Activated] = packData[6].onActivated,
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

			stroke = e(UIStroke, {
				color = Color3.fromRGB(255, 255, 255),
			}),

			icon = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", currencyInfo.Packs[6].Image),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(-5.28e-07, 0.204),
				Size = UDim2.fromScale(1, 0.684),
				ZIndex = 0,
			}),

			coins5 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.ExtraBold,
					Enum.FontStyle.Normal
				),
				Text = packData[6].coinAmount,
				TextColor3 = Color3.fromRGB(240, 240, 240),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(23, 276),
				RichText = true,
				Size = UDim2.fromOffset(74, 17),
			}, {
				stroke = e(UIStroke, {
					color = Color3.fromRGB(0, 0, 0),
				}),
			}),

			robux1 = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = packData[6].packPrice,
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
				stroke = e(UIStroke, {
					color = Color3.fromRGB(255, 255, 255),
					thickness = 1,
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
