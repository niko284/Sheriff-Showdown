--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local e = React.createElement
local useBinding = React.useBinding
local useEffect = React.useEffect
local useCallback = React.useCallback
local useRef = React.useRef

local function map(number: number, input_start: number, input_end: number, output_start: number, output_end: number)
	return output_start + ((output_end - output_start) * (number - input_start)) / (input_end - input_start)
end

local function getPiecewiseInput(mapped_time)
	if 0 < mapped_time and mapped_time < 4 * math.pi / 3 then
		return mapped_time * 0.75
	else
		return mapped_time * 1.5 + math.pi
	end
end

type RadialDotProps = Types.FrameProps & {
	transparency: React.Binding<{number}>,
	index: number,
	dotColor: Color3,
	dotImage: string?,
	position: React.Binding<{UDim2}>,
}

local function RadialDot(props: RadialDotProps): React.ReactElement<any, any>
	return e("Frame", {
		Size = props.size,
		BackgroundColor3 = props.dotColor,
		Position = props.position:map(function(positions: { UDim2 })
			return positions[props.index]
		end),
		BackgroundTransparency = not props.dotImage and props.transparency:map(function(transparency: { number })
			return transparency[props.index]
		end) or 1,
	}, {
		uiCorner = e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		dotImage = props.dotImage and e("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = props.dotImage,
			ImageTransparency = props.transparency:map(function(transparency: { number })
				return transparency[props.index]
			end),
		}),
	})
end

type RadialLoadingProps = Types.FrameProps & {
	spacing: number,
	radius: number,
	dots: number,
	dotSize: UDim2,
	dotColor: Color3,
	dotImage: string?,
	timeToCycle: number,
	position: UDim2,
}

local defaultProps = {
	radius = 0.5,
	dots = 8,
	dotSize = UDim2.fromScale(0.02, 0.02),
	timeToCycle = 1.2,
	spacing = 14,
}

local function RadialLoading(props: RadialLoadingProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local dotPositions, setPosition = useBinding({})
	local dotTransparencies, setDotTransparencies = useBinding({})
	local cycleTime = useRef(0)

	local getPositionFromTime = useCallback(function(mappedTime: number, index: number)
		-- Get spacing between dots based on number of dots
		local r = getPiecewiseInput((mappedTime + index * math.rad(props.spacing) * 2) % (math.pi * 2))
		local x = math.cos(r) * props.radius
		local y = math.sin(r) * props.radius
		return UDim2.fromOffset(x, y)
	end, { props.radius })

	-- Let's create our dots.
	local radialDots = Sift.Array.create(props.dots, function(index: number)
		local angle = (index / props.dots) * math.pi * 2
		local x = math.cos(angle) * props.radius
		local y = math.cos(angle) * props.radius
		local oldPositions = dotPositions:getValue()
		local oldTransparencies = dotTransparencies:getValue()
		oldPositions[index] = UDim2.new(0, x, 0, y)
		oldTransparencies[index] = 0
		setPosition(oldPositions)
		setDotTransparencies(oldTransparencies)
		return e(RadialDot, {
			key = index,
			position = dotPositions,
			size = props.dotSize,
			dotColor = props.dotColor,
			dotImage = props.dotImage,
			index = index,
			transparency = dotTransparencies,
		} :: any)
	end)

	useEffect(function()
		-- Get the position of each dot in the circle based on the time.
		local runLoader = RunService.RenderStepped:Connect(function(deltaTime: number)
			cycleTime.current = (cycleTime.current and cycleTime.current + deltaTime or 0) % props.timeToCycle
			local mappedTime = map(cycleTime.current or 0, 0, props.timeToCycle, 0, 2 * math.pi)
			local oldPositions = dotPositions:getValue()
			local oldTransparencies = dotTransparencies:getValue()
			for index = 1, props.dots do
				local pos = getPositionFromTime(mappedTime, index)
				oldPositions[index] = pos
				oldTransparencies[index] = map((pos.Y.Offset / props.radius), 0, 1, 0, 1)
				setDotTransparencies(oldTransparencies)
				setPosition(oldPositions)
			end
		end)
		return function()
			runLoader:Disconnect()
		end
	end, { setPosition, cycleTime, getPositionFromTime } :: { any })

	return e("Frame", {
		BackgroundTransparency = 1,
		Size = props.size,
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		ZIndex = props.zIndex,
	}, {
		radialDots = React.createElement(
			React.Fragment,
			nil,
			Sift.Array.map(radialDots, function(createDot: (number) -> any, index: number)
				return createDot(index)
			end)
		),
	})
end

return RadialLoading