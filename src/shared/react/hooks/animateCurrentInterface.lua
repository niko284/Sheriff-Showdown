--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Contexts = ReplicatedStorage.react.contexts

local CurrentInterfaceContext = require(Contexts.CurrentInterfaceContext)
local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)

local useCallback = React.useCallback
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useContext = React.useContext

-- // Use Current Interface \\

local function createStylesTable(isOpened: boolean, openPosition: UDim2, closedPosition: UDim2): any
	return {
		to = {
			position = isOpened and openPosition or closedPosition,
			transparency = isOpened and 0 or 1,
		},
		from = if isOpened then { position = UDim2.fromScale(0.5, 0), transparency = isOpened and 1 or 0 } else nil,
		config = not isOpened and { duration = 0.55 } or ReactSpring.config.wobbly,
		reset = isOpened,
	}
end

local function animateCurrentInterface(
	interfaceName: Types.Interface,
	openPosition: UDim2,
	closedPosition: UDim2,
	buildStyles: ((boolean, UDim2, UDim2) -> any)?
)
	local shouldRender, setShouldRender = useState(false)
	local lastAnimationPromise = useRef(nil)

	local currentInterface = useContext(CurrentInterfaceContext)

	local styles, api = ReactSpring.useSpring(function()
		local stylesFn = (buildStyles or createStylesTable) :: any
		return stylesFn(false, openPosition, closedPosition)
	end, { openPosition, closedPosition, buildStyles } :: { any })

	local toggleInterface = useCallback(function(toggle: boolean)
		if lastAnimationPromise.current then
			lastAnimationPromise.current:cancel()
			lastAnimationPromise.current = nil
		end
		local stylesFn = (buildStyles or createStylesTable) :: any
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
		toggleInterface(currentInterface.current == interfaceName)
	end, { currentInterface, interfaceName } :: { any })

	return shouldRender, styles, toggleInterface
end

return animateCurrentInterface
