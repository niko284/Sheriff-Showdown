-- Nevermore Controller
-- March 6th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Controller \\

local NevermoreController = {
	Name = "NevermoreController",
}

-- // Functions \\

function NevermoreController:Init()
	NevermoreController.ClientPackages = ReplicatedStorage:WaitForChild("NevermoreClientPackages")
	NevermoreController.ServiceBag = require(NevermoreController.ClientPackages.ServiceBag).new()
end

function NevermoreController:Start() end

function NevermoreController:GetPackage(PackageName: string)
	return self.ServiceBag:GetService(self.ClientPackages[PackageName])
end

return NevermoreController
