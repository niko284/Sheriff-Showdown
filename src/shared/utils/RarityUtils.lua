--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rarities = require(ReplicatedStorage.constants.Rarities)
local Types = require(ReplicatedStorage.constants.Types)

local RarityUtils = {}

function RarityUtils.GetRarityProbability(rarity: Types.ItemRarity, weightMap: { [Types.ItemRarity]: number }): number
	local totalWeight = 0
	for _, weight in pairs(weightMap) do
		totalWeight = totalWeight + weight
	end

	return weightMap[rarity] / totalWeight
end

function RarityUtils.SelectRandomRarity(weightMap: { [Types.ItemRarity]: number }): Types.ItemRarity
	local totalWeight = 0
	for _, weight in pairs(weightMap) do
		totalWeight = totalWeight + weight
	end

	local randomValue = math.random() * totalWeight
	for rarity, weight in pairs(weightMap) do
		randomValue = randomValue - weight
		if randomValue <= 0 then
			return rarity :: Types.ItemRarity
		end
	end

	return "Basic"
end

return RarityUtils
