--!strict

local React = require("@packages/React")
local ResourceContext = require("@ui/contexts/ResourceContext")
local ResourceController = require("@controllers/ResourceController")
local Types = require("@constants/Types")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function ResourceProvider(props)
	local resources, setResources = useState(nil :: Types.PlayerResources?)

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
	end, { resources })

	return e(ResourceContext.Provider, {
		value = resources,
	}, props.children)
end

return ResourceProvider
