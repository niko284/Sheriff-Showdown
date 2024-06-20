--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts

local CurrentInterfaceContext = require(Contexts.CurrentInterfaceContext)
local InterfaceController = require(Controllers.InterfaceController)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local useContext = React.useContext
local e = React.createElement

type SideButtonProps = Types.FrameProps & {
	gradient: ColorSequence,
	icon: string,
	buttonPath: Types.Interface,
}

local function SideButton(props: SideButtonProps)
	local currentInterface = useContext(CurrentInterfaceContext)

	return e("ImageButton", {
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		BackgroundColor3 = Color3.fromRGB(38, 38, 38),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
		[React.Event.Activated] = function()
			if currentInterface.current == props.buttonPath then
				InterfaceController.InterfaceChanged:Fire(nil)
			else
				InterfaceController.InterfaceChanged:Fire(props.buttonPath)
			end
		end,
	}, {
		gradient = e("UIGradient", {
			Color = props.gradient,
		}),

		uIStroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 15),
		}),

		pattern = e("ImageLabel", {
			Image = "rbxassetid://18128482523",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(78, 78),
		}),

		buttonIcon = e("ImageLabel", {
			Image = props.icon,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(21, 20),
			Size = UDim2.fromOffset(36, 38),
		}),
	})
end

return React.memo(SideButton)
