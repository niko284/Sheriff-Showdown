--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Crates = require(ReplicatedStorage.constants.Crates)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Types = require(ReplicatedStorage.constants.Types)

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
