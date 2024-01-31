-- Client Entity Component
-- September 9th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Component = require(Packages.Component)
local Janitor = require(Packages.Janitor)

-- // Entity \\

local EntityComponent = Component.new({
	Tag = "Entity",
	Ancestors = { workspace },
	Extensions = {},
})

-- // Functions \\

function EntityComponent:Construct()
	self.Janitor = Janitor.new()
end

function EntityComponent:Stop()
	self.Janitor:Destroy()
end

return EntityComponent
