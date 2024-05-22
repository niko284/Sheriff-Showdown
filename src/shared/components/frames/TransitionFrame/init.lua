--!strict
-- Transition Frame
-- March 31st, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components
local FrameComponents = Components.frames

local React = require(Packages.React)
local Signal = require(Packages.Signal)
local TransitionRow = require(FrameComponents.TransitionFrame.TransitionRow)
local Types = require(Constants.Types)

local e = React.createElement
local useEffect = React.useEffect
local useMemo = React.useMemo

type TransitionFrameProps = Types.FrameProps & {
	rows: number,
	columns: number,
	shapeIcon: number,
	activateSignal: Signal.Signal<number>,
}

-- // TransitionFrame Component \\

local function TransitionFrame(props: TransitionFrameProps)
	local toggleSignal = useMemo(function()
		return Signal.new()
	end, {}) :: Signal.Signal<{ { row: number, column: number } }>

	local rowElements = {}
	for i = 1, props.rows do
		table.insert(
			rowElements,
			e(TransitionRow, {
				key = i,
				amount = props.columns,
				shapeIcon = props.shapeIcon,
				row = i,
				toggleSignal = toggleSignal,
			})
		)
	end

	useEffect(function()
		local function onActivate(transitionDuration: number)
			task.spawn(function()
				for _toggle = 1, 2 do -- we need to toggle twice to get the cells to size up and then size back to zero.
					for i = 1, props.rows do
						for j = 1, props.columns do
							if i == 1 or j == props.columns then
								local row = i
								local column = j
								local diagonalCells = {}
								while row < props.rows and column > 1 do
									table.insert(diagonalCells, { row = row + 1, column = column - 1 })
									row = row + 1
									column = column - 1
								end
								table.insert(diagonalCells, { row = i, column = j })
								toggleSignal:Fire(diagonalCells)
								task.wait(0.06)
							end
						end
					end
					task.wait(transitionDuration) -- re-toggle the cells so they size back to zero.
				end
			end)
		end

		local connection = props.activateSignal:Connect(onActivate)

		return function()
			connection:Disconnect()
		end
	end, { toggleSignal, props.activateSignal, props.rows, props.columns } :: { any })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, {
		listLayout = e("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		rows = React.createElement(React.Fragment, nil, rowElements),
	})
end

return TransitionFrame
