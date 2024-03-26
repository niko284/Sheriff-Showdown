-- Resource Middleware
-- August 8th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local ResourceController = require(Controllers.ResourceController)

-- // Middleware \\

return function(nextDispatch, store)
	return function(action)
		if action.type == "SetResources" and action.payload then
			local oldResources = store:getState().Resources or {}
			if not oldResources then
				return nextDispatch(action)
			end
			local newResources = action.payload
			for resourceName, resource in pairs(newResources) do
				if oldResources[resourceName] ~= resource then
					ResourceController.ResourceChanged:Fire(resourceName, resource, oldResources[resourceName])
				end
			end
		end
		return nextDispatch(action)
	end
end
