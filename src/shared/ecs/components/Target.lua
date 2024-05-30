local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Matter = require(Packages.Matter)

local Target = Matter.component("Target", {
	CanTarget = false,
})

return Target
