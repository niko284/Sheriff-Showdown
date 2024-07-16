--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

return React.createContext({
	LastDailyRotation = -1,
	ActiveAchievements = {} :: { Types.Achievement },
})
