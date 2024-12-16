-- Item

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Item = Matter.component("Item", {
	Id = nil,
})

return Item
