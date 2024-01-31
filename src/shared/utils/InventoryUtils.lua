-- Inventory Utils
-- November 5th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Types = require(Constants.Types)

-- // Utils \\

local InventoryUtils = {}

function InventoryUtils.GetTakenInventorySpace(Inventory: Types.Inventory): number
	local takenSpace = 0
	for _, Item in Inventory.Items do
		local itemInfo = ItemUtils.GetItemInfoFromId(Item.Id)
		if itemInfo then
			local itemTypeInfo = ItemTypes[itemInfo.Type]
			if itemTypeInfo and itemTypeInfo.TakesInventorySlot == true then
				takenSpace += 1
			end
		end
	end
	return takenSpace
end

return InventoryUtils
