--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Contexts = ReplicatedStorage.react.contexts
local Controllers = PlayerScripts.controllers

local React = require(ReplicatedStorage.packages.React)
local ResourceContext = require(Contexts.ResourceContext)
local ResourceController = require(Controllers.ResourceController)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function ResourceProvider(props)
	local resources, setResources = useState({} :: Types.PlayerResources)

	useEffect(function()

        if resources == nil then
            local replicatedResources = ResourceController:GetReplicatedResources()
            if replicatedResources then
                setResources(replicatedResources)
            end
        end

		local resourcesChanged = ResourceController.ResourcesChanged:Connect(function(newResources)
			setResources(newResources)
		end)

		return function()
			resourcesChanged:Disconnect()
		end
	end, {resources})

	return e(ResourceContext.Provider, {
		value = resources,
	}, props.children)
end

return ResourceProvider
