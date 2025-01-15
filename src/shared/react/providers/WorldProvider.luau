--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contexts = ReplicatedStorage.react.contexts
local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers

local InterfaceController = require(Controllers.InterfaceController)
local Matter = require(ReplicatedStorage.packages.Matter)
local React = require(ReplicatedStorage.packages.React)
local WorldContext = require(Contexts.WorldContext)

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
			worldChangedSignal = InterfaceController.WorldCreated:Connect(function(world: Matter.World)
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
