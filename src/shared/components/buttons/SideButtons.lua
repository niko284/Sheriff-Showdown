-- Side Buttons
-- February 7th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Components = ReplicatedStorage.components
local Packages = ReplicatedStorage.packages
local PlayerScripts = LocalPlayer.PlayerScripts
local Rodux = PlayerScripts.rodux
local Slices = Rodux.slices

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local CurrentInterfaceSlice = require(Slices.CurrentInterfaceSlice)
local React = require(Packages.React)
local ReactRodux = require(Packages.ReactRodux)
local SideButton = require(Components.buttons.SideButton)

local e = React.createElement

local SIDE_BUTTON_DATA = {
	{
		name = "Shop",
		image = "rbxassetid://16170170415",
	},
	{
		name = "Inventory",
		image = "rbxassetid://16169453434",
	},
	{
		name = "Trade",
		image = "rbxassetid://16170188403",
	},
	{
		name = "Settings",
		image = "rbxassetid://16170078705",
	},
}

-- // Side Buttons \\

local function SideButtons()
	local dispatch = ReactRodux.useDispatch()

	local sideButtonElements = {}

	for index, sideButtonData in SIDE_BUTTON_DATA do
		sideButtonElements[sideButtonData.name] = e(SideButton, {
			name = sideButtonData.name,
			image = sideButtonData.image,
			layoutOrder = index,
			size = UDim2.fromOffset(64, 64),
			onActivated = function()
				print("Dispatching ", sideButtonData.name)
				dispatch(CurrentInterfaceSlice.actions.SetCurrentInterface({ interface = sideButtonData.name }))
			end,
		})
	end

	return e(AutomaticFrame, {
		instanceProps = {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.042, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		},
	}, {
		listLayout = e("UIListLayout", {
			Padding = UDim.new(0.025, 0),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		buttons = React.createElement(React.Fragment, nil, sideButtonElements),
	})
end

return React.memo(SideButtons)
