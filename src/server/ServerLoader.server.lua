local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)
local ecsStart = require(ServerScriptService.ecs.start)

local SYSTEM_CONTAINERS = {
	ReplicatedStorage.ecs.systems,
	ServerScriptService.ecs.systems,
}
local SERVICE_CONTAINERS = {
	ServerScriptService.services,
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
			for name, service in services do
				local method = service.OnStart
				if type(method) == "function" then
					task.spawn(function()
						debug.setmemorycategory(name)
						method(service) -- we pass the service as the first argument since we are calling it as a method (: instead of .)
					end)
				end
			end
			return services
		end)
		:andThen(function(services)
			ecsStart(SYSTEM_CONTAINERS, services)
		end)
end

loadServer()
	:andThen(function()
		print("Server loaded")
	end)
	:catch(function(err)
		warn("Error loading server:", err)
	end)
