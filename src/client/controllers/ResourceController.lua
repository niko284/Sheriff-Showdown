--!strict

local ClientComm = require("../ClientComm")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local PlayerResourcesProperty = ClientComm:GetProperty("PlayerResources")

local ResourceController = {
	Name = "ResourceController",
	ResourcesChanged = Signal.new() :: Signal.Signal<Types.PlayerResources>,
}

function ResourceController:OnInit()
	PlayerResourcesProperty:Observe(function(playerResources: Types.PlayerResources)
		ResourceController.ResourcesChanged:Fire(playerResources)
	end)
end

function ResourceController:GetReplicatedResources()
	return PlayerResourcesProperty:Get()
end

return ResourceController
