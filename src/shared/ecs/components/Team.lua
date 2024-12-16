local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Team = Matter.component("Team", {
	name = "default",
})

return Team
