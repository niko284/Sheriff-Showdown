--!strict

-- Use Product Info
-- August 31st, 2022
-- Nick

-- // Variables \\

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils
local Constants = ReplicatedStorage.constants

local DependencyArray = require(Utils.DependencyArray)
local React = require(Packages.React)
local Types = require(Constants.Types)

local useState = React.useState
local useEffect = React.useEffect

-- // Hook \\

local function useProductInfoFromIds(productIds: { [number]: Enum.InfoType })
	local productInfo, setProductInfo = useState({} :: { [number]: Types.ProductInfo })
	useEffect(function()
		if productIds then
			for productId, infoType in pairs(productIds) do
				local success, result = pcall(function()
					return MarketplaceService:GetProductInfo(productId, infoType) :: Types.ProductInfo
				end)
				if success and result then
					setProductInfo(function(prevProductInfo: { [number]: Types.ProductInfo })
						prevProductInfo = table.clone(prevProductInfo)
						-- Explicitly type cast prevProductInfo. Otherwise, it will still treat it as possibly nil.
						prevProductInfo[productId] = result
						return prevProductInfo
					end)
				end
			end
		end
	end, DependencyArray(productIds))

	return productInfo
end

return useProductInfoFromIds
