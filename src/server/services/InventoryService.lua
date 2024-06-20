--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants

local Freeze = require(ReplicatedStorage.packages.Freeze)
local InventoryUtils = require(ReplicatedStorage.utils.InventoryUtils)
local ItemService = require(Services.ItemService)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Items = require(Constants.Items)
local Lapis = require(ServerScriptService.ServerPackages.Lapis)
local Net = require(ReplicatedStorage.packages.Net)
local PlayerDataService = require(Services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ServerComm = require(ServerScriptService.ServerComm)
local Types = require(ReplicatedStorage.constants.Types)

local InventoryNamespace = Remotes.Server:GetNamespace("Inventory")
local ItemAdded = InventoryNamespace:Get("ItemAdded") :: Net.ServerSenderEvent
local EquipItem = InventoryNamespace:Get("EquipItem") :: Net.ServerAsyncCallback
local UnequipItem = InventoryNamespace:Get("UnequipItem") :: Net.ServerAsyncCallback
local LockItem = InventoryNamespace:Get("LockItem") :: Net.ServerAsyncCallback
local UnlockItem = InventoryNamespace:Get("UnlockItem") :: Net.ServerAsyncCallback
local ToggleItemFavorite = InventoryNamespace:Get("ToggleItemFavorite") :: Net.ServerAsyncCallback

local PlayerInventoryProperty = ServerComm:CreateProperty("PlayerInventory", nil)

local InventoryService = {}

function InventoryService:OnInit()
	PlayerDataService.DocumentLoaded:Connect(function(Player, Document)
		InventoryService:GrantDefaults(Player, Document)

		local data = Document:read()

		if data.Inventory then
			print("Setting for")
			PlayerInventoryProperty:SetFor(Player, data.Inventory)
		end
	end)

	EquipItem:SetCallback(function(Player: Player, ItemUUID: string)
		return InventoryService:EquipItemNetworkRequest(Player, ItemUUID)
	end)

	UnequipItem:SetCallback(function(Player: Player, ItemUUID: string)
		return InventoryService:UnequipItemNetworkRequest(Player, ItemUUID)
	end)

	LockItem:SetCallback(function(Player: Player, ItemUUID: string)
		return InventoryService:LockItemNetworkRequest(Player, ItemUUID)
	end)

	UnlockItem:SetCallback(function(Player: Player, ItemUUID: string)
		return InventoryService:UnlockItemNetworkRequest(Player, ItemUUID)
	end)

	ToggleItemFavorite:SetCallback(function(Player: Player, ItemUUID: string, Favorite: boolean)
		return InventoryService:ToggleItemFavoriteNetworkRequest(Player, ItemUUID, Favorite)
	end)
end

function InventoryService:GrantDefaults(Player: Player, Document: Lapis.Document<Types.DataSchema>): ()
	local data = Document:read()
	local grantedDefaults = table.clone(data.Inventory.GrantedDefaults)

	local wasGrantedAtLeastOne = false
	for _, ItemInfo in Items do
		if not table.find(grantedDefaults, ItemInfo.Id) then
			local isDefault = if typeof(ItemInfo.Default) == "function"
				then ItemInfo.Default(Player)
				else ItemInfo.Default
			if isDefault == false then
				continue
			end
			ItemService:GenerateItem(ItemInfo.Id)
				:andThen(function(Item: Types.Item)
					wasGrantedAtLeastOne = true
					table.insert(grantedDefaults, ItemInfo.Id)
					InventoryService:AddItem(Player, Item)
				end)
				:catch(function() end)
				:awaitStatus()
		end
	end

	if wasGrantedAtLeastOne then -- if we granted at least one item, update the document with the new granted defaults
		local newData = table.clone(Document:read())
		Document:write(Freeze.Dictionary.setIn(newData, { "Inventory", "GrantedDefaults" }, grantedDefaults))
	end
end

function InventoryService:AddItem(Player: Player, Item: Types.Item, sendNetworkEvent: boolean?): ()
	local Document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(Document:read())
	local newStorage = table.clone(newData.Inventory.Storage)
	table.insert(newStorage, Item)
	Document:write(Freeze.Dictionary.setIn(newData, { "Inventory", "Storage" }, newStorage))

	if sendNetworkEvent ~= false then
		ItemAdded:SendToPlayer(Player, Item)
	end
end

function InventoryService:EquipItem(Player: Player, ItemUUID: string): ()
	local Document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(Document:read())

	local newInventory = InventoryUtils.EquipItem(newData.Inventory, ItemUUID)
	newData.Inventory = newInventory

	Document:write(newData)
end

function InventoryService:UnequipItem(Player: Player, ItemUUID: string)
	local Document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(Document:read())

	local newInventory = InventoryUtils.UnequipItem(newData.Inventory, ItemUUID)
	newData.Inventory = newInventory

	Document:write(newData)
end

function InventoryService:LockItem(Player: Player, ItemUUID: string): ()
	local Document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(Document:read())

	local newInventory = InventoryUtils.LockItem(newData.Inventory, ItemUUID, true)
	newData.Inventory = newInventory

	Document:write(newData)
end

function InventoryService:UnlockItem(Player: Player, ItemUUID: string): ()
	local Document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(Document:read())

	local newInventory = InventoryUtils.LockItem(newData.Inventory, ItemUUID, false)
	newData.Inventory = newInventory

	Document:write(newData)
end

function InventoryService:ToggleItemFavorite(Player: Player, ItemUUID: string, Favorite: boolean): ()
	local Document = PlayerDataService:GetDocument(Player)
	local newData = table.clone(Document:read())

	local newInventory = InventoryUtils.ToggleItemFavorite(newData.Inventory, ItemUUID, Favorite)
	newData.Inventory = newInventory

	Document:write(newData)
end

function InventoryService:GetItemOfUUID(Player: Player, ItemUUID: string): Types.Item?
	local Document = PlayerDataService:GetDocument(Player)
	if not Document then
		return nil
	end

	local data = Document:read()
	for _, Item in data.Inventory.Storage do
		if Item.UUID == ItemUUID then
			return Item
		end
	end

	for _, Item in data.Inventory.Equipped do
		if Item.UUID == ItemUUID then
			return Item
		end
	end

	return nil
end

function InventoryService:GetItemsOfType(Player: Player, ItemType: Types.ItemType, Equipped: boolean?): { Types.Item }
	local Document = PlayerDataService:GetDocument(Player)
	local data = Document:read()
	local items = if Equipped == true then data.Inventory.Equipped else data.Inventory.Storage

	local filteredItems = {}
	for _, Item in ipairs(items) do
		local ItemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
		if ItemInfo.Type == ItemType then
			table.insert(filteredItems, Item)
		end
	end

	return filteredItems
end

function InventoryService:EquipItemNetworkRequest(Player: Player, ItemUUID: string): Types.NetworkResponse
	local Document = PlayerDataService:GetDocument(Player)
	if not Document then
		return { Success = false, Error = "Document not found" }
	end

	local Item = InventoryService:GetItemOfUUID(Player, ItemUUID)
	if not Item then
		return { Success = false, Error = "Item not found" }
	end

	local ItemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
	local ItemTypeInfo = ItemTypes[ItemInfo.Type]

	if ItemTypeInfo.CanEquip == false then
		return { Success = false, Error = "Item cannot be equipped" }
	end

	InventoryService:EquipItem(Player, ItemUUID)

	return { Success = true }
end

function InventoryService:UnequipItemNetworkRequest(Player: Player, ItemUUID: string): Types.NetworkResponse
	local Document = PlayerDataService:GetDocument(Player)
	if not Document then
		return { Success = false, Error = "Document not found" }
	end

	local Item = InventoryService:GetItemOfUUID(Player, ItemUUID)
	if not Item then
		return { Success = false, Error = "Item not found" }
	end

	local ItemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
	local ItemTypeInfo = ItemTypes[ItemInfo.Type]

	if ItemTypeInfo.CanEquip == false then
		return { Success = false, Error = "Item cannot be unequipped" }
	end

	InventoryService:UnequipItem(Player, ItemUUID)

	return { Success = true }
end

function InventoryService:LockItemNetworkRequest(Player: Player, ItemUUID: string): Types.NetworkResponse
	local Document = PlayerDataService:GetDocument(Player)
	if not Document then
		return { Success = false, Error = "Document not found" }
	end

	local Item = InventoryService:GetItemOfUUID(Player, ItemUUID)
	if not Item then
		return { Success = false, Error = "Item not found" }
	end

	InventoryService:LockItem(Player, ItemUUID)

	return { Success = true }
end

function InventoryService:UnlockItemNetworkRequest(Player: Player, ItemUUID: string): Types.NetworkResponse
	local Document = PlayerDataService:GetDocument(Player)
	if not Document then
		return { Success = false, Error = "Document not found" }
	end

	local Item = InventoryService:GetItemOfUUID(Player, ItemUUID)
	if not Item then
		return { Success = false, Error = "Item not found" }
	end

	InventoryService:UnlockItem(Player, ItemUUID)

	return { Success = true }
end

function InventoryService:ToggleItemFavoriteNetworkRequest(
	Player: Player,
	ItemUUID: string,
	Favorite: boolean
): Types.NetworkResponse
	local Document = PlayerDataService:GetDocument(Player)
	if not Document then
		return { Success = false, Error = "Document not found" }
	end

	local Item = InventoryService:GetItemOfUUID(Player, ItemUUID)
	if not Item then
		return { Success = false, Error = "Item not found" }
	end

	InventoryService:ToggleItemFavorite(Player, ItemUUID, Favorite)

	return { Success = true }
end

return InventoryService
