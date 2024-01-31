--!strict

-- Auto UI Scale
-- January 21st, 2024
-- Nick

-- // Variables \\

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

-- // Auto UI Scale \\

local function AutoUIScale(props: AutoUIScaleProps)
	local scale, setScale = useState(props.scale)
	local updateScale = useCallback(function()
		local vpSize = Camera.ViewportSize - (TopInset + BottomInset)
		setScale(function(oldScale: number)
			local newScale = 1 / math.max(props.size.X / vpSize.X, props.size.Y / vpSize.Y)
			if newScale ~= oldScale then
				if props.onScaleRatioChanged and typeof(props.onScaleRatioChanged) == "function" then
					props.onScaleRatioChanged(newScale * (props.scale or 1))
				end
				return newScale
			end
			return oldScale
		end)
	end, { props.size, setScale, props.scale, props.onScaleRatioChanged } :: { any })
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
		Scale = scale * (props.scale or 1),
	})
end

return AutoUIScale
