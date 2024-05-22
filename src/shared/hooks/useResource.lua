-- Use Resource
-- August 7th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local React = require(Packages.React)
local ResourceController = require(Controllers.ResourceController)

local useState = React.useState
local useEffect = React.useEffect

-- // Use Resource \\

local function useResource(ResourceName: string)
	local resourceValue, setResourceValue = useState(function()
		return ResourceController:GetResource(ResourceName)
	end)
	local oldValue, setOldValue = useState(nil)

	useEffect(function()
		local resourceChanged = ResourceController.ResourceChanged:Connect(
			function(Name: string, Value: any, OldValue: any)
				if Name == ResourceName then
					setResourceValue(Value)
					setOldValue(OldValue)
				end
			end
		)

		return function()
			resourceChanged:Disconnect()
		end
	end, { ResourceName, setResourceValue, setOldValue })

	return resourceValue, oldValue
end

return useResource
