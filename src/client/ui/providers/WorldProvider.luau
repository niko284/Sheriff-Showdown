--!strict

local InterfaceController = require("@controllers/InterfaceController")
local jecs = require("@packages/jecs")
local React = require("@packages/React")
local WorldContext = require("@ui/contexts/WorldContext")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function WorldProvider(props)
	local worldState, setWorldState = useState({})

	useEffect(function()
		local worldChangedSignal
		if InterfaceController.World then
			setWorldState({
				world = InterfaceController.World,
			})
		else
			worldChangedSignal = InterfaceController.WorldCreated:Connect(function(world: jecs.World)
				setWorldState({
					world = world,
				})
			end)
		end

		return function()
			if worldChangedSignal then
				worldChangedSignal:Disconnect()
			end
		end
	end, {})

	return e(WorldContext.Provider, {
		value = worldState,
	}, props.children)
end

return WorldProvider
