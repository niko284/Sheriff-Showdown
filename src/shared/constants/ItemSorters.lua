--!strict
-- Sorters
-- August 29th, 2023
-- Nick

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Items = require(Constants.Items)
local Types = require(Constants.Types)

local function GetItemFromId(Id: number): Types.ItemInfo
	for _, Item in pairs(Items) do
		if Item.Id == Id then
			return Item
		end
	end
	return nil :: any
end

return {}
