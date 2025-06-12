--!strict

local React = require("@packages/React")
local Types = require("@constants/Types")

return React.createContext({
	current = nil :: Types.Interface?,
	hideHUD = false,
})
