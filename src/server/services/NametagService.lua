--!strict

-- Nametag Service
-- July 22nd, 2022
-- Nick

-- // Variables \\

local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local ResourceService = require(Services.ResourceService)

-- // Service Variables \\

local NametagService = {
	Name = "NametagService",
	NametagTrees = {},
}

-- // Functions \\

function NametagService:Start()
	-- Replicate nametag property changes to the client so the client can update the nametags.
	ResourceService:ObserveResourceChanged("Level", function(Player: Player, Level: number)
		Player:SetAttribute("Level", Level)
	end)
end

return NametagService
