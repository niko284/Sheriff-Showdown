-- Client Loader
-- February 18th, 2022
-- Nick

-- selene: allow(global_usage)
if game:GetService("RunService"):IsStudio() then
	_G.__DEV__ = true
	_G.__PROFILE__ = true
end
--[[_G.__YOLO__ = true
_G.__PROFILE__ = true
_G.__EXPERIMENTAL__ = true
_G.performance = {
	mark = function(s)
		--print(debug.traceback())
		--print("React scheduler profiling: " .. s)
	end,
}--]]

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils
local ClientComponentsFolder = ReplicatedStorage:WaitForChild("instanceComponents")

local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
local PlayerUtils = require(Utils.PlayerUtils)
local Promise = require(Packages.Promise)

local Controllers = {}

-- Wait for PlayerScript controllers
Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("controllers")

-- // Functions \\

local function LoadClientComponents()
	for _, ComponentModule in pairs(ClientComponentsFolder:GetDescendants()) do
		if ComponentModule:IsA("ModuleScript") then
			require(ComponentModule)
		end
	end
end

local function LoadClient()
	return Promise.new(function(resolve, _reject)
		resolve("[ClientLoader] Loaded client")
	end)
end

local function controllerInit()
	local controllerInitPromises = {}
	for _, controller in LocalPlayer.PlayerScripts.controllers:GetChildren() do
		if controller:IsA("ModuleScript") then
			local controllerModule = require(controller)
			assert(controllerModule.Name, "Controller must have a name! Module at: " .. controller:GetFullName() .. "")
			Controllers[controllerModule.Name] = controllerModule
			if controllerModule.Init and typeof(controllerModule.Init) == "function" then
				table.insert(
					controllerInitPromises,
					Promise.new(function(resolve)
						-- selene: allow(incorrect_standard_library_use)
						debug.setmemorycategory(controllerModule.Name)
						controllerModule:Init()
						resolve()
					end)
				)
			end
		end
	end
	return Promise.all(controllerInitPromises)
end

local function controllerStart()
	for _, controller in Controllers do
		if controller.Start and type(controller.Start) == "function" then
			task.spawn(function()
				-- selene: allow(incorrect_standard_library_use)
				debug.setmemorycategory(controller.Name)
				controller:Start()
			end)
		end
	end
	return Promise.resolve()
end

local function initializePlayerAdded()
	local players = Players:GetPlayers()
	for _, controller in pairs(Controllers) do
		if controller.OnPlayerAdded and typeof(controller.OnPlayerAdded) == "function" then
			for _, player in players do
				controller:OnPlayerAdded(player)
			end
		end
	end
	Players.PlayerAdded:Connect(function(player)
		for _, controller in pairs(Controllers) do
			if controller.OnPlayerAdded and typeof(controller.OnPlayerAdded) == "function" then
				controller:OnPlayerAdded(player)
			end
		end
	end)
end

local function initializePlayerRemoving()
	Players.PlayerRemoving:Connect(function(player: Player)
		for _, controller in pairs(Controllers) do
			if controller.OnPlayerRemoving and typeof(controller.OnPlayerRemoving) == "function" then
				controller:OnPlayerRemoving(player)
			end
		end
	end)
end

-- // Loader \\

LoadClient()
	:andThen(function()
		return controllerInit()
	end)
	:andThen(function()
		return controllerStart()
	end)
	:andThen(function()
		local NevermoreController = Controllers.NevermoreController
		local serviceBag = NevermoreController:GetServiceBag()
		serviceBag:Init()
		serviceBag:Start()
	end)
	:andThenCall(LoadClientComponents)
	:andThen(function()
		CmdrClient:SetActivationKeys({ Enum.KeyCode.BackSlash, Enum.KeyCode.LeftBracket })
		local plrRank = PlayerUtils.GetRankInGroup(Players.LocalPlayer, 33234854)
		if plrRank < 254 and RunService:IsStudio() == false then
			CmdrClient:SetEnabled(false)
		end
	end)
	:andThen(function()
		initializePlayerAdded()
		initializePlayerRemoving()
	end)
	:catch(function(err: any)
		warn("[ClientLoader] Error loading client: " .. tostring(err))
	end)
