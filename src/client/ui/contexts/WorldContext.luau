--!strict

local jecs = require("@packages/jecs")
local React = require("@packages/React")

return React.createContext({
	world = nil :: jecs.World?,
})
