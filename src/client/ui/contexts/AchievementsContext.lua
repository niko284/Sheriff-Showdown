--!strict

local React = require("@packages/React")
local Types = require("@constants/Types")

return React.createContext({
	LastDailyRotation = -1,
	ActiveAchievements = {} :: { Types.Achievement },
})
