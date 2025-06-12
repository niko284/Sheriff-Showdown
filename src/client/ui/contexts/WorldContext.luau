--!strict

local Matter = require("@packages/Matter")
local React = require("@packages/React")

return React.createContext({
	world = nil :: Matter.World?,
})
