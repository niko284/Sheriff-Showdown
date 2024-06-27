--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)
local ReactSpring = require(ReplicatedStorage.packages.ReactSpring)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type ToggleButtonProps = Types.FrameProps & {
	toggled: boolean,
	onActivated: (boolean) -> (),
}

local function ToggleButton(props: ToggleButtonProps)
	local styles = ReactSpring.useSpring({
		config = { mass = 0.7, tension = 250, friction = 1, clamp = true },
		position = props.toggled and UDim2.fromOffset(31, 5) or UDim2.fromOffset(5, 5),
		backgroundColor = props.toggled and Color3.fromRGB(93, 221, 140) or Color3.fromRGB(255, 70, 95),
	}, { props.toggled })

	return e("ImageButton", {
		Image = "",
		BackgroundColor3 = styles.backgroundColor,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
		[React.Event.Activated] = function()
			props.onActivated(not props.toggled)
		end,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 1.4,
			Transparency = 0.69,
		}),

		toggleCircle = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = styles.position,
			Size = UDim2.fromOffset(26, 26),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})
end

return React.memo(ToggleButton)
