-- Equipment Service
-- February 17th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services
local Utils = ReplicatedStorage.utils

local EntityService = require(Services.EntityService)
local EquipmentHandler = require(script.EquipmentHandler)
local InventoryService = require(Services.InventoryService)
local ItemUtils = require(Utils.ItemUtils)
local Types = require(Constants.Types)

-- // Service \\

local EquipmentService = {
	Name = "EquipmentService",
}

function EquipmentService:Init()
	EntityService.PlayerEntityReady:Connect(function(Player: Player, Entity: Types.Entity)
		EquipmentService:CharacterAdded(Player, Entity)
	end)
	InventoryService.ItemEquipped:Connect(function(Player: Player, Item: Types.Item)
		local itemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
		if itemInfo.Type == "Gun" then
			EquipmentHandler.UnequipAllGuns(Player.Character :: Types.Entity)
			EquipmentHandler.EquipGun(Player.Character :: Types.Entity, itemInfo, "Waist")
		end
	end)
end

function EquipmentService:CharacterAdded(Player: Player, Entity: Types.Entity)
	local equippedGuns = InventoryService:GetItemsOfType(Player, "Gun", true)
	local primaryGun = equippedGuns[1]
	if primaryGun then
		-- show on waist
		EquipmentHandler.EquipGun(Entity, ItemUtils.GetItemInfoFromId(primaryGun.Id), "Waist")
	end
end

return EquipmentService
