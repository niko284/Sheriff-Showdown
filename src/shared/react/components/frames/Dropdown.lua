--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local ReactSpring = require(Packages.ReactSpring)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local e = React.createElement
local useState = React.useState

local DefaultDropdownProps = {
	backgroundColor3 = Color3.fromRGB(57, 57, 57),
	backgroundTransparency = 0,
	textColor3 = Color3.fromRGB(255, 255, 255),
	strokeColor = Color3.fromRGB(112, 112, 112),
	strokeThickness = 1.4,
	applyStrokeMode = Enum.ApplyStrokeMode.Border,
	cornerRadius = UDim.new(1, 0),
	textSize = 16,
	fontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
}

type DropdownProps = Types.FrameProps & {
	thickness: number?,
	spacingY: number?,
	buttonSizeY: number,
	buttonSizeX: number,
	paddingTop: number,
	selections: { string },
	selectionElement: any,
	onSelection: (selection: string) -> (),
	currentSelection: string,
	onToggle: (isOpen: boolean) -> (),
}

local function Dropdown(props: DropdownProps)
	local selectionsVisible, setSelectionsVisible = useState(false)

	local filteredSelections = Sift.Array.removeValue(props.selections, props.currentSelection)

	-- Create springs for the buttons
	local springProps = {}
	for index, _selection in filteredSelections do
		local thickness = props.thickness or DefaultDropdownProps.strokeThickness
		local spacing = props.spacingY or 0
		springProps[index] = {
			position = selectionsVisible and UDim2.fromOffset(0, index * (props.buttonSizeY + spacing + thickness))
				or UDim2.fromScale(0, 0),
			delay = 0,
			config = {
				duration = 0.2,
			},
		}
	end
	local springs = ReactSpring.useTrail(#filteredSelections, springProps)

	local currentStyles = ReactSpring.useSpring({
		backgroundColor = selectionsVisible and Color3.fromRGB(140, 140, 140) or DefaultDropdownProps.backgroundColor3,
		config = {
			duration = 0.2,
		},
	}, { selectionsVisible })

	-- Create the selection buttons

	local selectionElements = {}
	for index, selection in filteredSelections do
		selectionElements[index] = e(
			props.selectionElement,
			Sift.Dictionary.merge(DefaultDropdownProps, {
				text = selection,
				key = selection,
				position = springs[index].position,
				onActivated = function()
					if props.onSelection and typeof(props.onSelection) == "function" then
						setSelectionsVisible(false)
						props.onSelection(selection)
					end
				end,
				size = UDim2.fromOffset(props.buttonSizeX, props.buttonSizeY),
				zIndex = 1,
			})
		)
	end

	local selection = nil

	if props.currentSelection then
		selection = e(
			props.selectionElement,
			Sift.Dictionary.merge(DefaultDropdownProps, {
				text = props.currentSelection,
				size = UDim2.fromOffset(props.buttonSizeX, props.buttonSizeY),
				onActivated = function()
					if props.onToggle and typeof(props.onToggle) == "function" then
						task.spawn(function()
							if (not selectionsVisible) == false then
								task.wait(0.2)
							end
							props.onToggle(not selectionsVisible) -- Then we can set the zindex back to 1 again, so the elements don't fall behind the dropdowns during the animation
						end)
					end
					setSelectionsVisible(function(visible)
						return not visible
					end)
				end,
				backgroundColor = currentStyles.backgroundColor,
				zIndex = 5,
			})
		)
	end

	return e("Frame", {
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		Position = props.position,
		Size = UDim2.fromOffset(props.buttonSizeX, props.buttonSizeY * #filteredSelections + props.paddingTop),
	}, {
		padding = e("UIPadding", {
			PaddingTop = UDim.new(0, props.paddingTop),
		}),
		selectionFrames = React.createElement(React.Fragment, nil, selectionElements),
		currentFrame = selection,
	})
end

return Dropdown
