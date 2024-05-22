local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

local useEvent = Matter.useEvent

type RenderableRecord = MatterTypes.WorldChangeRecord<Components.Renderable>

local function charactersAreTargets(world: Matter.World)
	for _, player in Players:GetPlayers() do
		for _, character in useEvent(player, "CharacterAdded") do
			world:spawn(
				Components.Target(),
				Components.Renderable({
					instance = character,
				}),
				Components.Health({
					health = 100,
					maxHealth = 100,
					regenRate = 0,
				})
			)
		end
	end
	for entityId, renderableRecord: RenderableRecord in world:queryChanged(Components.Renderable) do
		if renderableRecord.new == nil and renderableRecord.old ~= nil then
			local hasTarget = world:get(entityId, Components.Target)
			if hasTarget then
				print(`Despawning target entity: {entityId}`)
				world:despawn(entityId) -- despawn the target entity if the renderable is removed (like when a character dies)
			end
		end
	end
end

return charactersAreTargets