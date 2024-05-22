--!strict
-- Transition Row
-- March 31st, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Signal = require(Packages.Signal)

local useEffect = React.useEffect
local e = React.createElement
local useState = React.useState

-- // Transition Row \\

type TransitionRowProps = {
	shapeIcon: number,
	amount: number,
	row: number,
	toggleSignal: Signal.Signal<{ { row: number, column: number } }>,
}

local function TransitionRow(props: TransitionRowProps)
	local rowShapeElements = {}

	local shapeSpringProps = {}

	local shapeToggles, setShapeToggles = useState(function()
		local toggles = {}

		for i = 1, props.amount do
			toggles[i] = false
		end

		return toggles
	end)

	for i = 1, props.amount do
		table.insert(shapeSpringProps, {
			size = if shapeToggles[i] == true then UDim2.fromScale(2, 2) else UDim2.fromScale(0, 0),
			config = { duration = 0.1 },
		})
	end

	local springs = ReactSpring.useSprings(props.amount, shapeSpringProps)

	for i = 1, props.amount do
		table.insert(
			rowShapeElements,
			e("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Size = UDim2.fromScale(0.1, 1),
				key = i,
			}, {
				shapeIcon = e("ImageLabel", {
					Image = string.format("rbxassetid://%d", props.shapeIcon),
					ImageColor3 = Color3.fromRGB(0, 0, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = springs[i].size,
					Position = UDim2.fromScale(0.5, 0.5),
				}),
			})
		)
	end

	useEffect(function()
		local connection = props.toggleSignal:Connect(function(cells: { { row: number, column: number } })
			setShapeToggles(function(oldToggles)
				local toggles = table.clone(oldToggles)
				for _, cell in cells do
					if cell.row == props.row then
						toggles[cell.column] = not toggles[cell.column]
					end
				end
				return toggles
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, { setShapeToggles, props.toggleSignal, props.row } :: { any })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0.143),
	}, {
		listLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		shapes = React.createElement(React.Fragment, nil, rowShapeElements),
	})
end

return TransitionRow
