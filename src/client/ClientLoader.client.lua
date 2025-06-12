local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local BootstrapCollections = require("@ecs/BootstrapCollections")
local Components = require("@ecs/components")
local Promise = require("@packages/Promise")
local ecsStart = require("@client/ecs/start")

local SYSTEM_CONTAINERS = {
	ReplicatedStorage.shared.ecs.systems,
	PlayerScripts.client.ecs.systems,
}
local CONTROLLER_CONTAINERS = {
	PlayerScripts.client.controllers,
}
local COLLECTION_COMPONENTS = {
	AnimatedRig = {
		Components.AnimatedRig,
	},
}
local LIFECYCLE_METHODS = { "OnInit", "OnStart" }

local function fetchControllers(controllerContainers)
	return Promise.new(function(resolve)
		local controllers = {}
		for _, container in ipairs(controllerContainers) do
			for _, controller in ipairs(container:GetChildren()) do
				local controllerModule = require(controller)
				controllers[controllerModule.Name] = controllerModule
			end
		end
		resolve(controllers)
	end)
end

local function loadClient()
	return fetchControllers(CONTROLLER_CONTAINERS)
		:andThen(function(controllers)
			-- call :OnStart() on all controllers.
			for _, lifecycleMethod in LIFECYCLE_METHODS do
				for name, controller in controllers do
					local method = controller[lifecycleMethod]
					if type(method) == "function" then
						debug.setmemorycategory(name)
						method(controller) -- we pass the service as the first argument since we are calling it as a method (: instead of .)
					end
				end
			end

			return controllers
		end)
		:andThen(function(controllers)
			local world = ecsStart(SYSTEM_CONTAINERS, controllers)
			BootstrapCollections(world, COLLECTION_COMPONENTS, { workspace })

			controllers.InterfaceController.WorldCreated:Fire(world)
		end)
end

loadClient()
	:andThen(function()
		print("Client loaded")
	end)
	:catch(function(err)
		warn("Error loading client: ", tostring(err))
	end)
