--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants

local Freeze = require(ReplicatedStorage.packages.Freeze)
local ItemService = require(Services.ItemService)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Items = require(Constants.Items)
local Lapis = require(ServerScriptService.ServerPackages.Lapis)
local Net = require(ReplicatedStorage.packages.Net)
local PlayerDataService = require(Services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Types = require(ReplicatedStorage.constants.Types)

local InventoryNamespace = Remotes.Server:GetNamespace("Inventory")
local UpdateInventory = InventoryNamespace:Get("UpdateInventory") :: Net.ServerSenderEvent
local ItemAdded = InventoryNamespace:Get("ItemAdded") :: Net.ServerSenderEvent
local EquipItem = InventoryNamespace:Get("EquipItem") :: Net.ServerAsyncCallback
local UnequipItem = InventoryNamespace:Get("UnequipItem") :: Net.ServerAsyncCallback

local InventoryService = {}

function InventoryService:OnInit()
	PlayerDataService.DocumentLoaded:Connect(function(Player, Document)
		InventoryService:GrantDefaults(Player, Document)

		local data = Document:read()

		if data.Inventory then
			UpdateInventory:SendToPlayer(Player, data.Inventory)
		end
	end)

	EquipItem:SetCallback(function(Player: Player, ItemUUID: string)
		return InventoryService:EquipItemNetworkRequest(Player, ItemUUID)
	end)

	UnequipItem:SetCallback(function(Player: Player, ItemUUID: string)
		return nil
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
	local newStorage = table.clone(newData.Inventory.Storage)
	local newEquipped = table.clone(newData.Inventory.Equipped)

	local indexToRemove = nil
	for index, item in ipairs(newStorage) do
		if item.UUID == ItemUUID then
			indexToRemove = index
			break
		end
	end

	if not indexToRemove then
		return -- Item not found
	end

	local Item = table.remove(newStorage, indexToRemove)
	table.insert(newEquipped, Item)

	newData.Inventory.Storage = newStorage
	newData.Inventory.Equipped = newEquipped

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
	return nil
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

return InventoryService
