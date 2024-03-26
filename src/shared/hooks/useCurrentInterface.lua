-- Use Current Interface
-- October 11th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local InterfaceController = require(Controllers.InterfaceController)
local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)

local useCallback = React.useCallback
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef

-- // Use Current Interface \\

local function createStylesTable(isOpened: boolean, openPosition: UDim2, closedPosition: UDim2)
	return {
		to = {
			position = isOpened and openPosition or closedPosition,
			transparency = isOpened and 0 or 1.4,
		},
		from = if isOpened then { position = UDim2.fromScale(0.5, 0), transparency = isOpened and 1.4 or 0 } else nil,
		config = not isOpened and { duration = 0.55 } or ReactSpring.config.wobbly,
		reset = isOpened,
	}
end

local function useCurrentInterface(
	interfaceName: string,
	openPosition: UDim2,
	closedPosition: UDim2,
	buildStyles: ((boolean, UDim2, UDim2) -> { any })?,
	listenInterfaceChanged: boolean?
)
	local shouldRender, setShouldRender = useState(function()
		return InterfaceController:GetCurrentInterface() == interfaceName
	end)
	local lastAnimationPromise = useRef(nil)

	local styles, api = ReactSpring.useSpring(function()
		local stylesFn = buildStyles or createStylesTable
		return stylesFn(false, openPosition, closedPosition)
	end, { openPosition, closedPosition, buildStyles })

	local toggleInterface = useCallback(function(toggle: boolean)
		if lastAnimationPromise.current then
			lastAnimationPromise.current:cancel()
			lastAnimationPromise.current = nil
		end
		local stylesFn = buildStyles or createStylesTable
		if toggle then
			setShouldRender(true)
			lastAnimationPromise.current = api.start(stylesFn(true, openPosition, closedPosition))
		else
			lastAnimationPromise.current = api.start(stylesFn(false, openPosition, closedPosition)):andThen(function()
				setShouldRender(false)
			end)
		end
	end, { setShouldRender, api, lastAnimationPromise, closedPosition, openPosition, buildStyles } :: { any })

	useEffect(function()
		if InterfaceController:GetCurrentInterface() == interfaceName then
			toggleInterface(true)
		end
		local interfaceChanged = listenInterfaceChanged ~= false
			and InterfaceController.InterfaceChanged:Connect(function(InterfaceType: string?)
				print(InterfaceType)
				if InterfaceType == interfaceName then
					toggleInterface(true)
				elseif InterfaceType ~= interfaceName then
					toggleInterface(false)
				end
			end)
		return function()
			if interfaceChanged then
				interfaceChanged:Disconnect()
			end
		end
	end, { toggleInterface, interfaceName, listenInterfaceChanged } :: { any })

	return shouldRender, styles, toggleInterface
end

return useCurrentInterface
