local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Matter = require(Packages.Matter)

local Identifier = Matter.component("Identifier", {
	uuid = nil :: string?,
})

return Identifier
