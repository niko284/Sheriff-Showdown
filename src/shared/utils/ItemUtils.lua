local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.constants.Items)

local ItemUtils = {}

function ItemUtils.GetItemInfoFromId(Id: number): Items.ItemInfo
	for _, itemInfo in ipairs(Items) do
		if itemInfo.Id == Id then
			return itemInfo
		end
	end
	return nil :: any
end

return ItemUtils
