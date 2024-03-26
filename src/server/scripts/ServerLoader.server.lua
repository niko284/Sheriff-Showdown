-- Server Loader
-- January 22nd, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerComponents = ServerScriptService.components

local Cmdr = require(ServerScriptService.ServerPackages.Cmdr)
local Promise = require(ReplicatedStorage.packages.Promise)

local Services = {}

-- // Functions \\

local function LoadServer()
	return Promise.new(function(resolve, _reject)
		resolve("[ServerLoader] Loaded server")
	end)
end

local function LoadServerComponents()
	for _, ComponentModule in ServerComponents:GetDescendants() do
		if ComponentModule:IsA("ModuleScript") then
			require(ComponentModule)
		end
	end
end

local function serviceInit()
	local serviceInitPromises = {}
	for _, service in ServerScriptService.services:GetChildren() do
		if service:IsA("ModuleScript") then
			local serviceModule = require(service)
			assert(serviceModule.Name, "Service must have a name! Module at: " .. service:GetFullName() .. "")
			Services[serviceModule.Name] = serviceModule
			if serviceModule.Init and typeof(serviceModule.Init) == "function" then
				table.insert(
					serviceInitPromises,
					Promise.new(function(resolve)
						-- selene: allow(incorrect_standard_library_use)
						debug.setmemorycategory(serviceModule.Name)
						serviceModule:Init()
						resolve()
					end)
				)
			end
		end
	end
	return Promise.all(serviceInitPromises)
end

local function serviceStart()
	for _, service in Services do
		if service.Start and type(service.Start) == "function" then
			task.spawn(function()
				-- selene: allow(incorrect_standard_library_use)
				debug.setmemorycategory(service.Name)
				service:Start()
			end)
		end
	end
	return Promise.resolve()
end

local function initializePlayerAdded()
	local players = Players:GetPlayers()
	for _, service in pairs(Services) do
		if service.OnPlayerAdded and typeof(service.OnPlayerAdded) == "function" then
			for _, player in players do -- Run for all players already in the game
				service:OnPlayerAdded(player)
			end
		end
	end
	Players.PlayerAdded:Connect(function(player)
		for _, service in pairs(Services) do
			if service.OnPlayerAdded and typeof(service.OnPlayerAdded) == "function" then
				service:OnPlayerAdded(player)
			end
		end
	end)
end

local function initializePlayerRemoving()
	Players.PlayerRemoving:Connect(function(player)
		for _, service in pairs(Services) do
			if service.OnPlayerRemoving and typeof(service.OnPlayerRemoving) == "function" then
				service:OnPlayerRemoving(player)
			end
		end
	end)
end

-- // Loader \\

LoadServer()
	:andThen(function()
		-- Initialize services
		return serviceInit()
	end)
	:andThen(function()
		return serviceStart()
	end)
	:andThen(function()
		local nevermoreService = Services.NevermoreService
		local serviceBag = nevermoreService:GetServiceBag()
		serviceBag:Init()
		serviceBag:Start()
	end)
	:andThenCall(LoadServerComponents)
	:andThen(function()
		Cmdr.Registry:RegisterCommandsIn(ServerScriptService.cmdr.commands)
		Cmdr.Registry:RegisterTypesIn(ServerScriptService.cmdr.types)
		Cmdr.Registry:RegisterHooksIn(ServerScriptService.cmdr.hooks)
	end)
	:andThen(function()
		initializePlayerAdded()
		initializePlayerRemoving()
	end)
	:catch(function(err: any)
		print("[ServerLoader] Error: " .. tostring(err))
	end)
