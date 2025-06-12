--!strict

local DependencyArray = require("@utilities/DependencyArray")
local React = require("@packages/React")
local useProductInfoFromIds = require("@ui/hooks/useProductInfoFromIds")

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
