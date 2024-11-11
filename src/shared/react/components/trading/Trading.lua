--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Hooks = ReplicatedStorage.react.hooks
local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local AcceptIndicator = require(Components.trading.AcceptIndicator)
local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local Button = require(Components.buttons.Button)
local ConfirmationPrompt = require(Components.other.ConfirmationPrompt)
local CurrentInterfaceContext = require(Contexts.CurrentInterfaceContext)
local InterfaceController = require(Controllers.InterfaceController)
local InventoryContext = require(Contexts.InventoryContext)
local InventoryController = require(Controllers.InventoryController)
local InventoryUtils = require(ReplicatedStorage.utils.InventoryUtils)
local Net = require(ReplicatedStorage.packages.Net)
local PlayerIcon = require(Components.other.PlayerIcon)
local RadialLoading = require(Components.other.RadialLoading)
local React = require(ReplicatedStorage.packages.React)
local Remotes = require(ReplicatedStorage.network.Remotes)
local TradeContext = require(Contexts.TradeContext)
local TradeItemTemplate = require(Components.trading.TradeItemTemplate)
local TradingController = require(Controllers.TradingController)
local Types = require(ReplicatedStorage.constants.Types)
local UUIDSerde = require(ReplicatedStorage.network.serde.UUIDSerde)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)
local createNextOrder = require(Hooks.createNextOrder)

local TradingNamespace = Remotes.Client:GetNamespace("Trading")
local AcceptTrade = TradingNamespace:Get("AcceptTrade") :: Net.ClientAsyncCaller
local DeclineTrade = TradingNamespace:Get("DeclineTrade") :: Net.ClientAsyncCaller
local ConfirmTrade = TradingNamespace:Get("ConfirmTrade") :: Net.ClientAsyncCaller
local TradeProcessed = TradingNamespace:Get("TradeProcessed") :: Net.ClientListenerEvent

local e = React.createElement
local useContext = React.useContext
local useRef = React.useRef
local useCallback = React.useCallback
local useState = React.useState
local useEffect = React.useEffect

type TradingProps = {}

local function Trading(_props: TradingProps)
	local _shouldRender, styles =
		animateCurrentInterface("ActiveTrade", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))
	local nextOrder = createNextOrder()

	local currentTradeUUID = useRef(nil :: string?)

	local tradeState = useContext(TradeContext)
	local currentInterface = useContext(CurrentInterfaceContext)
	local inventory = useContext(InventoryContext)

	local timeLeft, setTimeLeft = useState(0)

	local confirmTrade = useCallback(function()
		if not tradeState.currentTrade then
			return
		end

		local serializedTradeUUID = UUIDSerde.Serialize(tradeState.currentTrade.UUID)

		-- show loading state since confirming trade might take a while
		local newTradeState = table.clone(tradeState)
		local newCurrentTrade = table.clone(newTradeState.currentTrade :: Types.Trade)

		table.insert(newCurrentTrade.Confirmed, LocalPlayer)
		newTradeState.currentTrade = newCurrentTrade

		if #newCurrentTrade.Confirmed == 2 then
			newCurrentTrade.Status = "Completed"
		end

		TradingController.TradeStateChanged:Fire(newTradeState)

		ConfirmTrade:CallServerAsync(serializedTradeUUID)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					TradingController.TradeStateChanged:Fire(tradeState) -- rollback
					warn(response.Message)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, { tradeState })

	local acceptTrade = useCallback(function()
		if not tradeState.currentTrade then
			return
		end

		local serializedTradeUUID = UUIDSerde.Serialize(tradeState.currentTrade.UUID)

		AcceptTrade:CallServerAsync(serializedTradeUUID)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					warn(response.Message)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, { tradeState })
	local declineTrade = useCallback(function()
		if not tradeState.currentTrade then
			return
		end

		local serializedTradeUUID = UUIDSerde.Serialize(tradeState.currentTrade.UUID)

		DeclineTrade:CallServerAsync(serializedTradeUUID)
			:andThen(function(response: Types.NetworkResponse)
				--print(response)
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, { tradeState })

	local currentTrade = tradeState.currentTrade
	local otherPlayer = nil
	local myOffer = nil :: { Types.Item }?
	local otherOffer = nil :: { Types.Item }?

	if currentTrade then
		otherPlayer = currentTrade.Receiver == LocalPlayer and currentTrade.Sender or currentTrade.Receiver
		myOffer = currentTrade.Sender == LocalPlayer and currentTrade.SenderOffer or currentTrade.ReceiverOffer
		otherOffer = currentTrade.Sender == LocalPlayer and currentTrade.ReceiverOffer or currentTrade.SenderOffer
	end

	local otherAccepted = currentTrade and table.find(currentTrade.Accepted, otherPlayer) or false
	local clientAccepted = currentTrade and table.find(currentTrade.Accepted, LocalPlayer) or false

	local isConfirmStage = currentTrade and currentTrade.Status == "Confirming" or false
	local tradeCompleted = currentTrade and currentTrade.Status == "Completed" or false
	local wasConfirmed = currentTrade and table.find(currentTrade.Confirmed, LocalPlayer) or false

	local myTradeItemElements = {}
	local theirTradeItemElements = {}

	if currentTrade and myOffer and otherOffer then
		-- Create elements for the already existing items in the trade
		for _, item in ipairs(myOffer) do
			table.insert(
				myTradeItemElements,
				e(TradeItemTemplate, {
					item = item,
					canAddItem = currentTrade.Status == "Started",
					key = item.UUID,
					layoutOrder = nextOrder(),
				})
			)
		end
		for _, item in ipairs(otherOffer) do
			table.insert(
				theirTradeItemElements,
				e(TradeItemTemplate, {
					item = item,
					canAddItem = false,
					key = item.UUID,
					layoutOrder = nextOrder(),
				})
			)
		end

		-- Fill in the rest of the slots with placeholders
		local myRemainingSlots = currentTrade.MaximumItems - #myOffer
		for i = 1, myRemainingSlots do
			table.insert(
				myTradeItemElements,
				e(
					TradeItemTemplate,
					{
						canAddItem = true,
						item = nil,
						key = tostring(#myOffer + i),
						layoutOrder = nextOrder(),
					} :: any
				)
			)
		end

		local theirRemainingSlots = currentTrade.MaximumItems - #otherOffer
		for i = 1, theirRemainingSlots do
			table.insert(
				theirTradeItemElements,
				e(
					TradeItemTemplate,
					{
						canAddItem = false,
						item = nil,
						key = tostring(#otherOffer + i),
						layoutOrder = nextOrder(),
					} :: any
				)
			)
		end
	end

	useEffect(function()
		local currTradeUUID = currentTrade and currentTrade.UUID

		if currentTradeUUID.current ~= currTradeUUID and currTradeUUID ~= nil then
			-- new trade, open the trading interface
			InterfaceController.InterfaceChanged:Fire("ActiveTrade")

			local newTradeState = table.clone(tradeState)
			newTradeState.showTradeSideButton = true
			TradingController.TradeStateChanged:Fire(newTradeState)
		elseif currTradeUUID == nil then
			-- no trade, close the active trade interface if it's open
			if currentInterface.current == "ActiveTrade" then
				InterfaceController.InterfaceChanged:Fire(nil)
				local newTradeState = table.clone(tradeState)
				newTradeState.showTradeSideButton = false
				TradingController.TradeStateChanged:Fire(newTradeState)
			end
		end

		local tradeProcessedConnection = TradeProcessed:Connect(function(_tradeUUID: string)
			local newTradeState = table.clone(tradeState)
			newTradeState.showTradeSideButton = false
			TradingController.TradeStateChanged:Fire(newTradeState)

			if inventory then
				local trade = tradeState.currentTrade :: Types.Trade
				local itemsLost = trade.Sender == LocalPlayer and trade.SenderOffer or trade.ReceiverOffer
				local itemsGained = trade.Sender == LocalPlayer and trade.ReceiverOffer or trade.SenderOffer
				local newInventory =
					InventoryUtils.AddItems(InventoryUtils.RemoveItems(inventory, itemsLost), itemsGained)
				InventoryController.InventoryChanged:Fire(newInventory)
			end

			InterfaceController.InterfaceChanged:Fire("TradeProcessed")
		end)

		local cooldownConnection = nil
		if currentTrade and currentTrade.CooldownEnd and currentTrade.CooldownEnd > os.time() then
			cooldownConnection = RunService.Heartbeat:Connect(function()
				local newTimeLeft = currentTrade.CooldownEnd - os.time()
				if newTimeLeft <= 0 then
					cooldownConnection:Disconnect()
				end
				setTimeLeft(math.round(newTimeLeft))
			end)
		end

		currentTradeUUID.current = currTradeUUID

		return function()
			if cooldownConnection then
				cooldownConnection:Disconnect()
			end
			tradeProcessedConnection:Disconnect()
		end
	end, { tradeState, currentInterface, inventory } :: { any })

	return e("ImageLabel", {
		Image = "rbxassetid://18349341250",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(848, 608),
	}, {
		tradingWith = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = currentTrade and string.format("Trading with %s", otherPlayer.Name) or "Trading",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(27, 132),
			Size = UDim2.fromOffset(276, 21),
		}),

		confirming = isConfirmStage and e(ConfirmationPrompt, {
			title = "Confirm Trade",
			description = "Are you sure you want to accept this trade?",
			acceptText = wasConfirmed and "Confirmed" or "Confirm",
			cancelText = "Decline",
			onAccept = confirmTrade,
			onCancel = declineTrade,
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18349391822",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18349341421",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			trading = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Trading\r",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(64, 35),
				Size = UDim2.fromOffset(88, 21),
			}),

			tradeIcon3 = e("ImageLabel", {
				Image = "rbxassetid://18349342236",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(32, 30),
				Size = UDim2.fromOffset(8, 8),
			}),

			tradeIcon2 = e("ImageLabel", {
				Image = "rbxassetid://18349342382",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(30, 36),
				Size = UDim2.fromOffset(12, 17),
			}),

			tradeIcon1 = e("ImageLabel", {
				Image = "rbxassetid://18349353841",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 42),
				Size = UDim2.fromOffset(27, 15),
			}),
		}),

		yourItems = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Your Items",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 216),
			Size = UDim2.fromOffset(91, 12),
		}),

		theirItems = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%s's Items", otherPlayer and otherPlayer.Name or "Player"),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(565, 216),
			Size = UDim2.fromOffset(149, 12),
		}),

		decline = not tradeCompleted and not isConfirmStage and e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Decline",
			textColor3 = Color3.fromRGB(53, 0, 12),
			textSize = 16,
			position = UDim2.fromScale(0.714, 0.235),
			anchorPoint = Vector2.new(0.5, 0.5),
			size = UDim2.fromOffset(137, 44),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 68, 118)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(203, 35, 67)),
			}),
			strokeThickness = 1.5,
			strokeColor = Color3.fromRGB(255, 255, 255),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			gradientRotation = -90,
			onActivated = declineTrade,
		}),

		clientAcceptIndicator = clientAccepted and e(AcceptIndicator, {
			text = "You have accepted",
			position = UDim2.fromOffset(27, 534),
		}),

		otherAcceptIndicator = otherAccepted and e(AcceptIndicator, {
			text = string.format("%s has accepted", otherPlayer and otherPlayer.Name or "Player"),
			position = UDim2.fromOffset(564, 534),
		}),

		flowArrow2 = timeLeft <= 0 and e("ImageLabel", {
			Image = "rbxassetid://18349354330",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(408, 385),
			Size = UDim2.fromOffset(32, 32),
		}),

		cooldownText = timeLeft > 0 and e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = tostring(timeLeft),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 46,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(407, 298),
			Size = UDim2.fromOffset(34, 38),
		}),

		accept = clientAccepted == false and e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Accept",
			textColor3 = Color3.fromRGB(0, 54, 25),
			anchorPoint = Vector2.new(0.5, 0.5),
			textSize = 16,
			size = UDim2.fromOffset(137, 44),
			position = UDim2.fromScale(0.884, 0.235),
			strokeThickness = 1.5,
			layoutOrder = 1,
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
			}),
			gradientRotation = -90,
			onActivated = acceptTrade,
		}),

		flowArrow1 = timeLeft <= 0 and e("ImageLabel", {
			Image = "rbxassetid://18349366976",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(408, 345),
			Size = UDim2.fromOffset(32, 32),
		}),

		tradeProcessing = tradeCompleted and e("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(25, 25, 25),
			BackgroundTransparency = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			description = e("TextLabel", {
				Font = Enum.Font.FredokaOne,
				Text = string.format("Trade accepted by %s", otherPlayer.Name),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.51),
				Size = UDim2.fromScale(0.8, 0.06),
			}, {
				gradient = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 56)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 223, 0)),
					}),
					Rotation = 90,
				}),
				stroke = e("UIStroke", {
					Color = Color3.fromRGB(27, 16, 18),
					Thickness = 3,
				}),
			}),
			gradient = e("UIGradient", {
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.312),
					NumberSequenceKeypoint.new(1, 0.294),
				}),
			}),
			description2 = e("TextLabel", {
				Font = Enum.Font.FredokaOne,
				Text = "Your trade is processing",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.58),
				Size = UDim2.fromScale(0.8, 0.04),
			}),
			radialLoading = e(RadialLoading, {
				dots = 6,
				dotSize = UDim2.fromScale(0.02, 0.02),
				dotColor = Color3.fromRGB(255, 255, 255),
				radius = 40,
				spacing = 20,
				timeToCycle = 1,
				position = UDim2.fromScale(0.5, 0.75),
				size = UDim2.fromOffset(500, 500),
			}),
			playerIcon = e(PlayerIcon, {
				player = otherPlayer,
				scaleType = Enum.ScaleType.Fit,
				anchorPoint = Vector2.new(0.5, 0.5),
				backgroundTransparency = 1,
				position = UDim2.fromScale(0.5, 0.38),
				size = UDim2.fromScale(0.1, 0.1),
				sizeConstraint = Enum.SizeConstraint.RelativeXX,
				thumbnailSize = Enum.ThumbnailSize.Size352x352,
			}, {
				uICorner8 = e("UICorner", {
					CornerRadius = UDim.new(0.5, 0),
				}),
			}),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18349354566",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 188),
			Size = UDim2.fromOffset(797, 3),
		}),

		theirOfferList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 8,
			active = true,
			backgroundTransparency = 1,
			position = UDim2.fromScale(0.658, 0.413),
			size = UDim2.fromOffset(276, 268),
		}, {
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 3),
				PaddingTop = UDim.new(0, 3),
			}),

			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(6, 6),
				CellSize = UDim2.fromOffset(126, 126),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			theirItems = e(React.Fragment, nil, theirTradeItemElements),
		}),

		myOfferList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 8,
			active = true,
			backgroundTransparency = 1,
			position = UDim2.fromScale(0.0259, 0.413),
			size = UDim2.fromOffset(276, 268),
		}, {
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(7, 7),
				CellSize = UDim2.fromOffset(126, 126),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 3),
				PaddingTop = UDim.new(0, 3),
			}),

			myItems = e(React.Fragment, nil, myTradeItemElements),
		}),
	})
end

return Trading
