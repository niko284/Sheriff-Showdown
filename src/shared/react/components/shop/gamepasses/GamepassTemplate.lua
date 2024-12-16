--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local React = require(ReplicatedStorage.packages.React)
local useProductInfoFromId = require(ReplicatedStorage.react.hooks.useProductInfoFromId)

local e = React.createElement

type GamepassTemplateProps = {
	gamepassId: number,
}

local function GamepassTemplate(props: GamepassTemplateProps)
	local productInfo = useProductInfoFromId(props.gamepassId, Enum.InfoType.GamePass)

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.533, 0.288),
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		button = e("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 2,
			Size = UDim2.fromScale(1, 1),
			[React.Event.Activated] = function()
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, props.gamepassId)
			end,
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),

		passIcon = e("ImageLabel", {
			Image = productInfo and string.format("rbxassetid://%d", productInfo.IconImageAssetId) or "",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(161, 168),
			ZIndex = 0,
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = string.format("Buy %s", productInfo and productInfo.Name or "Unknown Gamepass"),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.369,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 132),
			Size = UDim2.fromOffset(80, 14),
		}),

		passName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = productInfo and productInfo.Name or "Unknown Gamepass",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 110),
			Size = UDim2.fromOffset(91, 12),
		}),

		robuxAmount = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d", productInfo and productInfo.PriceInRobux or 0),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(165, 20),
			Size = UDim2.fromOffset(28, 12),
		}),
	})
end

return React.memo(GamepassTemplate)
