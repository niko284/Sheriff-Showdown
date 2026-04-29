--!strict

local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local jabby = require("@packages/jabby")
local jecs = require("@packages/jecs")
local planck = require("@packages/planck")
local replecs = require("@packages/replecs")

local BlinkServer = require("@server/modules/BlinkServer")
local Components = require("@ecs/components")
local VoxelBuffer = require("@utilities/VoxelBuffer")
local VoxelManager = require("@server/ecs/VoxelManager")
local VoxelOriginalData = require("@ecs/VoxelOriginalData")
local registerObservers = require("@ecs/observers")
local registerServerObservers = require("@server/ecs/observers")

-- Shared systems
local cooldownsExpire = require("@ecs/systems/cooldownsExpire")
local lifetimesDespawn = require("@ecs/systems/lifetimesDespawn")
local projectilesTravel = require("@ecs/systems/projectilesTravel")
local updateTransforms = require("@ecs/systems/updateTransforms")

-- Server-only systems
local accessoriesCantQuery = require("@server/ecs/systems/accessoriesCantQuery")
local actionsAreConsumed = require("@server/ecs/systems/actionsAreConsumed")
local adjustWalkSpeed = require("@server/ecs/systems/adjustWalkSpeed")
local attachStatusEffects = require("@server/ecs/systems/attachStatusEffects")
local gunsAreRendered = require("@server/ecs/systems/gunsAreRendered")
local healthUpdates = require("@server/ecs/systems/healthUpdates")
local killsAreProcessed = require("@server/ecs/systems/killsAreProcessed")
local merryGoRoundsSpin = require("@server/ecs/systems/merryGoRoundsSpin")
local ragdollsAreApplied = require("@server/ecs/systems/ragdollsAreApplied")
local replecsUpdatesAreSent = require("@server/ecs/systems/replecsUpdatesAreSent")
local statModifiersApplied = require("@server/ecs/systems/statModifiersApplied")
local statusEffectsExpire = require("@server/ecs/systems/statusEffectsExpire")
local targetsAreKnocked = require("@server/ecs/systems/targetsAreKnocked")
local teamsAreAssigned = require("@server/ecs/systems/teamsAreAssigned")

local UNRELIABLE_COMPONENTS = {
	"Transform",
	"Velocity",
}

local function ensureCollisionGroup(name: string)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

ensureCollisionGroup("VoxelMesh")
ensureCollisionGroup("VoxelDebris")
-- VoxelMesh collides with everything by default, including itself: members
-- welded into one falling assembly skip internal collision automatically
-- (Roblox doesn't simulate internal collisions in a welded assembly), and
-- between assemblies (or between a falling section and static structures)
-- we WANT collisions so chunks bounce off, stack, and pile up.
PhysicsService:CollisionGroupSetCollidable("VoxelDebris", "VoxelDebris", false)

local function start(_systemsContainers: { Instance }, services: { [string]: any })
	local world = jecs.world()

	local replecsServer = replecs.create_server(world)
	replecsServer:init()

	local componentSerdes = (BlinkServer :: any).components
	local unreliableSet: { [string]: true } = {}
	for _, name in UNRELIABLE_COMPONENTS do
		unreliableSet[name] = true
	end

	for name, component in (Components :: any) :: { [string]: jecs.Entity } do
		world:set(component, jecs.Name, name)
		world:add(component, replecs.shared)

		local serdes = componentSerdes[name]
		if serdes ~= nil then
			world:set(component, replecs.serdes, {
				serialize = serdes.Write,
				deserialize = serdes.Read,
			})
		end
	end

	world:set(Components.VoxelGrid, jecs.OnAdd, function(entity: jecs.Entity, _id: jecs.Id, value: Components.VoxelGrid)
		VoxelOriginalData.set(entity :: any, VoxelBuffer.clone(value.data))
	end)

	world:set(Components.VoxelGrid, jecs.OnRemove, function(entity: jecs.Entity)
		VoxelOriginalData.remove(entity :: any)
		VoxelManager.cleanupEntity(entity :: any)
	end)

	registerObservers(world, { isClient = false })
	registerServerObservers(world, services)

	BlinkServer.ReplecsHandshakeRequest.On(function(player: Player)
		replecsServer:mark_player_ready(player)
		local changes, variants = replecsServer:get_full(player)
		BlinkServer.ReplecsHandshakeResponse.Fire(player, { Changes = changes, Variants = variants })
	end)

	jabby.register({
		name = "world",
		applet = jabby.applets.world,
		configuration = { world = world },
	})
	jabby.set_check_function(function(player: Player)
		return player:GetRankInGroup(33234854) >= 254
	end)

	local PreUpdate = planck.Phase.new("PreUpdate")
	local Update = planck.Phase.new("Update")
	local PostUpdate = planck.Phase.new("PostUpdate")

	local UpdatePipeline = planck.Pipeline.new("UpdatePipeline"):insert(PreUpdate):insert(Update):insert(PostUpdate)

	local state = {
		services = services,
		replecsServer = replecsServer,
		actionQueue = {} :: { { player: Player, payload: { [string]: any } } },
		scheduler = nil :: any,
	}

	local scheduler = planck.Scheduler.new(world, state :: any)
	state.scheduler = scheduler

	BlinkServer.ProcessAction.On(function(player: Player, payload: { [string]: any })
		table.insert(state.actionQueue, { player = player, payload = payload })
	end)

	scheduler:insert(UpdatePipeline, RunService, "Heartbeat")

	scheduler:addSystem(updateTransforms, PreUpdate)
	scheduler:addSystem(attachStatusEffects, PreUpdate)
	scheduler:addSystem(statModifiersApplied, PreUpdate)
	scheduler:addSystem(teamsAreAssigned, PreUpdate)
	scheduler:addSystem(accessoriesCantQuery, PreUpdate)

	scheduler:addSystem(projectilesTravel, Update)
	scheduler:addSystem(actionsAreConsumed, Update)
	scheduler:addSystem(healthUpdates, Update)
	scheduler:addSystem(statusEffectsExpire, Update)
	scheduler:addSystem(merryGoRoundsSpin, Update)
	scheduler:addSystem(gunsAreRendered, Update)

	scheduler:addSystem(adjustWalkSpeed, PostUpdate)
	scheduler:addSystem(ragdollsAreApplied, PostUpdate)
	scheduler:addSystem(targetsAreKnocked, PostUpdate)
	scheduler:addSystem(killsAreProcessed, PostUpdate)
	scheduler:addSystem(cooldownsExpire, PostUpdate)
	scheduler:addSystem(lifetimesDespawn, PostUpdate)
	scheduler:addSystem(replecsUpdatesAreSent, PostUpdate)

	for _, service in services do
		service.World = world
		service.Scheduler = scheduler
		service.Phases = { PreUpdate = PreUpdate, Update = Update, PostUpdate = PostUpdate }
	end

	local playerToEntityIdMap: { [Player]: jecs.Entity } = {}

	local function spawnPlayerEntity(player: Player, character: Model)
		if playerToEntityIdMap[player] and world:contains(playerToEntityIdMap[player]) then
			world:delete(playerToEntityIdMap[player])
		end

		local eid = world:entity()
		world:add(eid, replecs.networked)
		world:set(eid, Components.Player, { player = player })
		world:add(eid, jecs.pair(replecs.reliable, Components.Player))
		world:set(eid, Components.Renderable, { instance = character })
		world:add(eid, jecs.pair(replecs.reliable, Components.Renderable))
		world:set(eid, Components.Health, {
			health = 100,
			maxHealth = 100,
			regenRate = 0,
		})
		world:add(eid, jecs.pair(replecs.reliable, Components.Health))
		world:add(eid, jecs.pair(replecs.unreliable, Components.Transform))

		playerToEntityIdMap[player] = eid
		player:SetAttribute("serverEntityId", eid)
	end

	local function onPlayerAdded(player: Player)
		local character = player.Character or player.CharacterAdded:Wait()
		spawnPlayerEntity(player, character)

		player.CharacterAdded:Connect(function(newCharacter)
			spawnPlayerEntity(player, newCharacter)
		end)
	end

	local function onPlayerRemoving(player: Player)
		local eid = playerToEntityIdMap[player]
		if eid and world:contains(eid) then
			task.defer(function()
				world:delete(eid)
				playerToEntityIdMap[player] = nil
			end)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	for _, target in CollectionService:GetTagged("Target") do
		local eid = world:entity()
		world:add(eid, replecs.networked)
		world:set(eid, Components.Target, { CanTarget = false })
		world:add(eid, jecs.pair(replecs.reliable, Components.Target))
		world:set(eid, Components.Renderable, { instance = target })
		world:add(eid, jecs.pair(replecs.reliable, Components.Renderable))
		world:set(eid, Components.Health, {
			health = 100,
			maxHealth = 100,
			regenRate = 0,
		})
		world:add(eid, jecs.pair(replecs.reliable, Components.Health))
	end

	local VoxelSampler = require("@utilities/VoxelSampler")

	local function voxelizePart(part: BasePart)
		task.spawn(function()
			-- Inherit cell size from the part attribute, then walk ancestors, then default.
			local cellSize: number = (part:GetAttribute("VoxelCellSize") :: number?) or 2
			if not part:GetAttribute("VoxelCellSize") then
				local ancestor = part.Parent
				while ancestor do
					local inherited = ancestor:GetAttribute("VoxelCellSize") :: number?
					if inherited then
						cellSize = inherited
						break
					end
					ancestor = ancestor.Parent
				end
			end

			local data, sX, sY, sZ
			if part:IsA("MeshPart") then
				data, sX, sY, sZ = VoxelSampler.voxelizeMeshPart(part :: MeshPart, cellSize)
			else
				data, sX, sY, sZ = VoxelSampler.voxelizeBasePart(part, cellSize)
			end

			local eid = world:entity()
			world:add(eid, replecs.networked)
			world:set(eid, Components.Renderable, { instance = part })
			world:add(eid, jecs.pair(replecs.reliable, Components.Renderable))
			world:set(eid, Components.Transform, { cframe = part.CFrame })
			world:add(eid, jecs.pair(replecs.unreliable, Components.Transform))
			local gridValue: Components.VoxelGrid = {
				data = data,
				sizeX = sX,
				sizeY = sY,
				sizeZ = sZ,
				cellSize = cellSize,
			}
			world:set(eid, Components.VoxelGrid, gridValue)
			world:add(eid, jecs.pair(replecs.reliable, Components.VoxelGrid))
			world:add(eid, Components.Voxelized)
			world:add(eid, jecs.pair(replecs.reliable, Components.Voxelized))
			part:SetAttribute("voxelEntityId", eid)

			-- Build the visible greedy-meshed members and hide the source.
			VoxelManager.refreshEntity(eid, gridValue, part)
		end)
	end

	local function bootstrapVoxelizable(instance: Instance)
		if instance:IsA("BasePart") then
			voxelizePart(instance)
		else
			-- Model/Folder/etc.: voxelize all descendant BaseParts.
			for _, descendant in instance:GetDescendants() do
				if descendant:IsA("BasePart") then
					voxelizePart(descendant :: BasePart)
				end
			end
			-- Handle parts streamed or added to the container after bootstrap.
			instance.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("BasePart") then
					voxelizePart(descendant :: BasePart)
				end
			end)
		end
	end

	local function onVoxelizableTagged(instance: Instance)
		if instance:IsDescendantOf(workspace) then
			bootstrapVoxelizable(instance)
		else
			-- Pre-tagged in ServerStorage (or similar): bootstrap once moved into workspace.
			local conn
			conn = instance.AncestryChanged:Connect(function()
				if instance:IsDescendantOf(workspace) then
					conn:Disconnect()
					bootstrapVoxelizable(instance)
				end
			end)
		end
	end

	for _, instance in CollectionService:GetTagged("Voxelizable") do
		onVoxelizableTagged(instance)
	end
	CollectionService:GetInstanceAddedSignal("Voxelizable"):Connect(onVoxelizableTagged)

	return world
end

return start
