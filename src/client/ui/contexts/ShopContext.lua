--!strict

local React = require("@packages/React")
local Types = require("@constants/Types")

return React.createContext({
	giftRecipient = nil :: Player?,
	crateToView = nil :: Types.Crate?,
	giftedGamepasses = nil :: { number }?,
})
