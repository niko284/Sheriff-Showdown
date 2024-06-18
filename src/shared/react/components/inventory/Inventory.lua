--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local Utils = ReplicatedStorage.utils
local Hooks = ReplicatedStorage.react.hooks

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CloseButton = require(Components.buttons.CloseButton)
local Freeze = require(ReplicatedStorage.packages.Freeze)
local InventoryContext = require(Contexts.InventoryContext)
local ItemDisplay = require(Components.inventory.ItemDisplay)
local ItemTemplate = require(Components.items.Item)
local ItemUtils = require(Utils.ItemUtils)
local OptionButton = require(Components.buttons.OptionButton)
local React = require(ReplicatedStorage.packages.React)
local Searchbar = require(Components.other.Searchbar)
local Separator = require(Components.other.Separator)
local Types = require(ReplicatedStorage.constants.Types)
local createNextOrder = require(Hooks.createNextOrder)

local e = React.createElement
local useState = React.useState
local useContext = React.useContext
local useCallback = React.useCallback

type InventoryProps = {}

local function Inventory(_props: InventoryProps)
	local inventory: Types.PlayerInventory? = useContext(InventoryContext)
	local nextOrder = createNextOrder()

	local selectedItem: Types.Item?, setSelectedItem = useState(nil)
	local selectedItemInfo: Types.ItemInfo? = if selectedItem then ItemUtils.GetItemInfoFromId(selectedItem.Id) else nil

	local onItemClicked = useCallback(function(uuid: string)
		if inventory then
			for _, inventoryItem in Freeze.List.merge(inventory.Equipped, inventory.Storage) do
				if inventoryItem.UUID == uuid then
					setSelectedItem(inventoryItem)
					break
				end
			end
		end
	end, { inventory })

	local itemElements = {}
	if inventory then
		-- show the equipped items first
		for _, item in inventory.Equipped do
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			itemElements[item.UUID] = e(ItemTemplate, {
				layoutOrder = nextOrder(),
				image = string.format("rbxassetid://%d", itemInfo.Image),
				rarity = itemInfo.Rarity,
				itemName = itemInfo.Name,
				itemSerial = item.Serial,
				killCount = item.Kills,
				itemUUID = item.UUID,
				onItemClicked = onItemClicked,
			})
		end

		-- then show the storage items
		for _, item in inventory.Storage do
			local itemInfo = ItemUtils.GetItemInfoFromId(item.Id)
			itemElements[item.UUID] = e(ItemTemplate, {
				layoutOrder = nextOrder(),
				image = string.format("rbxassetid://%d", itemInfo.Image),
				rarity = itemInfo.Rarity,
				itemName = itemInfo.Name,
				itemSerial = item.Serial,
				itemUUID = item.UUID,
				killCount = item.Kills,
				onItemClicked = onItemClicked,
			}) :: any
		end
	end

	return e("ImageLabel", {
		Image = "rbxassetid://17886529902",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),
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
			}),

			close = e(CloseButton, {
				size = UDim2.fromOffset(43, 43),
				position = UDim2.fromOffset(781, 23),
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
			serial = selectedItem.Serial,
			rarity = selectedItemInfo.Rarity,
			image = string.format("rbxassetid://%d", selectedItemInfo.Image),
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
				CellSize = UDim2.fromOffset(146, 146),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			itemList = React.createElement(React.Fragment, nil, itemElements :: any),

			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
				PaddingTop = UDim.new(0, 5),
			}),
		}),

		optionButton = e(OptionButton, {
			image = "rbxassetid://17886581750",
			size = UDim2.fromOffset(43, 43),
			position = UDim2.fromOffset(781, 119),
		}),
	})
end

return Inventory
