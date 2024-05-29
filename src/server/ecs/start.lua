local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Items = require(ReplicatedStorage.constants.Items)
local Matter = require(ReplicatedStorage.packages.Matter)

local function start(systemsContainers: { Instance }, services)
	local world = Matter.World.new()

	local loop = Matter.Loop.new(world, {
		services = services,
	})

	local systems = {}
	for _, systemContainer in ipairs(systemsContainers) do
		for _, system in systemContainer:GetChildren() do
			table.insert(systems, require(system))
		end
	end
	for _, service in services do
		service.World = world -- inject the world into the service for easy access
	end

	loop:scheduleSystems(systems)

	loop:begin({
		default = RunService.Heartbeat,
	})

	for _, target in CollectionService:GetTagged("Target") do
		world:spawn(
			Components.Target(),
			Components.Renderable({
				instance = target,
			}),
			Components.Health({
				health = 100,
				maxHealth = 100,
				regenRate = 0,
			})
		)
	end
end

return start
