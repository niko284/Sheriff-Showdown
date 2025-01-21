--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local UIStroke = require(ReplicatedStorage.react.components.other.UIStroke)
local useProductInfoFromId = require(ReplicatedStorage.react.hooks.useProductInfoFromId)

local e = React.createElement

type GamepassTemplateProps = {
	gamepassId: number,
	giftRecipient: Player?,
	giftProductId: number,
	showGiftPrompt: (Player, string, number, number, number) -> (),
}

local function GamepassTemplate(props: GamepassTemplateProps)
	local productInfo = useProductInfoFromId(props.gamepassId, Enum.InfoType.GamePass)

	return e("ImageButton", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.533, 0.288),
		[React.Event.Activated] = function()
			if props.giftRecipient and productInfo then
				props.showGiftPrompt(
					props.giftRecipient,
					productInfo.Name,
					productInfo.PriceInRobux,
					props.gamepassId,
					props.giftProductId
				)
			else
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, props.gamepassId)
			end
		end,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e(UIStroke, {
			color = Color3.fromRGB(255, 255, 255),
		}),

		passIcon = e("ImageLabel", {
			Image = productInfo and string.format("rbxassetid://%d", productInfo.IconImageAssetId) or "",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(150, 150),
			Position = UDim2.fromOffset(80, 10),
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
				Enum.FontWeight.ExtraBold,
				Enum.FontStyle.Normal
			),
			Text = productInfo and productInfo.Name or "Unknown Gamepass",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 110),
			Size = UDim2.fromOffset(91, 12),
		}, {
			stroke = e(UIStroke, {
				color = Color3.fromRGB(0, 0, 0),
				thickness = 1.8,
			}),
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
			Position = UDim2.fromOffset(15, 20),
			Size = UDim2.fromOffset(28, 12),
		}),
	})
end

return React.memo(GamepassTemplate)
