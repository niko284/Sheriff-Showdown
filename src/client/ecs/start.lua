--!strict

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local jabby = require("@packages/jabby")
local jecs = require("@packages/jecs")
local planck = require("@packages/planck")
local replecs = require("@packages/replecs")

local Spark = require("@packages/Spark")

local BlinkClient = require("@client/modules/BlinkClient")
local Components = require("@ecs/components")
local GunPrediction = require("@client/ecs/gunPrediction")
local registerClientObservers = require("@client/ecs/observers")
local registerObservers = require("@ecs/observers")

-- Shared systems
local cooldownsExpire = require("@ecs/systems/cooldownsExpire")
local lifetimesDespawn = require("@ecs/systems/lifetimesDespawn")
local projectilesTravel = require("@ecs/systems/projectilesTravel")
local updateTransforms = require("@ecs/systems/updateTransforms")

-- Client-only systems
local gunsCanShoot = require("@client/ecs/systems/gunsCanShoot")
local idleAnimationsPlay = require("@client/ecs/systems/idleAnimationsPlay")
local merryGoRoundsImpulse = require("@client/ecs/systems/merryGoRoundsImpulse")
local merryGoRoundsRender = require("@client/ecs/systems/merryGoRoundsRender")
local mobileExtendedHitbox = require("@client/ecs/systems/mobileExtendedHitbox")
local projectilesAreVisualized = require("@client/ecs/systems/projectilesAreVisualized")
local projectilesCollide = require("@client/ecs/systems/projectilesCollide")
local teamsAreHighlighted = require("@client/ecs/systems/teamsAreHighlighted")
local updateInputs = require("@client/ecs/systems/updateInputs")
local voxelDeltasAreApplied = require("@client/ecs/systems/voxelDeltasAreApplied")

local InputState = Spark.InputState
local Actions = Spark.Actions
local InputMap = Spark.InputMap

local UNRELIABLE_COMPONENTS = {
	"Transform",
	"Velocity",
}

local function start(_systemsContainers: { Instance }, controllers: { [string]: any })
	local world = jecs.world()

	local replecsClient = replecs.create_client(world)
	replecsClient:init()

	local componentSerdes = (BlinkClient :: any).components
	local unreliableSet: { [string]: true } = {}
	for _, name in UNRELIABLE_COMPONENTS do
		unreliableSet[name] = true
	end

	for name, component in (Components :: any) :: { [string]: jecs.Entity } do
		world:set(component, jecs.Name, name)
		world:add(component, replecs.shared)

		if unreliableSet[name] then
			world:add(component, replecs.unreliable)
		else
			world:add(component, replecs.reliable)
		end

		local serdes = componentSerdes[name]
		if serdes ~= nil then
			world:set(component, replecs.serdes, {
				serialize = serdes.Write,
				deserialize = serdes.Read,
			})
		end
	end

	world:set(
		Components.ProjectilePrediction,
		replecs.custom_handler,
		function(prediction: Components.ProjectilePrediction?)
			if not prediction then
				return world:entity()
			end

			for eid, _projectile, existingPrediction: Components.ProjectilePrediction in
				world:query(Components.Projectile, Components.ProjectilePrediction)
			do
				if existingPrediction.uuid == prediction.uuid and replecsClient:get_server_entity(eid) == nil then
					return eid
				end
			end

			return world:entity()
		end
	)

	registerObservers(world, { isClient = true, replecsClient = replecsClient })
	registerClientObservers(world, replecsClient)
	GunPrediction.register(world)

	BlinkClient.ReplecsUpdate.On(function(pkg)
		replecsClient:apply_updates(pkg.Changes :: buffer, pkg.Variants :: { { any } })
	end)
	BlinkClient.ReplecsUnreliableUpdate.On(function(pkg)
		replecsClient:apply_unreliable(pkg.Changes :: buffer, pkg.Variants :: { { any } })
	end)
	BlinkClient.ReplecsHandshakeResponse.On(function(pkg)
		replecsClient:apply_full(pkg.Changes :: buffer, pkg.Variants :: { { any } })
	end)

	BlinkClient.ReplecsHandshakeRequest.Fire(0)

	local jabbyClient = jabby.obtain_client()
	ContextActionService:BindAction("Open Jabby Home", function(_, inputState: Enum.UserInputState)
		if inputState ~= Enum.UserInputState.Begin then
			return
		end
		jabbyClient.spawn_app(jabbyClient.apps.home, nil)
	end, false, Enum.KeyCode.F4)

	local state = {
		inputState = InputState.new(),
		actions = Actions.new({ "shoot" }),
		inputMap = InputMap.new():insert("shoot", Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1),
		controllers = controllers,
		replecsClient = replecsClient,
		scheduler = nil :: any,
	}

	local PreUpdate = planck.Phase.new("PreUpdate")
	local Update = planck.Phase.new("Update")
	local PostUpdate = planck.Phase.new("PostUpdate")
	local Render = planck.Phase.new("Render")

	local UpdatePipeline = planck.Pipeline.new("UpdatePipeline"):insert(PreUpdate):insert(Update):insert(PostUpdate)
	local RenderPipeline = planck.Pipeline.new("RenderPipeline"):insert(Render)

	local scheduler = planck.Scheduler.new(world, state :: any)
	state.scheduler = scheduler

	scheduler:insert(UpdatePipeline, RunService, "Heartbeat")
	scheduler:insert(RenderPipeline, RunService, "RenderStepped")

	-- Render pipeline: input update runs first
	scheduler:addSystem(updateInputs, Render)

	-- PreUpdate: transforms, hitboxes
	scheduler:addSystem(updateTransforms, PreUpdate)
	scheduler:addSystem(mobileExtendedHitbox, PreUpdate)

	-- Update: gameplay logic
	scheduler:addSystem(projectilesTravel, Update)
	scheduler:addSystem(projectilesAreVisualized, Update)
	scheduler:addSystem(gunsCanShoot, Update)
	scheduler:addSystem(merryGoRoundsImpulse, Update)
	scheduler:addSystem(merryGoRoundsRender, Update)
	scheduler:addSystem(idleAnimationsPlay, Update)
	scheduler:addSystem(teamsAreHighlighted, Update)

	-- PostUpdate: cleanup
	scheduler:addSystem(projectilesCollide, PostUpdate)
	scheduler:addSystem(voxelDeltasAreApplied, PostUpdate)
	scheduler:addSystem(cooldownsExpire, PostUpdate)
	scheduler:addSystem(lifetimesDespawn, PostUpdate)

	for _, controller in controllers do
		controller.World = world
		controller.Scheduler = scheduler
		controller.Phases = {
			PreUpdate = PreUpdate,
			Update = Update,
			PostUpdate = PostUpdate,
			Render = Render,
		}
	end

	return world
end

return start
