-- Crate Purchase
-- March 2nd, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components
local ButtonComponents = Components.buttons
local Hooks = ReplicatedStorage.hooks
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local Crates = require(Constants.Crates)
local CurrencyButton = require(ButtonComponents.CurrencyButton)
local React = require(Packages.React)
local Remotes = require(ReplicatedStorage.Remotes)
local ShopController = require(Controllers.ShopController)
local TransactionController = require(Controllers.TransactionController)
local Types = require(Constants.Types)
local useOwnsGamepass = require(Hooks.useOwnsGamepass)
local useProductInfoFromIds = require(Hooks.useProductInfoFromIds)

local TransactionsNamespace = Remotes.Client:GetNamespace("Transactions")
local PurchaseCrates = TransactionsNamespace:Get("PurchaseCrates")

local useCallback = React.useCallback
local useMemo = React.useMemo
local e = React.createElement
local useState = React.useState

-- // Crate Purchase \\

type CratePurchaseProps = {
	crateType: Types.CrateType,
	setCrateInfo: (crateInfo: Types.CrateInfo?) -> (),
}

local function CratePurchase(props: CratePurchaseProps)
	local amountPurchasing, setAmountPurchasing = useState(1)

	local crateInfo = Crates[props.crateType]

	local multipleCratesPass = TransactionController:GetGamepassByName("Multiple Crates")

	local playerOwnsPass = useOwnsGamepass(multipleCratesPass.GamepassId)

	local onCratePurchase = useCallback(function(purchaseInfo: Types.CratePurchaseInfo)
		PurchaseCrates:CallServerAsync(props.crateType, purchaseInfo.PurchaseType, amountPurchasing)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success then
					ShopController:OpenMultipleCrates(props.crateType, response.Response)
				else
					warn(response.Response)
				end
			end)
	end, { props.crateType, amountPurchasing })

	local productInfoData = useMemo(function()
		local newData = {}
		for _, purchaseInfo in crateInfo.PurchaseInfo do
			if purchaseInfo.ProductId then
				newData[purchaseInfo.ProductId] = Enum.InfoType.Product
			end
		end
		return newData
	end, { props.crateType })

	local productInfos = useProductInfoFromIds(productInfoData)

	local purchaseButtons = {}
	for _, purchaseInfo in crateInfo.PurchaseInfo do
		local price = purchaseInfo.Price
		if purchaseInfo.ProductId then
			local productInfo = productInfos[purchaseInfo.ProductId]
			if productInfo then
				price = productInfo.PriceInRobux
			end
		end

		purchaseButtons[purchaseInfo.PurchaseType] = e(CurrencyButton, {
			size = UDim2.fromOffset(157, 51),
			amount = price * amountPurchasing,
			currency = purchaseInfo.PurchaseType,
			onActivated = function()
				onCratePurchase(purchaseInfo)
			end,
		})
	end

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(500, 300),
	}, {
		text = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Text = "Confirm Purchase",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0288, 0.0244),
			Size = UDim2.fromOffset(475, 37),
		}),

		purchase = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.02, 0.791),
			Size = UDim2.fromOffset(480, 50),
		}, {
			uIListLayout = e("UIListLayout", {
				Padding = UDim.new(0, 7),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			buttons = React.createElement(React.Fragment, nil, purchaseButtons),
		}),

		x = e("TextButton", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = "X",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextTransparency = 0.1,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.895, 0.012),
			Size = UDim2.fromOffset(52, 49),
			[React.Event.Activated] = function()
				props.setCrateInfo(nil)
			end,
		}),

		contents = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.022, 0.147),
			Size = UDim2.fromOffset(478, 193),
		}, {
			crateview = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Size = UDim2.fromOffset(193, 193),
			}, {
				imageLabel = e("ImageLabel", {
					Image = string.format("rbxassetid://%d", crateInfo.ShopImage),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(-0.142, 0.128),
					Size = UDim2.fromOffset(260, 260),
				}, {
					uIGradient = e("UIGradient", {
						Rotation = 90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.545, 0),
							NumberSequenceKeypoint.new(0.625, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),

				amount = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = string.format("x%d", amountPurchasing),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 22,
					TextStrokeTransparency = 0,
					TextWrapped = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.0297, 0.0446),
					Size = UDim2.fromOffset(50, 36),
				}),
			}),

			gamepass = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.447, 0.273),
				Size = UDim2.fromOffset(247, 100),
			}, {
				label = e("TextLabel", {
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
					Text = "How many would you like to purchase?",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.04, 0),
					Size = UDim2.new(0.92, 0, -0.0219, 50),
				}),

				input = e("TextBox", {
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					PlaceholderColor3 = Color3.fromRGB(197, 197, 197),
					PlaceholderText = "Enter Number",
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextWrapped = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.259, 0.599),
					Size = UDim2.fromOffset(128, 37),
					[React.Event.FocusLost] = function(rbx)
						local num = tonumber(rbx.Text)
						if playerOwnsPass and num then
							setAmountPurchasing(math.round(num))
						else
							setAmountPurchasing(1)
							rbx.Text = ""
							TransactionController:PromptGamepassPurchase("Multiple Crates")
						end
					end,
				}),
			}),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 3,
			Transparency = 0.3,
		}, {
			uIGradient1 = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
				}),
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.798),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),

		uIGradient2 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 13, 13)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 36)),
			}),
			Rotation = -90,
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0.01, 8),
		}),
	})
end

return CratePurchase
