--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts

local React = require(ReplicatedStorage.packages.React)
local SettingsContext = require(Contexts.SettingsContext)
local SettingsController = require(Controllers.SettingsController)
local Types = require(ReplicatedStorage.constants.Types)

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
	end, {settingsState})

	return e(SettingsContext.Provider, {
		value = settingsState,
	}, props.children)
end

return SettingsProvider
