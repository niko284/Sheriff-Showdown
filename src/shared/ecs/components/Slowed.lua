local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Matter = require(Packages.Matter)

local Slowed = Matter.component("Slowed", {
	walkspeedMultiplier = 1,
})

return Slowed
