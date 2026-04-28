local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local Components = require("@ecs/components")
local Promise = require("@packages/Promise")
local bootstrapCollections = require("@ecs/BootstrapCollections")
local ecsStart = require("@server/ecs/start")

local SYSTEM_CONTAINERS = {
	ReplicatedStorage.shared.ecs.systems,
	ServerScriptService.server.ecs.systems,
}
local SERVICE_CONTAINERS = {
	ServerScriptService.server.services,
}
local LIFECYCLE_METHODS = { "OnInit", "OnStart" }
local COLLECTION_COMPONENTS = {
	MerryGoRound = {
		{ Components.MerryGoRound, {
			targetAngularVelocity = 0,
			currentAngularVelocity = 0,
			angularAcceleration = 0.1,
			maxAngularVelocity = 1.5,
		} },
	},
}

local function fetchServices(serviceContainers)
	return Promise.new(function(resolve)
		local services = {}
		for _, container in ipairs(serviceContainers) do
			for _, service in ipairs(container:GetChildren()) do
				local serviceModule = require(service)
				services[service.Name] = serviceModule
			end
		end
		resolve(services)
	end)
end

local function loadServer()
	return fetchServices(SERVICE_CONTAINERS)
		:andThen(function(services)
			-- call :OnStart() on all services.
			for _, lifecycleMethod in LIFECYCLE_METHODS do
				for name, service in services do
					local method = service[lifecycleMethod]
					if type(method) == "function" then
						debug.setmemorycategory(name)
						method(service) -- no yielding is allowed in our lifecycle methods.
					end
				end
			end
			return services
		end)
		:andThen(function(services)
			local world = ecsStart(SYSTEM_CONTAINERS, services)
			bootstrapCollections(world, COLLECTION_COMPONENTS, { workspace }, function(eid: number)
				world:add(eid, replecs.networked)
				world:add(eid, jecs.pair(replecs.reliable, Components.MerryGoRound))
				world:add(eid, jecs.pair(replecs.reliable, Components.Renderable))
				world:add(eid, jecs.pair(replecs.unreliable, Components.Transform))
			end)
		end)
end

loadServer()
	:andThen(function()
		print("Server loaded")
	end)
	:catch(function(err)
		warn("Error loading server:", err)
	end)
