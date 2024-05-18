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

local function loadClient()
	return Promise.new(function(resolve)
		ecsStart(SYSTEM_CONTAINERS)
		resolve()
	end)
end

loadClient()
	:andThen(function()
		print("Client loaded")
	end)
	:catch(function(err)
		warn("Error loading client: ", tostring(err))
	end)
