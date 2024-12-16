--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NevermoreController = {
	Name = "NevermoreController",
}

function NevermoreController:OnInit()
	NevermoreController.ClientPackages = ReplicatedStorage:WaitForChild("NevermoreClientPackages") :: any
	NevermoreController.ServiceBag = require(NevermoreController.ClientPackages.ServiceBag).new() :: any
end

function NevermoreController:OnStart() end

function NevermoreController:GetServiceBag()
	return self.ServiceBag
end

function NevermoreController:GetPackage(PackageName: string)
	return self.ServiceBag:GetService(self.ClientPackages[PackageName])
end

return NevermoreController
