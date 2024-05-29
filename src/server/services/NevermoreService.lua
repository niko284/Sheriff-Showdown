--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)

local NevermoreService = {
	Name = "NevermoreService",
}

-- // Functions \\

function NevermoreService:OnInit()
	NevermoreService:LoadNevermore()
		:andThen(function(_clientPackages, serverPackages, _sharedPackages)
			NevermoreService.ServiceBag = require(serverPackages.ServiceBag).new() :: any
		end)
		:catch(function(error: any)
			warn(tostring(error))
		end)
end

function NevermoreService:GetPackage(PackageName: string)
	return self.ServiceBag:GetService(self.ServerPackages[PackageName])
end

function NevermoreService:GetServiceBag()
	return self.ServiceBag
end

function NevermoreService:LoadNevermore()
	return Promise.new(function(resolve, _reject, _onCancel)
		local NevermoreLoaderUtilsModule = ServerScriptService.nodeModules:FindFirstChild("LoaderUtils", true)
		local NevermoreLoaderUtils = require(NevermoreLoaderUtilsModule) :: any

		local client, server, shared = NevermoreLoaderUtils.toWallyFormat(ServerScriptService.nodeModules, false)
		client.Name = "NevermoreClientPackages"
		client.Parent = ReplicatedStorage

		server.Name = "NevermoreServerPackages"
		server.Parent = ServerScriptService
		NevermoreService.ServerPackages = server

		shared.Name = "NevermoreSharedPackages"
		shared.Parent = ReplicatedStorage

		resolve(client, server, shared)
	end)
end

return NevermoreService
