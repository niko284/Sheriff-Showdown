local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)
local ecsStart = require(PlayerScripts.ecs.start)

local SYSTEM_CONTAINERS = {
	ReplicatedStorage.ecs.systems,
	PlayerScripts.ecs.systems,
}
local CONTROLLER_CONTAINERS = {
	PlayerScripts.controllers,
}

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
			for name, controller in controllers do
				local method = controller.OnStart
				if type(method) == "function" then
					task.spawn(function()
						debug.setmemorycategory(name)
						method(controller) -- we pass the service as the first argument since we are calling it as a method (: instead of .)
					end)
				end
			end
			return controllers
		end)
		:andThen(function()
			ecsStart(SYSTEM_CONTAINERS)
		end)
end

loadClient()
	:andThen(function()
		print("Client loaded")
	end)
	:catch(function(err)
		warn("Error loading client: ", tostring(err))
	end)
