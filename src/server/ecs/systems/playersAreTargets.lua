local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)

local useEvent = Matter.useEvent

local function playersAreTargets(world: Matter.World)
	for _, player in Players:GetPlayers() do
		for _, character in useEvent(player, "CharacterAdded") do
			world:spawn(
				Components.Target(),
				Components.Renderable({
					instance = character,
				})
			)
		end
	end
	for entityId in world:query(Components.Target):without(Components.Renderable) do
		world:despawn(entityId) -- Despawn entities with a Target component but no Renderable component. (Players can die/leave the game.)
	end
end

return playersAreTargets
