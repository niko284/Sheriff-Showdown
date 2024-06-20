--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Components = ReplicatedStorage.react.components
local Utils = ReplicatedStorage.utils
local Constants = ReplicatedStorage.constants
local PlayerScripts = LocalPlayer.PlayerScripts
local Serde = ReplicatedStorage.network.serde

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local Button = require(Components.buttons.Button)
local InventoryContext = require(ReplicatedStorage.react.contexts.InventoryContext)
local InventoryController = require(PlayerScripts.controllers.InventoryController)
local InventoryUtils = require(Utils.InventoryUtils)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Net = require(ReplicatedStorage.packages.Net)
local Rarities = require(ReplicatedStorage.constants.Rarities)
local React = require(ReplicatedStorage.packages.React)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Types = require(ReplicatedStorage.constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local InventoryNamespace = Remotes.Client:GetNamespace("Inventory")
local LockItem = InventoryNamespace:Get("LockItem") :: Net.ClientAsyncCaller
local UnlockItem = InventoryNamespace:Get("UnlockItem") :: Net.ClientAsyncCaller
local EquipItem = InventoryNamespace:Get("EquipItem") :: Net.ClientAsyncCaller
local UnequipItem = InventoryNamespace:Get("UnequipItem") :: Net.ClientAsyncCaller
local ToggleItemFavorite = InventoryNamespace:Get("ToggleItemFavorite") :: Net.ClientAsyncCaller

local e = React.createElement
local useCallback = React.useCallback
local useContext = React.useContext

type ItemDisplayProps = Types.FrameProps & {
	itemName: string,
	itemId: number,
	itemUUID: string,
	isFavorited: boolean,
	isLocked: boolean,
	serial: number?,
	rarity: Types.ItemRarity,
	image: string,
	killCount: number?,
}

local function ItemDisplay(props: ItemDisplayProps)
	local rarityInfo = Rarities[props.rarity]

	local itemInfo = ItemUtils.GetItemInfoFromId(props.itemId)
	local itemTypeInfo = ItemTypes[itemInfo.Type]

	local inventory: Types.PlayerInventory? = useContext(InventoryContext)

	local isEquipped = inventory and InventoryUtils.IsEquipped(inventory, props.itemUUID)

	local equipItem = useCallback(function()
		local oldInventory = inventory :: Types.PlayerInventory
		local newInventory = InventoryUtils.EquipItem(oldInventory, props.itemUUID)

		InventoryController.InventoryChanged:Fire(newInventory)

		-- rollback if the server fails to complete this request
		local serializedUUID = UUIDSerde.Serialize(props.itemUUID)
		EquipItem:CallServerAsync(serializedUUID)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					InventoryController.InventoryChanged:Fire(oldInventory)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
				InventoryController.InventoryChanged:Fire(oldInventory)
			end)
	end, { inventory, props.itemUUID } :: { any })

	local unequipItem = useCallback(function()
		local oldInventory = inventory :: Types.PlayerInventory
		local newInventory = InventoryUtils.UnequipItem(oldInventory, props.itemUUID)

		InventoryController.InventoryChanged:Fire(newInventory)

		-- rollback if the server fails to complete this request
		local serializedUUID = UUIDSerde.Serialize(props.itemUUID)
		UnequipItem:CallServerAsync(serializedUUID)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					InventoryController.InventoryChanged:Fire(oldInventory)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
				InventoryController.InventoryChanged:Fire(oldInventory)
			end)
	end, { inventory, props.itemUUID } :: { any })

	local lockItem = useCallback(function()
		local oldInventory = inventory :: Types.PlayerInventory
		local newInventory = InventoryUtils.LockItem(oldInventory, props.itemUUID, true)

		InventoryController.InventoryChanged:Fire(newInventory)

		-- rollback if the server fails to complete this request
		local serializedUUID = UUIDSerde.Serialize(props.itemUUID)
		LockItem:CallServerAsync(serializedUUID)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					InventoryController.InventoryChanged:Fire(oldInventory)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
				InventoryController.InventoryChanged:Fire(oldInventory)
			end)
	end, { inventory, props.itemUUID } :: { any })

	local unlockItem = useCallback(function()
		local oldInventory = inventory :: Types.PlayerInventory
		local newInventory = InventoryUtils.LockItem(oldInventory, props.itemUUID, false)

		InventoryController.InventoryChanged:Fire(newInventory)

		-- rollback if the server fails to complete this request
		local serializedUUID = UUIDSerde.Serialize(props.itemUUID)
		UnlockItem:CallServerAsync(serializedUUID)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					InventoryController.InventoryChanged:Fire(oldInventory)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
				InventoryController.InventoryChanged:Fire(oldInventory)
			end)
	end, { inventory, props.itemUUID } :: { any })

	local toggleItemFavorite = useCallback(function(favorite: boolean)
		local oldInventory = inventory :: Types.PlayerInventory
		local newInventory = InventoryUtils.ToggleItemFavorite(oldInventory, props.itemUUID, favorite)

		InventoryController.InventoryChanged:Fire(newInventory)

		-- rollback if the server fails to complete this request
		local serializedUUID = UUIDSerde.Serialize(props.itemUUID)
		ToggleItemFavorite:CallServerAsync(serializedUUID, favorite)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					InventoryController.InventoryChanged:Fire(oldInventory)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
				InventoryController.InventoryChanged:Fire(oldInventory)
			end)
	end, { inventory, props.itemUUID } :: { any })

	return e("ImageLabel", {
		Image = "rbxassetid://17886556400",
		BackgroundTransparency = 1,
		Position = props.position,
		Size = props.size,
	}, {
		weaponName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.itemName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(25, 30),
			Size = UDim2.fromOffset(124, 15),
		}),

		rarity = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.rarity,
			TextColor3 = rarityInfo.Color,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(26, 54),
			Size = UDim2.fromOffset(35, 11),
		}),

		itemSerial = props.serial and e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(200, 25),
			Size = UDim2.fromOffset(70, 30),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			serial = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "#" .. props.serial,
				TextColor3 = Color3.fromRGB(72, 72, 72),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 11),
				Size = UDim2.fromOffset(42, 9),
			}),
		}),

		itemImage = e("ImageLabel", {
			Image = props.image,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(60, 51),
			Size = UDim2.fromOffset(178, 178),
		}),

		killText = props.killCount and e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(70, 53),
			Size = UDim2.fromOffset(65, 12),
		}, {
			kills = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.SemiBold,
					Enum.FontStyle.Normal
				),
				Text = props.killCount,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(17, 1),
				Size = UDim2.fromOffset(48, 11),
			}),

			deathIcon = e("ImageLabel", {
				Image = "rbxassetid://17886556724",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(13, 12),
			}),
		}),

		options = e("ImageLabel", {
			Image = "rbxassetid://17886569101",
			BackgroundTransparency = 1,
			Visible = false,
			Position = UDim2.fromOffset(23, 80),
			Size = UDim2.fromOffset(56, 26),
		}, {
			lock = e("ImageLabel", {
				Image = "rbxassetid://17886569169",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(8, 6),
				Size = UDim2.fromOffset(12, 14),
			}),

			favorite = e("ImageLabel", {
				Image = "rbxassetid://17886569282",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(35, 5),
				Size = UDim2.fromOffset(16, 16),
			}),

			seperator = e("ImageLabel", {
				Image = "rbxassetid://17886569505",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(26, 6),
				Size = UDim2.fromOffset(4, 13),
			}),
		}),

		buttonList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 6,
			active = true,
			backgroundTransparency = 1,
			anchorPoint = Vector2.new(0, 0),
			borderSizePixel = 0,
			position = UDim2.fromScale(0.0307, 0.674),
			size = UDim2.fromOffset(280, 107),
		}, {
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(6, 10),
				CellSize = UDim2.fromOffset(131, 42),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 3),
				PaddingRight = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 3),
			}),

			equip = itemTypeInfo.CanEquip and e(Button, {
				fontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				text = isEquipped and "Unequip" or "Equip",
				textColor3 = not isEquipped and Color3.fromRGB(0, 54, 25) or Color3.fromRGB(53, 0, 12),
				anchorPoint = Vector2.new(0.5, 0.5),
				textSize = 16,
				strokeThickness = 1.5,
				layoutOrder = 1,
				applyStrokeMode = Enum.ApplyStrokeMode.Border,
				strokeColor = Color3.fromRGB(255, 255, 255),
				cornerRadius = UDim.new(0, 5),
				gradient = not isEquipped and ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
				}) or ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 68, 118)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(203, 35, 67)),
				}),
				gradientRotation = -90,
				onActivated = not isEquipped and equipItem or unequipItem,
			}),

			lock = e(Button, {
				anchorPoint = Vector2.new(0.5, 0.5),
				fontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				text = props.isLocked and "Unlock" or "Lock",
				textColor3 = Color3.fromRGB(0, 0, 0),
				textSize = 16,
				strokeThickness = 1.5,
				layoutOrder = 2,
				applyStrokeMode = Enum.ApplyStrokeMode.Border,
				strokeColor = Color3.fromRGB(255, 255, 255),
				cornerRadius = UDim.new(0, 5),
				gradient = props.isLocked and ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 114, 114)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 74, 74)),
				}) or ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 198, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(244, 157, 5)),
				}),
				gradientRotation = -90,
				onActivated = props.isLocked and unlockItem or lockItem,
			}),

			favorite = e(Button, {
				anchorPoint = Vector2.new(0.5, 0.5),
				fontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				text = props.isFavorited and "Unfavorite" or "Favorite",
				textColor3 = Color3.fromRGB(0, 0, 0),
				textSize = 16,
				strokeThickness = 1.5,
				layoutOrder = 3,
				applyStrokeMode = Enum.ApplyStrokeMode.Border,
				strokeColor = Color3.fromRGB(255, 255, 255),
				cornerRadius = UDim.new(0, 5),
				gradient = props.isFavorited and ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 114, 114)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 74, 74)),
				}) or ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 85, 150)),
				}),
				gradientRotation = -90,
				onActivated = function()
					toggleItemFavorite(not props.isFavorited)
				end,
			}),

			--[[sell = itemTypeInfo.CanSell and e(Button, {
				backgroundTransparency = 1,
				anchorPoint = Vector2.new(0.5, 0.5),
				text = "Sell",
				layoutOrder = 4,
				textColor3 = Color3.fromRGB(255, 255, 255),
				textSize = 16,
				strokeThickness = 1.5,
				applyStrokeMode = Enum.ApplyStrokeMode.Border,
				strokeColor = Color3.fromRGB(255, 255, 255),
				cornerRadius = UDim.new(0, 5),
				fontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
			}),--]]
		}),
	})
end

return ItemDisplay
