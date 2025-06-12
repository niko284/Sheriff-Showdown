--!strict

local React = require("@packages/React")
local Types = require("@constants/Types")

return React.createContext({
	currentTrade = nil :: Types.Trade?,
	showTradeSideButton = false :: boolean, -- should the trade side button be shown?
})
