--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.constants.Rarities)
local Types = require(ReplicatedStorage.constants.Types)

local RarityUtils = {}

function RarityUtils.GetRarityProbability(rarity: Types.ItemRarity): number
	local totalWeight = 0
	for _, rarityInfo in pairs(Rarities) do
		totalWeight = totalWeight + rarityInfo.Weight
	end

	local rarityInfo = Rarities[rarity]

	return rarityInfo.Weight / totalWeight
end

return RarityUtils
