local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Guns = Assets:FindFirstChild("guns") :: Folder

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

local function gunsAreRendered(world: Matter.World)
	for _, gun, owner, item in
		world:query(Components.Gun, Components.Owner, Components.Item):without(Components.Renderable)
	do
	end
end

return gunsAreRendered
