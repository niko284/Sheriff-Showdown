-- Item Holder
-- November 17th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components
local Hooks = ReplicatedStorage.hooks
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local FrameComponents = Components.frames
local InventoryComponents = Components.inventory

local AutomaticScrollingFrame = require(FrameComponents.AutomaticScrollingFrame)
local BaseItem = require(InventoryComponents.BaseItem)
local ItemController = require(Controllers.ItemController)
local ItemSorters = require(Constants.ItemSorters)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Rarities = require(Constants.Rarities)
local React = require(Packages.React)
local Sift = require(Packages.Sift)
local StringUtils = require(Utils.StringUtils)
local Types = require(Constants.Types)
local createNextOrder = require(Hooks.createNextOrder)

local e = React.createElement

type ItemHolderProps = Types.FrameProps & {
	inventory: Types.Inventory,
	searchQuery: string,
	scrollBarImageTransparency: number?,
	scrollBarThickness: number?,
	sortOption: string?,
	onActivated: (element: ImageButton, item: Types.Item, isEquipped: boolean, viewProps: any) -> (),
	onItemHovered: ((element: ImageButton, item: Types.Item) -> ())?,
	onItemUnhovered: ((element: ImageButton, item: Types.Item) -> ())?,
	children: any,
	getExtraProps: ((item: Types.Item) -> any)?,
	onScroll: (() -> ())?,
	filterItemFromList: ((item: Types.Item) -> boolean)?,
}

-- // Item Holder \\

local function ItemHolder(props: ItemHolderProps)
	local nextOrder = createNextOrder()

	local inventoryElements = {}

	local equippedItems = {}
	local storageItems = {}

	local filteredItems = {}

	if props.inventory then
		for _, item in props.inventory.Items do
			local isEquipped = table.find(props.inventory.Equipped, item.UUID)
			local extraProps = props.getExtraProps and props.getExtraProps(item) or {}
			if extraProps.isEquipped ~= nil then -- we might have different equip behavior than the default inventory. it's specified in the extra props.
				isEquipped = extraProps.isEquipped
			end
			if props.filterItemFromList and props.filterItemFromList(item) then
				table.insert(filteredItems, item.UUID) -- we want to keep it in the list but not show it to keep things memory efficient
			end
			if isEquipped then
				table.insert(equippedItems, item)
			else
				table.insert(storageItems, item)
			end
		end
	end

	if props.sortOption then
		local sorter = ItemSorters[props.sortOption].Sorter
		if sorter then
			storageItems = Sift.Array.sort(storageItems, sorter)
			equippedItems = Sift.Array.sort(equippedItems, sorter)
		end
	end

	-- sort both equipped and storage items where favorited items are first. after favorited items are put on top, sort by rarity
	local favoritedSorter = function(a: Types.Item, b: Types.Item)
		if a.Favorited and not b.Favorited then
			return true
		elseif not a.Favorited and b.Favorited then
			return false
		else
			local aRarity = ItemUtils.GetItemInfoFromId(a.Id).Rarity
			local bRarity = ItemUtils.GetItemInfoFromId(b.Id).Rarity
			local rarityInfoA = Rarities[aRarity]
			local rarityInfoB = Rarities[bRarity]
			-- we want to push items with no rarity to the bottom of the list.
			if not rarityInfoA then
				return false
			elseif not rarityInfoB then
				return true
			end
			return rarityInfoA.Weight < rarityInfoB.Weight
		end
	end

	storageItems = Sift.Array.sort(storageItems, favoritedSorter)
	equippedItems = Sift.Array.sort(equippedItems, favoritedSorter)

	for _, item in equippedItems do
		local itemInfo = ItemUtils.GetItemInfoFromId(item.Id) :: Types.ItemInfo

		local layoutOrder = nextOrder()

		local visible = true
		if
			(props.searchQuery and StringUtils.MatchesSearch(itemInfo.Name, props.searchQuery) == false)
			or table.find(filteredItems, item.UUID)
		then
			visible = false
		end

		local extraProps = {
			key = item.UUID,
			item = item,
			onActivated = props.onActivated,
			onHover = props.onItemHovered,
			onUnhover = props.onItemUnhovered,
			isEquipped = true,
			noDash = item.Level == nil,
			layoutOrder = layoutOrder,
			visible = visible,
		}

		extraProps = props.getExtraProps and Sift.Dictionary.merge(extraProps, props.getExtraProps(item)) or extraProps -- Merge extra props from custom props function

		table.insert(inventoryElements, e(BaseItem, ItemController:BuildBaseItemProps(item.Id, extraProps)))
	end

	local itemsAlreadyAsOne = {}
	for _, item in storageItems do
		local itemInfo = ItemUtils.GetItemInfoFromId(item.Id) :: Types.ItemInfo
		local itemTypeInfo = ItemTypes[itemInfo.Type]

		local layoutOrder = nextOrder()

		local visible = true
		if
			(props.searchQuery and StringUtils.MatchesSearch(itemInfo.Name, props.searchQuery) == false)
			or table.find(filteredItems, item.UUID)
		then
			visible = false
		end

		local extraProps = {
			key = item.UUID,
			onActivated = props.onActivated,
			onHover = props.onItemHovered,
			onUnhover = props.onItemUnhovered,
			noDash = item.Level == nil,
			item = item,
			isEquipped = false,
			layoutOrder = layoutOrder,
			visible = visible,
		}

		extraProps = props.getExtraProps and Sift.Dictionary.merge(extraProps, props.getExtraProps(item)) or extraProps -- Merge extra props from custom props function

		if itemTypeInfo.ShowAsOne then
			if table.find(itemsAlreadyAsOne, itemInfo.Id) then -- already shown in the list as one (like x5), so don't show it again
				continue
			end

			table.insert(itemsAlreadyAsOne, itemInfo.Id)
			local itemAmount = 0
			for _, itemOfType in props.inventory.Items do
				if itemOfType.Id == itemInfo.Id then
					itemAmount = itemAmount + 1
				end
			end

			extraProps.amount = itemAmount
		end

		table.insert(inventoryElements, e(BaseItem, ItemController:BuildBaseItemProps(item.Id, extraProps)))
	end

	return e(AutomaticScrollingFrame, {
		anchorPoint = props.anchorPoint,
		size = props.size,
		position = props.position,
		topImage = "",
		bottomImage = "",
		layoutOrder = props.layoutOrder,
		scrollBarThickness = props.scrollBarThickness or 6,
		backgroundTransparency = props.backgroundTransparency,
		onScroll = props.onScroll,
		scrollBarImageTransparency = props.scrollBarImageTransparency,
		backgroundColor3 = props.backgroundColor3,
	}, {
		inventoryItems = React.createElement(React.Fragment, nil, inventoryElements),
		children = React.createElement(React.Fragment, nil, props.children),
	})
end

return React.memo(ItemHolder)
