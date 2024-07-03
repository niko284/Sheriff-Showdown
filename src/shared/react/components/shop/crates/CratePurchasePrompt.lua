--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Contexts = ReplicatedStorage.react.contexts
local Hooks = ReplicatedStorage.react.hooks

local ConfirmationPrompt = require(Components.other.ConfirmationPrompt)
local Crates = require(ReplicatedStorage.constants.Crates)
local InventoryContext = require(Contexts.InventoryContext)
local Net = require(ReplicatedStorage.packages.Net)
local React = require(ReplicatedStorage.packages.React)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ResourceContext = require(Contexts.ResourceContext)
local Types = require(ReplicatedStorage.constants.Types)
local useProductInfoFromId = require(Hooks.useProductInfoFromId)

local ShopNamespace = Remotes.Client:GetNamespace("Shop")
local PurchaseCrate = ShopNamespace:Get("PurchaseCrate") :: Net.ClientAsyncCaller

local useCallback = React.useCallback
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useContext = React.useContext

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
				PurchaseCrate:CallServerAsync(props.crateName, 1)
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
				'Purchase the %s crate for <font color="rgb(255,125,0)">%d %s</font>?',
				props.crateName,
				purchaseMethod.Price,
				purchaseMethod.Type
			)
			acceptText = "Purchase"
		else
			description = string.format(
				"You need %d %s more to purchase the %s crate!",
				purchaseMethod.Price - resources[purchaseMethod.Type],
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
