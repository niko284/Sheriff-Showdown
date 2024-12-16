local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Items = require(ReplicatedStorage.constants.Items)
local Matter = require(ReplicatedStorage.packages.Matter)
local Plasma = require(ReplicatedStorage.packages.Plasma)

local function start(systemsContainers: { Instance }, services)
	local world = Matter.World.new()

	local debugger = Matter.Debugger.new(Plasma) -- Pass Plasma into the debugger!
	local widgets = debugger:getWidgets()

	local loop = Matter.Loop.new(world, {
		services = services,
	}, widgets)
	local playerToEntityIdMap = {} -- map player to entity id

	debugger:autoInitialize(loop)

	debugger.authorize = function(player)
		if player:GetRankInGroup(33234854) >= 254 then -- example
			return true
		end
		return false
	end

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
		stepped = RunService.Stepped,
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

	local function onPlayerAdded(player: Player)
		local char = player.Character or player.CharacterAdded:Wait()
		local eid = world:spawn(
			Components.Player({ player = player }), -- also indicate that this target is a player
			Components.Renderable({
				instance = char,
			}),
			Components.Health({
				health = 100,
				maxHealth = 100,
				regenRate = 0,
			}),
			Components.Children({
				children = {},
			}) -- list of entity ids that are owned by this entity
		)
		playerToEntityIdMap[player] = eid

		player:SetAttribute("serverEntityId", eid)

		player.CharacterAdded:Connect(function(character)
			world:replace(
				eid,
				Components.Player({ player = player }), -- also indicate that this target is a player
				Components.Renderable({
					instance = character,
				}),
				Components.Health({
					health = 100,
					maxHealth = 100,
					regenRate = 0,
				}),
				Components.Children({
					children = {},
				}) -- list of entity ids that are owned by this entity
			)
		end)
	end

	local function onPlayerRemoving(player: Player)
		if playerToEntityIdMap[player] then
			task.defer(function()
				world:despawn(playerToEntityIdMap[player])
				playerToEntityIdMap[player] = nil
			end)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	return world
end

return start
