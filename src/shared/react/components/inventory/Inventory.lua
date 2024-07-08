--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local Utils = ReplicatedStorage.utils
local Hooks = ReplicatedStorage.react.hooks
local Controllers = LocalPlayer.PlayerScripts.controllers

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CloseButton = require(Components.buttons.CloseButton)
local InterfaceController = require(Controllers.InterfaceController)
local InventoryContext = require(Contexts.InventoryContext)
local InventoryUtils = require(Utils.InventoryUtils)
local ItemDisplay = require(Components.inventory.ItemDisplay)
local ItemTemplate = require(Components.items.Item)
local ItemTypes = require(ReplicatedStorage.constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local OptionButton = require(Components.buttons.OptionButton)
local React = require(ReplicatedStorage.packages.React)
local Searchbar = require(Components.other.Searchbar)
local Separator = require(Components.other.Separator)
local StringUtils = require(Utils.StringUtils)
local TradeContext = require(Contexts.TradeContext)
local Types = require(ReplicatedStorage.constants.Types)
local animateCurrentInterface = require(Hooks.animateCurrentInterface)
local createNextOrder = require(Hooks.createNextOrder)

local e = React.createElement
local useState = React.useState
local useContext = React.useContext
local useEffect = React.useEffect

type InventoryProps = {}

local function Inventory(_props: InventoryProps)
	local inventory: Types.PlayerInventory? = useContext(InventoryContext)
	local tradeState = useContext(TradeContext)

	local nextOrder = createNextOrder()

	local selectedUUID, setSelectedUUID = useState(nil)
	local searchQuery, setSearchQuery = useState("")
	local expandedGrid, setExpandedGrid = useState(false)

	local _shouldRender, styles =
		animateCurrentInterface("Inventory", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local isTradeMode = tradeState and tradeState.isInInventory == true or false
	local selectedItem = inventory and selectedUUID and InventoryUtils.GetItemOfUUID(inventory, selectedUUID)

	local selectedItemInfo: Types.ItemInfo? = if selectedItem then ItemUtils.GetItemInfoFromId(selectedItem.Id) else nil

	local itemElements = {}
	if inventory then
		-- show the equipped items first
		for _, item in inventory.Equipped do
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			if not StringUtils.MatchesSearch(itemInfo.Name, searchQuery) then
				continue
			end
			local itemTypeInfo = ItemTypes[itemInfo.Type]
			if isTradeMode and (itemTypeInfo.CanTrade == false or item.Locked == true) then
				continue
			end
			itemElements[item.UUID] = e(ItemTemplate, {
				layoutOrder = nextOrder(),
				image = string.format("rbxassetid://%d", itemInfo.Image),
				rarity = itemInfo.Rarity,
				itemName = itemInfo.Name,
				itemSerial = item.Serial,
				killCount = item.Kills,
				isLocked = item.Locked,
				isFavorited = item.Favorited,
				itemUUID = item.UUID,
				onItemClicked = setSelectedUUID,
				gradient = Color3.fromRGB(0, 255, 127), -- override the rarity gradient for equipped items
			})
		end

		-- then show the storage items
		for _, item in inventory.Storage do
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			if not StringUtils.MatchesSearch(itemInfo.Name, searchQuery) then
				continue
			end
			local itemTypeInfo = ItemTypes[itemInfo.Type]
			if isTradeMode and (itemTypeInfo.CanTrade == false or item.Locked == true) then
				continue
			end
			itemElements[item.UUID] = e(ItemTemplate, {
				layoutOrder = nextOrder(),
				image = string.format("rbxassetid://%d", itemInfo.Image),
				rarity = itemInfo.Rarity,
				itemName = itemInfo.Name,
				isFavorited = item.Favorited,
				isLocked = item.Locked,
				itemSerial = item.Serial,
				itemUUID = item.UUID,
				killCount = item.Kills,
				onItemClicked = setSelectedUUID,
			}) :: any
		end
	end

	-- this can happen if the selected item is removed from the inventory, then we should deselect it from the display. (i.e a crate is opened and the item is removed)
	useEffect(function()
		if selectedUUID then
			local item = InventoryUtils.GetItemOfUUID(inventory, selectedUUID)
			if not item then
				setSelectedUUID(nil)
			end
		end
	end, { inventory, selectedUUID } :: { any })

	return e("ImageLabel", {
		Image = "rbxassetid://17886529902",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(848, 608),
	}, {
		separator = e(Separator, {
			position = UDim2.fromOffset(26, 188),
			size = UDim2.fromOffset(797, 3),
		}),

		yourItems = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Your Items",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 131),
			Size = UDim2.fromOffset(125, 16),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://17886530471",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			title = e("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(24, 31),
				Size = UDim2.fromOffset(151, 26),
			}, {
				inventory = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = "Inventory",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 22,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(42, 5),
					Size = UDim2.fromOffset(109, 20),
				}),

				icon2 = e("ImageLabel", {
					Image = "rbxassetid://17886543491",
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(24, 26),
				}),

				icon1 = e("ImageLabel", {
					Image = "rbxassetid://17886543709",
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(6, 14),
					Size = UDim2.fromOffset(12, 12),
				}),
			}),

			pattern = e("ImageLabel", {
				Image = "rbxassetid://17886543903",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			searchbar = e(Searchbar, {
				position = UDim2.fromOffset(612, 23),
				size = UDim2.fromOffset(162, 43),
				onTextChanged = function(rbx: TextBox)
					setSearchQuery(rbx.Text)
				end,
			}),

			close = e(CloseButton, {
				size = UDim2.fromOffset(43, 43),
				position = UDim2.fromScale(0.945, 0.51),
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire(nil)
				end,
			}),
		}),

		aboutItem = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "About Item",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(532, 216),
			Size = UDim2.fromOffset(94, 12),
		}),

		selectedDisplay = selectedItem and selectedItemInfo and e(ItemDisplay, {
			position = UDim2.fromOffset(531, 246),
			size = UDim2.fromOffset(293, 340),
			itemName = selectedItemInfo.Name,
			itemId = selectedItem.Id,
			isFavorited = selectedItem.Favorited or false,
			serial = selectedItem.Serial,
			isLocked = selectedItem.Locked or false,
			itemUUID = selectedItem.UUID,
			rarity = selectedItemInfo.Rarity,
			image = string.format("rbxassetid://%d", selectedItemInfo.Image),
			isTradeMode = isTradeMode,
		}),

		scrolling = e(AutomaticScrollingFrame, {
			scrollBarThickness = 9,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0318, 0.355),
			size = UDim2.fromOffset(492, 370),
			anchorPoint = Vector2.new(0, 0),
		}, {
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(10, 10),
				CellSize = expandedGrid and UDim2.fromOffset(110, 110) or UDim2.fromOffset(146, 146),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			itemList = React.createElement(React.Fragment, nil, itemElements :: any),

			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 5),
			}),
		}),

		gridExpansion = e(OptionButton, {
			image = "rbxassetid://17886581750",
			size = UDim2.fromOffset(43, 43),
			position = UDim2.fromOffset(781, 119),
			onActivated = function()
				setExpandedGrid(function()
					return not expandedGrid
				end)
			end,
		}),
	})
end

return Inventory
