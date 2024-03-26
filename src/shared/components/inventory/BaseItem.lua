-- Base Item
-- February 13th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde
local PlayerScripts = LocalPlayer.PlayerScripts
local Rodux = PlayerScripts.rodux
local Slices = Rodux.slices
local Utils = ReplicatedStorage.utils
local Controllers = PlayerScripts.controllers

local InventoryController = require(Controllers.InventoryController)
local InventorySlice = require(Slices.InventorySlice)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Rarities = require(Constants.Rarities)
local React = require(Packages.React)
local ReactRodux = require(Packages.ReactRodux)
local Remotes = require(ReplicatedStorage.Remotes)
local Sift = require(Packages.Sift)
local StringUtils = require(Utils.StringUtils)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local InventoryNamespace = Remotes.Client:GetNamespace("Inventory")

local EquipItem = InventoryNamespace:Get("EquipItem")
local UnequipItem = InventoryNamespace:Get("UnequipItem")
local FavoriteItem = InventoryNamespace:Get("FavoriteItem")

local e = React.createElement
local useCallback = React.useCallback

-- // Base Item \\

type BaseItemProps = Types.FrameProps & {
	icon: string,
	name: string,
	item: Types.Item,
	isEquipped: boolean,
}

local function BaseItem(props: BaseItemProps)
	local dispatch = ReactRodux.useDispatch()

	local onEquipItemPressed = useCallback(function()
		-- Let's check if the item type has a certain stack amount. If it does and we have more than that amount, we'll remove the excess items and predict the server will also remove them.
		local itemInfo = ItemUtils.GetItemInfoFromId(props.item.Id) :: Types.ItemInfo
		local itemTypeInfo = ItemTypes[itemInfo.Type]
		local itemRemoved = nil

		local stackAmount = if typeof(itemTypeInfo.StackAmount) == "function"
			then itemTypeInfo.StackAmount(itemInfo)
			else itemTypeInfo.StackAmount
		if stackAmount then
			local itemsOfType = InventoryController:GetItemsOfType(itemInfo.Type, true)
			if #itemsOfType >= stackAmount then
				local _uuidRemoved, itemIndex =
					StringUtils.GetFirstStringInAlphabet(Sift.Array.map(itemsOfType, function(itemOfType)
						return itemOfType.UUID
					end))
				itemRemoved = itemsOfType[itemIndex]
				dispatch(InventorySlice.actions.UnequipItem({
					item = itemRemoved,
				})) -- The server will remove the excess item with the UUID that is first in the alphabetical order.
				-- We use alphabetical order to remove the same item as the server would.
			end
		end

		if itemTypeInfo.UnequipItemsOfType then
			for _, itemType in itemTypeInfo.UnequipItemsOfType do
				local itemsOfType = InventoryController:GetItemsOfType(itemType, true)
				for _, itemOfType in itemsOfType do
					dispatch(InventorySlice.actions.UnequipItem({
						item = itemOfType,
					}))
				end
			end
		end

		dispatch(InventorySlice.actions.EquipItem({
			item = props.item,
		}))

		local serializedUUID = UUIDSerde.Serialize(props.item.UUID)
		EquipItem:CallServerAsync(serializedUUID)
			:andThen(function(networkResponse: Types.NetworkResponse)
				if networkResponse.Success == false then
					warn(networkResponse.Response)
					-- Let's rollback the state, since the server didn't accept the equip request.
					dispatch(InventorySlice.actions.UnequipItem({
						item = props.item,
					}))
					if itemRemoved then
						dispatch(InventorySlice.actions.EquipItem({
							item = itemRemoved,
						}))
					end
				end
			end)
			:catch(function(error: any)
				warn(tostring(error))
				dispatch(InventorySlice.actions.UnequipItem({
					item = props.item,
				}))
				dispatch(InventorySlice.actions.EquipItem({
					item = itemRemoved,
				}))
			end)
	end, { props.item } :: { any }) -- Dependencies

	local onUnequipItemPressed = useCallback(function()
		-- Let's predict that the server will accept the unequip request.
		dispatch(InventorySlice.actions.UnequipItem({
			item = props.item,
		}))

		local serializedUUID = UUIDSerde.Serialize(props.item.UUID)
		return UnequipItem:CallServerAsync(serializedUUID)
			:andThen(function(networkResponse: Types.NetworkResponse)
				if networkResponse.Success == false then
					warn(networkResponse.Response)
					-- Let's rollback the state, since the server didn't accept the unequip request.
					dispatch(InventorySlice.actions.EquipItem({
						item = props.item,
					}))
				end
			end)
			:catch(function(error: any)
				warn(tostring(error))
				dispatch(InventorySlice.actions.EquipItem({
					item = props.item,
				}))
			end)
	end, { props.item } :: { any }) -- Dependencies

	local onFavoritePressed = useCallback(function()
		-- // Favorite the item

		-- we use client-side prediction to make the UI feel more responsive. we can always revert the change if the server doesn't allow it

		local newItem = table.clone(props.item)
		newItem.Favorited = not newItem.Favorited
		dispatch(InventorySlice.actions.SetItem({
			item = newItem,
		}))

		FavoriteItem:CallServerAsync(UUIDSerde.Serialize(props.item.UUID), not props.item.Favorited)
			:andThen(function(networkResponse: Types.NetworkResponse)
				if networkResponse.Success == false then
					-- // Revert the change
					dispatch(InventorySlice.actions.SetItem({
						item = props.item,
					}))
				end
			end)
			:catch(function()
				-- // Revert the change
				dispatch(InventorySlice.actions.SetItem({
					item = props.item,
				}))
			end)
	end, { props.item })

	local itemInfo = ItemUtils.GetItemInfoFromId(props.item.Id)
	local rarityColor = itemInfo and itemInfo.Rarity and Rarities[itemInfo.Rarity].Color or Color3.fromRGB(255, 255, 255)

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		LayoutOrder = props.layoutOrder,
	}, {
		itemImage = e("ImageButton", {
			Image = props.icon,
			ScaleType = Enum.ScaleType.Fit,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.1, 0.0435),
			Size = UDim2.fromOffset(91, 91),
			[React.Event.Activated] = function()
				if props.isEquipped then
					onUnequipItemPressed()
				else
					onEquipItemPressed()
				end
			end,
		}),

		uIGradient = e("UIGradient", {
			Color = ColorSequence.new(rarityColor, rarityColor),
			Rotation = -90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.814),
				NumberSequenceKeypoint.new(0.702, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),

		uIStroke = props.isEquipped == false and e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 2,
			Transparency = 0.7,
		}, {
			uIGradient1 = e("UIGradient", {
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

		equippedStroke = props.isEquipped == true and e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
			Transparency = 0.7,
		}, {
			uIGradient = e("UIGradient", {
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.498, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),

		name = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextTransparency = 0.3,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.1, 0.818),
			Size = UDim2.fromOffset(91, 20),
		}),

		uICorner = e("UICorner"),

		favorite = e("ImageButton", {
			Image = props.item.Favorited == true and "rbxassetid://16155966501" or "rbxassetid://16155911787",
			ImageTransparency = 0.2,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0, 0.0385),
			Size = UDim2.fromOffset(22, 22),
			[React.Event.Activated] = onFavoritePressed,
		}),
	})
end

return React.memo(BaseItem)
