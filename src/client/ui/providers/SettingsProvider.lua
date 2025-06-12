--!strict

local React = require("@packages/React")
local SettingsContext = require("@ui/contexts/SettingsContext")
local SettingsController = require("@controllers/SettingsController")
local Types = require("@constants/Types")

local e = React.createElement
local useEffect = React.useEffect
local useState = React.useState

local function SettingsProvider(props)
	local settingsState, setSettingsState = useState({} :: Types.PlayerDataSettings)

	useEffect(function()
		if settingsState == nil then
			local playerSettings = SettingsController:GetReplicatedSettings()
			if playerSettings then
				setSettingsState(playerSettings)
			end
		end
		local settingsChanged = SettingsController.SettingsChanged:Connect(
			function(playerSettings: Types.PlayerDataSettings)
				setSettingsState(playerSettings)
			end
		)

		return function()
			settingsChanged:Disconnect()
		end
	end, { settingsState })

	return e(SettingsContext.Provider, {
		value = settingsState,
	}, props.children)
end

return SettingsProvider
