--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local InterfaceController = require("@controllers/InterfaceController")
local ItemUtils = require("@utilities/ItemUtils")
local Promise = require("@packages/Promise")
local React = require("@packages/React")
local TradeContext = require("@ui/contexts/TradeContext")
local Types = require("@constants/Types")
local UIStroke = require("@ui/components/other/UIStroke")
local UUIDSerde = require("@utilities/UUIDSerde")

local useCallback = React.useCallback
local useContext = React.useContext
local useState = React.useState
local e = React.createElement

local REMOVE_IMAGE_ID = "rbxassetid://18404389457"

type TradeItemTemplateProps = {
	canAddItem: boolean, -- is this element allowed to add items (if false, it will be a placeholder/visual)
	layoutOrder: number,
	item: Types.Item?,
}

local function TradeItemTemplate(props: TradeItemTemplateProps)
	local itemInfo: Types.ItemInfo? = props.item and ItemUtils.GetItemInfoFromId(props.item.Id)

	local tradeState = useContext(TradeContext)
	local removeHovered, setRemoveHovered = useState(false)

	local removeItemFromTrade = useCallback(function()
		if not props.item or not tradeState.currentTrade then
			return
		end
		local serializedItemUUID = UUIDSerde.Serialize(props.item.UUID)
		local serializedTradeUUID = UUIDSerde.Serialize(tradeState.currentTrade.UUID)

		InterfaceController.InterfaceChanged:Fire("ActiveTrade")

		Promise.new(function(resolve, reject)
			local ok, result =
				pcall(BlinkClient.TradingRemoveItem.Invoke, { tradeUuid = serializedTradeUUID, itemUuid = serializedItemUUID })
			if ok then resolve(result) else reject(result) end
		end)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					warn(response.Message)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, { props.item, tradeState } :: { any })

	local openTradeInventory = useCallback(function()
		InterfaceController.InterfaceChanged:Fire("Inventory")
	end, { tradeState } :: { any })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromOffset(100, 100),
	}, {
		addIcon = props.canAddItem and props.item == nil and e("ImageLabel", {
			Image = "rbxassetid://18349367356",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(44, 44),
			Size = UDim2.fromOffset(37, 37),
		}),

		addButton = props.canAddItem and props.item == nil and e("ImageButton", {
			Image = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			[React.Event.Activated] = function()
				openTradeInventory()
			end,
		}),

		removeButton = props.canAddItem and props.item and e("ImageButton", {
			Image = "",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			[React.Event.MouseEnter] = function()
				setRemoveHovered(true)
			end,
			[React.Event.MouseLeave] = function()
				setRemoveHovered(false)
			end,
			[React.Event.Activated] = function()
				removeItemFromTrade()
			end,
		}),

		itemImage = itemInfo and e("ImageLabel", {
			Image = removeHovered and REMOVE_IMAGE_ID or string.format("rbxassetid://%d", itemInfo.Image),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = removeHovered and UDim2.fromScale(0.6, 0.6) or UDim2.fromScale(0.9, 0.9),
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e(UIStroke, {
			color = Color3.fromRGB(255, 255, 255),
			thickness = 1,
		}),
	})
end

return React.memo(TradeItemTemplate)
