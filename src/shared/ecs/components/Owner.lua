-- Item

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Owner = Matter.component("Owner", {
	OwnedBy = nil :: Player?,
})

return Owner
