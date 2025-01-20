--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local ConfirmationPrompt = require(ReplicatedStorage.react.components.other.ConfirmationPrompt)
local FormatNumber = require(ReplicatedStorage.utils.FormatNumber)
local GamepassTemplate = require(Components.shop.gamepasses.GamepassTemplate)
local Gamepasses = require(ReplicatedStorage.constants.Gamepasses)
local React = require(ReplicatedStorage.packages.React)
local ShopContext = require(ReplicatedStorage.react.contexts.ShopContext)

local e = React.createElement
local useContext = React.useContext
local useCallback = React.useCallback
local useState = React.useState

local NumberFormatter = FormatNumber.NumberFormatter

local PriceFormatter = NumberFormatter.with():Precision(FormatNumber.Precision.integer())

type GamepassPageProps = {
	pageRef: (ref: Frame) -> (),
}

local function GamepassPage(props: GamepassPageProps)
	local shopState = useContext(ShopContext)
	local giftData, setGiftData = useState(nil :: any)

	local showGiftPrompt = useCallback(
		function(
			giftPlayer: Player,
			gamepassName: string,
			gamepassPrice: number,
			gamepassId: number,
			giftProductId: number
		)
			setGiftData({
				description = string.format(
					'Would you like to gift %s %s for <font color="rgb(131,242,143)">%s %s</font>?',
					giftPlayer.Name,
					gamepassName,
					PriceFormatter:Format(gamepassPrice),
					"Robux"
				),
				gamepassId = gamepassId,
				onAccept = function()
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, giftProductId)
					setGiftData(nil)
				end,
				onCancel = function()
					setGiftData(nil)
				end,
			})
		end
	)

	local gamepassElements = {}
	for _, gamepass in Gamepasses do
		-- only show gamepass templates that have a gift product id if we're gifting
		if shopState.giftRecipient and not gamepass.GiftProductId then
			continue
		end
		if
			shopState.giftRecipient
			and shopState.giftedGamepasses
			and table.find(shopState.giftedGamepasses, gamepass.GamepassId)
		then
			continue
		end
		gamepassElements[gamepass.GamepassId] = e(GamepassTemplate, {
			gamepassId = gamepass.GamepassId,
			giftRecipient = shopState.giftRecipient,
			showGiftPrompt = showGiftPrompt,
			giftProductId = gamepass.GiftProductId :: number,
		})
	end

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
		gamepass = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Gamepasses",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 18),
			Size = UDim2.fromOffset(87, 15),
		}),

		giftGamepassPrompt = giftData and e(ConfirmationPrompt, {
			title = "Gift Gamepass",
			description = giftData.description,
			acceptText = "Gift",
			onAccept = giftData.onAccept,
			onCancel = giftData.onCancel,
		}),

		gamepassList = e(AutomaticScrollingFrame, {
			anchorPoint = Vector2.new(0, 0),
			scrollBarThickness = 9,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0133, 0.117),
			size = UDim2.fromOffset(801, 332),
		}, {
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingTop = UDim.new(0, 5),
			}),
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(15, 15),
				CellSize = UDim2.fromOffset(245, 166),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			passes = e(React.Fragment, nil, gamepassElements),
		}),
	})
end

return React.memo(GamepassPage)
