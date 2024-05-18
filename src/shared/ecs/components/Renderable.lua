local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Renderable = Matter.component("Renderable", {
	model = nil,
})

return Renderable
