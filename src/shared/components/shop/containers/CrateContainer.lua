-- Crate Container
-- February 24th, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components
local CrateComponents = Components.shop.crates

local CrateTemplate = require(CrateComponents.CrateTemplate)
local Crates = require(Constants.Crates)
local React = require(Packages.React)
local Types = require(Constants.Types)

local e = React.createElement

-- // Crate Container \\

type CrateContainerProps = {
	setViewInfo: (Types.ShopViewInfo) -> (),
}
local function CrateContainer(props: CrateContainerProps)
	local crateElements = {}
	for crateName, crate in Crates do
		crateElements[crateName] = e(CrateTemplate, {
			name = crateName,
			image = crate.ShopImage,
			size = UDim2.fromOffset(100, 100),
			layoutOrder = crate.ShopLayoutOrder,
			purchaseInfo = crate.PurchaseInfo,
			onActivated = function()
				props.setViewInfo({
					Name = crateName,
					Image = crate.ShopImage,
					Type = "Crate",
				})
			end,
		})
	end

	return e(React.Fragment, nil, crateElements)
end

return React.memo(CrateContainer)
