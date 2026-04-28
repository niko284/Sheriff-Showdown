--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local ResourceController = {
	Name = "ResourceController",
	ResourcesChanged = Signal.new() :: Signal.Signal<Types.PlayerResources>,
	CurrentResources = nil :: Types.PlayerResources?,
}

function ResourceController:OnInit()
	BlinkClient.ResourcesSync.On(function(playerResources: Types.PlayerResources)
		ResourceController.CurrentResources = playerResources
		ResourceController.ResourcesChanged:Fire(playerResources)
	end)
end

function ResourceController:GetReplicatedResources()
	return ResourceController.CurrentResources
end

return ResourceController
