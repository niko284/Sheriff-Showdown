--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local ConfirmationPrompt = require("@ui/components/other/ConfirmationPrompt")
local Crates = require("@constants/Crates")
local FormatNumber = require("@utilities/FormatNumber")
local InventoryContext = require("@ui/contexts/InventoryContext")
local Promise = require("@packages/Promise")
local React = require("@packages/React")
local ResourceContext = require("@ui/contexts/ResourceContext")
local Types = require("@constants/Types")

local NumberFormatter = FormatNumber.NumberFormatter

local useCallback = React.useCallback
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useContext = React.useContext

local PriceFormatter = NumberFormatter.with():Precision(FormatNumber.Precision.integer())

type CratePurchasePromptProps = {
	crateName: Types.Crate,
	switchToCategory: (category: string) -> (),
	onCancel: () -> (),
}

local function CratePurchasePrompt(props: CratePurchasePromptProps)
	local wasPurchased, setWasPurchased = useState(false)

	local crateInfo = Crates[props.crateName]

	local resources = useContext(ResourceContext)
	local inventory = useContext(InventoryContext)

	local onCrateConfirm = useCallback(function()
		local purchaseMethod = crateInfo.PurchaseMethods[1]
		if purchaseMethod.Price then
			if resources[purchaseMethod.Type] >= purchaseMethod.Price then
				-- purchase the crate
				props.onCancel()
				Promise.new(function(resolve, reject)
					local ok, result =
						pcall(BlinkClient.ShopPurchaseCrate.Invoke, { crateType = props.crateName, quantity = 1 })
					if ok then resolve(result) else reject(result) end
				end)
					:andThen(function(response: Types.NetworkResponse)
						if response.Success == false then
							warn(response.Message)
						else
							setWasPurchased(true)
						end
					end)
					:catch(function(err)
						warn(tostring(err))
					end)
			else
				-- go to the currency shop
				props.switchToCategory("Currency")
			end
		end
	end, { resources, inventory, props.onCancel } :: { any })

	local description = nil
	local acceptText = nil
	local purchaseMethod = crateInfo.PurchaseMethods[1] -- just support one purchase method for now

	if purchaseMethod.Price then
		local hasEnough = resources[purchaseMethod.Type] >= purchaseMethod.Price
		if hasEnough then
			description = string.format(
				'Purchase the %s crate for <font color="rgb(255,125,0)">%s %s</font>?',
				props.crateName,
				PriceFormatter:Format(purchaseMethod.Price),
				purchaseMethod.Type
			)
			acceptText = "Purchase"
		else
			description = string.format(
				"You need %s %s more to purchase the %s crate!",
				PriceFormatter:Format(purchaseMethod.Price - resources[purchaseMethod.Type]),
				purchaseMethod.Type,
				props.crateName
			)
			acceptText = "Buy More"
		end
	end

	useEffect(function()
		if wasPurchased == true then
			task.delay(1, function()
				setWasPurchased(false)
			end)
		end
		return function() end
	end, { wasPurchased })

	return e(ConfirmationPrompt, {
		title = "Purchase Crate",
		description = description,
		acceptText = wasPurchased and "Purchased!" or acceptText,
		onAccept = wasPurchased and function() end or onCrateConfirm,
		onCancel = props.onCancel,
	})
end

return CratePurchasePrompt
