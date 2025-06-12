--!strict

local CurrentInterfaceContext = require("@ui/contexts/CurrentInterfaceContext")
local InterfaceController = require("@controllers/InterfaceController")
local React = require("@packages/React")

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function CurrentInterfaceProvider(props)
	local currentInterface, setCurrentInterface = useState(nil)
	local hideHUD, setHideHUD = useState(false)

	useEffect(function()
		local interfaceChangedConnection = InterfaceController.InterfaceChanged:Connect(function(newInterface)
			setCurrentInterface(newInterface)
		end)
		local hideHUDConnection = InterfaceController.HideHUD:Connect(function(shouldHide: boolean)
			setHideHUD(shouldHide)
		end)
		return function()
			hideHUDConnection:Disconnect()
			interfaceChangedConnection:Disconnect()
		end
	end, {})

	return e(CurrentInterfaceContext.Provider, {
		value = {
			current = currentInterface,
			hideHUD = hideHUD,
		},
	}, props.children)
end

return CurrentInterfaceProvider
