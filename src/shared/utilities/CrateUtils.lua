--!strict

local Crates = require("@constants/Crates")
local ItemUtils = require("@utilities/ItemUtils")
local Types = require("@constants/Types")

local CrateUtils = {}

function CrateUtils.GetCrateContents(CrateName: Types.Crate): { Types.ItemInfo }
	local CrateContents = {}
	local Crate = Crates[CrateName]
	for _, itemName in Crate.ItemContents do
		local ItemInfo = ItemUtils.GetItemInfoFromName(itemName)
		if ItemInfo then
			table.insert(CrateContents, ItemInfo)
		end
	end
	return CrateContents
end

return CrateUtils
