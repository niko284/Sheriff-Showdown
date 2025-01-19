--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)
local ScaleContext = require(ReplicatedStorage.react.contexts.ScaleContext)

local e = React.createElement
local useContext = React.useContext

type StrokeProps = {
	color: Color3?,
	thickness: number?,
	applyStrokeMode: Enum.ApplyStrokeMode?,
	transparency: (number | React.Binding<number>)?,
}

local function UIStroke(props: StrokeProps)
	local scaleContext = useContext(ScaleContext)

	return e("UIStroke", {
		Color = props.color,
		Thickness = scaleContext.scale * (props.thickness or 1),
		ApplyStrokeMode = props.applyStrokeMode,
		Transparency = props.transparency,
	})
end

return React.memo(UIStroke)
