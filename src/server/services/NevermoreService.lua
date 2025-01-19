local ServerScriptService = game:GetService("ServerScriptService")

local loader = ServerScriptService.nodeModules:FindFirstChild("LoaderUtils", true).Parent

local require = require(loader).bootstrapGame(ServerScriptService.nodeModules)

local serviceBag = require("ServiceBag").new()

local NevermoreService = {
	require = require,
	serviceBag = serviceBag,
	Name = "NevermoreService",
}

serviceBag:GetService(require("RagdollService"))

serviceBag:Init()
serviceBag:Start()

return NevermoreService
