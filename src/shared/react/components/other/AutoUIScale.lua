--!strict
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)

local Camera = workspace.CurrentCamera
local TopInset, BottomInset = GuiService:GetGuiInset()

local e = React.createElement
local useState = React.useState
local useCallback = React.useCallback
local useEffect = React.useEffect

type AutoUIScaleProps = {
	scale: number?,
	size: Vector2,
	onScaleRatioChanged: ((number) -> ())?,
}

local function AutoUIScale(props: AutoUIScaleProps)
	local updateScale = useCallback(function()
		local vpSize = Camera.ViewportSize - (TopInset + BottomInset)
		local newScale = 1 / math.max(props.size.X / vpSize.X, props.size.Y / vpSize.Y)
		if newScale ~= props.scale then
			if props.onScaleRatioChanged and typeof(props.onScaleRatioChanged) == "function" then
				props.onScaleRatioChanged(newScale)
			end
		end
	end, { props.size, props.scale, props.onScaleRatioChanged } :: { any })
	useEffect(function()
		updateScale()
		local viewportSizeChanged = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			updateScale()
		end)
		return function()
			viewportSizeChanged:Disconnect()
		end
	end, { updateScale })
	return e("UIScale", {
		Scale = props.scale,
	})
end

return AutoUIScale
