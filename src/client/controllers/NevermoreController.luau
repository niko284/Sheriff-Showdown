local ReplicatedStorage = game:GetService("ReplicatedStorage")

local loader = ReplicatedStorage:WaitForChild("nodeModules"):WaitForChild("loader") :: any

local require = require(loader).bootstrapGame(ReplicatedStorage.nodeModules)

local serviceBag = require("ServiceBag").new()

local NevermoreController = {
	require = require,
	serviceBag = serviceBag,
	Name = "NevermoreController",
}

serviceBag:GetService(require("RagdollServiceClient"))

serviceBag:Init()
serviceBag:Start()

return NevermoreController
