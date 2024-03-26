--!strict

-- Use Product Info
-- August 31st, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils
local Hooks = ReplicatedStorage.hooks

local DependencyArray = require(Utils.DependencyArray)
local React = require(Packages.React)
local useProductInfoFromIds = require(Hooks.useProductInfoFromIds)

local useMemo = React.useMemo

-- // Hook \\

local function useProductInfoFromId(productId: number?, infoType: EnumItem)
	local product = useMemo(function()
		return productId and { [productId] = infoType }
	end, DependencyArray(productId, infoType))
	local productInfo = useProductInfoFromIds(product or {} :: any)
	return productId and productInfo[productId] or nil
end

return useProductInfoFromId
