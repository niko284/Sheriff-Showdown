--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local InterfaceController = require("@controllers/InterfaceController")
local PlayerSelectionList = require("@ui/components/frames/SelectionList/PlayerSelectionList")
local Promise = require("@packages/Promise")
local React = require("@packages/React")
local ShopContext = require("@ui/contexts/ShopContext")
local animateCurrentInterface = require("@ui/hooks/animateCurrentInterface")

local e = React.createElement
local useContext = React.useContext
local useCallback = React.useCallback

type GiftingSelectionListProps = {}

local function GiftingSelectionList(_props: GiftingSelectionListProps)
	local shouldRender, styles =
		animateCurrentInterface("GiftingSelection", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local shopState = useContext(ShopContext)

	local giftPlayer = useCallback(function(_rbx: TextButton, player: Player)
		Promise.new(function(resolve, reject)
			local ok, result = pcall(BlinkClient.ShopGetGiftedGamepasses.Invoke, player)
			if ok then resolve(result) else reject(result) end
		end)
			:andThen(function(giftedGamepasses: { number })
				local newShopState = table.clone(shopState)
				newShopState.giftRecipient = player
				newShopState.giftedGamepasses = giftedGamepasses
				InterfaceController.UpdateShopState:Fire(newShopState)
				InterfaceController.InterfaceChanged:Fire("Shop")

				BlinkClient.ShopSetGiftPlayer.Fire(player)
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, { shopState })

	local onClose = useCallback(function()
		InterfaceController.InterfaceChanged:Fire("Shop")
	end, {})

	return shouldRender
		and e(
			PlayerSelectionList,
			{
				position = styles.position,
				listTitle = "Gifting",
				selectionText = "Gift",
				subtitle = "Players",
				selectionDescription = "Select a player to gift to!",
				selectionActivated = giftPlayer,
				onClose = onClose,
			} :: any
		)
end

return React.memo(GiftingSelectionList)
