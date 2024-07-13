--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Freeze = require(ReplicatedStorage.packages.Freeze)

return {
	-- granted defaults are now stored in player's inventory
	function(old)
		return Freeze.Dictionary.setIn(old, { "Inventory", "GrantedDefaults" }, {})
	end,
	function(old)
		return Freeze.Dictionary.set(old, "CodesRedeemed", {})
	end,
	function(old)
		return Freeze.Dictionary.set(old, "Settings", {})
	end,
	function(old)
		return Freeze.Dictionary.set(old, "ProcessingTrades", {})
	end,
}
