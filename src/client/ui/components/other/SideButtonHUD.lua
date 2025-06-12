local CurrentInterfaceContext = require("@ui/contexts/CurrentInterfaceContext")
local React = require("@packages/React")
local ReactSpring = require("@packages/ReactSpring")
local SideButton = require("@ui/components/buttons/SideButton")
local TradeContext = require("@ui/contexts/TradeContext")
local Types = require("@constants/Types")

local useSpring = ReactSpring.useSpring
local useContext = React.useContext
local e = React.createElement

type SideButtonData = {
	Image: string,
	Gradient: ColorSequence,
	LayoutOrder: number,
	Opacity: number?,
}
type SideButtonHUDProps = {
	buttons: { [Types.Interface]: SideButtonData },
}

local function SideButtonHUD(props: SideButtonHUDProps)
	local sideButtonElements = {} :: React.ReactElement<any, any>

	local tradeState = useContext(TradeContext)
	local currentInterfaceState = useContext(CurrentInterfaceContext)

	local styles = useSpring({
		position = currentInterfaceState.hideHUD and UDim2.fromScale(-0.3, 0.219) or UDim2.fromScale(0.00573, 0.219),
	}, { currentInterfaceState.hideHUD })

	for name, sideButton in pairs(props.buttons) do
		sideButtonElements[name] = e(
			SideButton,
			{
				layoutOrder = sideButton.LayoutOrder,
				icon = sideButton.Image,
				buttonPath = name,
				zIndex = sideButton.LayoutOrder,
				size = UDim2.fromOffset(78, 78),
				gradient = sideButton.Gradient,
				opacity = sideButton.Opacity,
			} :: any
		)
	end

	if tradeState.showTradeSideButton then
		sideButtonElements["ActiveTrade"] = e(
			SideButton,
			{
				layoutOrder = 100, -- keep this at the end
				icon = "rbxassetid://18420762649",
				buttonPath = "ActiveTrade",
				zIndex = 100,
				size = UDim2.fromOffset(78, 78),
				-- do a violet purple to darker purple gradient
				gradient = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 128)),
				}),
				tooltipName = "Current Trade",
			} :: any
		)
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = styles.position,
		Size = UDim2.fromOffset(99, 608),
	}, {
		listLayout = e("UIListLayout", {
			Padding = UDim.new(0, 15),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		buttons = e(React.Fragment, nil, sideButtonElements),
	})
end

return React.memo(SideButtonHUD)
