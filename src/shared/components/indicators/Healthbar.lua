--!strict

-- Healthbar
-- June 11th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils
local Vendor = ReplicatedStorage.vendor

local DependencyArray = require(Utils.DependencyArray)
local FormatNumber = require(Vendor.FormatNumber)
local React = require(Packages.React)
local Sift = require(Packages.Sift)
local StatisticBar = require(Components.indicators.StatisticBar)
local Types = require(Constants.Types)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useEffect = React.useEffect
local useMemo = React.useMemo

local NumberFormatter = FormatNumber.NumberFormatter

local HEALTH_ABBREVIATIONS = FormatNumber.Notation.compactWithSuffixThousands({
	"K",
	"M",
	"B",
	"T",
})

type HealthbarProps = Types.FrameProps & {
	humanoid: Humanoid?,
	statisticName: string?,
	minColor: Color3?,
	showPercentage: boolean?,
	shouldFormat: boolean?,
	maxColor: Color3?,
	statisticIcon: string?,
	percentageTextAlignment: Enum.TextXAlignment?,
	backgroundColor: Color3,
	children: { any }?,
	healthLines: number?,
}

local defaultProps = {
	maxColor = Color3.fromRGB(55, 255, 25),
	minColor = Color3.fromRGB(255, 25, 25),
	showPercentage = true,
}

-- // Healthbar \\

local function Healthbar(props: HealthbarProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local healthFormatter = useRef(
		NumberFormatter.with()
			:Notation(HEALTH_ABBREVIATIONS)
			:Precision(FormatNumber.Precision.integer():WithMinDigits(4))
	)

	local currentHealth, setCurrentHealth = useState(function()
		return if props.humanoid then props.humanoid.Health else nil
	end)
	local maxHealth, setMaxHealth = useState(function()
		return if props.humanoid then props.humanoid.MaxHealth else nil
	end)

	useEffect(function()
		local healthChanged = nil
		local maxHealthChanged = nil
		if props.humanoid then
			healthChanged = props.humanoid:GetPropertyChangedSignal("Health"):Connect(function()
				setCurrentHealth(props.humanoid.Health)
			end)
			maxHealthChanged = props.humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
				setMaxHealth(props.humanoid.MaxHealth)
			end)
		end
		-- Disconnect the events when the component is unmounted
		return function()
			if healthChanged then
				healthChanged:Disconnect()
			end
			if maxHealthChanged then
				maxHealthChanged:Disconnect()
			end
		end
	end, DependencyArray(props.humanoid, setMaxHealth, setCurrentHealth) :: { any })

	-- Create healthbar line elements. We can memoize this for performance, and only re-calculate when #healthLines change.

	local lineElements = useMemo(function()
		local lines = {}
		for _i = 1, (props.healthLines or 5) do
			table.insert(
				lines,
				e("Frame", {
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.8,
					BorderSizePixel = 0,
					key = _i,
					ZIndex = 3,
					Size = UDim2.fromScale(0.0035, 1),
				})
			)
		end
		return lines
	end, { props.healthLines }) :: any

	return e(
		StatisticBar,
		{
			statisticName = props.statisticName,
			value = currentHealth,
			maxValue = maxHealth,
			formatter = props.shouldFormat == true and healthFormatter.current or nil,
			percentageTextAlignment = props.percentageTextAlignment,
			barColor = currentHealth
				and maxHealth
				and (props.minColor :: Color3):Lerp(props.maxColor :: Color3, currentHealth / maxHealth),
			statisticIcon = props.statisticIcon or "",
			round = true,
			size = props.size,
			showPercentage = props.showPercentage,
			layoutOrder = props.layoutOrder,
			backgroundColor = props.backgroundColor,
			position = props.position,
			anchorPoint = props.anchorPoint,
		} :: any,
		Sift.Dictionary.join({
			lineList = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 0.5),
				ZIndex = 3,
			}, {
				listLayout = e("UIListLayout", {
					Padding = UDim.new(0.325, 0),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				lineGroup = React.createElement(React.Fragment, nil, lineElements),
			}),
		}, props.children or {})
	)
end

return Healthbar
