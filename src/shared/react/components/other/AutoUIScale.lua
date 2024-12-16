--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Settings = require(ReplicatedStorage.constants.Settings)
local LocalPlayer = Players.LocalPlayer
local SettingsController = require(LocalPlayer.PlayerScripts.controllers.SettingsController)

local React = require(Packages.React)

local Camera = workspace.CurrentCamera
local TopInset, BottomInset = GuiService:GetGuiInset()

local e = React.createElement
local useState = React.useState
local useCallback = React.useCallback
local useEffect = React.useEffect

type AutoUIScaleProps = {
	scale: number,
	size: Vector2,
	onScaleRatioChanged: ((number) -> ())?,
}

local function AutoUIScale(props: AutoUIScaleProps)
	local multiplier, setMultiplier = useState(1)
	local updateScale = useCallback(function()
		local vpSize = Camera.ViewportSize - (TopInset + BottomInset)
		local newScale = 1 / math.max(props.size.X / vpSize.X, props.size.Y / vpSize.Y)
		if newScale ~= props.scale then
			if props.onScaleRatioChanged and typeof(props.onScaleRatioChanged) == "function" then
				props.onScaleRatioChanged(newScale)
			end
		end
	end, { props.size, props.scale, props.onScaleRatioChanged, multiplier } :: { any })
	useEffect(function()
		updateScale()
		local viewportSizeChanged = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			updateScale()
		end)
		local scaleMultiplierChanged = SettingsController:ObserveSettingsChanged(function(settings)
			local uiScale = settings["UI Scale"]
			if uiScale then
				local max = Settings["UI Scale" :: any].Maximum :: number
				local min = Settings["UI Scale" :: any].Minimum :: number
				-- map percent to min-max range i.e 100% to max and 0% to min
				local percent = (uiScale.Value :: number) / 100
				local value = min + (max - min) * percent
				setMultiplier(value / 100)
			end
		end)
		return function()
			viewportSizeChanged:Disconnect()
			scaleMultiplierChanged:Disconnect()
		end
	end, { updateScale, setMultiplier } :: { any })
	return e("UIScale", {
		Scale = (props.scale or 1) * multiplier,
	})
end

return AutoUIScale
