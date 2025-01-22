local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Renderable = Matter.component("Renderable", {
	instance = nil,
})

return Renderable
