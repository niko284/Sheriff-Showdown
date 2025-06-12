--!strict

local MarketplaceService = game:GetService("MarketplaceService")

local DependencyArray = require("@utilities/DependencyArray")
local React = require("@packages/React")
local Types = require("@constants/Types")

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
