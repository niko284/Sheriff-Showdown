--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils
local Contexts = ReplicatedStorage.react.contexts

local DependencyArray = require(Utils.DependencyArray)
local Janitor = require(Packages.Janitor)
local React = require(Packages.React)
local ScaleContext = require(Contexts.ScaleContext)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local e = React.createElement
local useBinding = React.useBinding
local useRef = React.useRef
local useCallback = React.useCallback
local useContext = React.useContext
local useEffect = React.useEffect

-- // Automatic Frame \\

--[[
	MIT License

	Copyright (c) 2021 Eryn L. K.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

type AutomaticFrameProps = Types.FrameProps & {
	automaticSize: EnumItem?,
	maxSize: Vector2,
	textToRead: string?,
	minSize: Vector2,
	instanceProps: { [string]: any },
	className: string,
	children: { any },
}

local defaultProps = {
	className = "Frame",
	maxSize = Vector2.new(math.huge, math.huge),
	minSize = Vector2.new(0, 0),
	automaticSize = Enum.AutomaticSize.XY,
}

local function AutomaticFrame(props: AutomaticFrameProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local frameRef = useRef(React.createRef())
	local janitor = useRef(Janitor.new() :: Janitor.Janitor)
	local containerSize, setContainerSize = useBinding(props.instanceProps.Size)
	local scaleRatio = useContext(ScaleContext)

	print(scaleRatio)

	local resizeFrame = useCallback(
		function(container: GuiObject, layout: UIGridStyleLayout)
			local axis = props.automaticSize or Enum.AutomaticSize.XY
			local maxSize = props.maxSize or Vector2.new(math.huge, math.huge)
			local minSize = props.minSize
			if typeof(maxSize) == "UDim2" then
				if container.Parent == nil then
					maxSize = Vector2.new(0, 0)
				else
					local parent = container.Parent :: GuiObject
					local parentSize = parent.AbsoluteSize
					maxSize = Vector2.new(
						(parentSize.X / maxSize.X.Scale) + maxSize.X.Offset,
						(parentSize.Y / maxSize.Y.Scale) + maxSize.Y.Offset
					)
				end
			end

			local paddingX = 0
			local paddingY = 0

			local padding: UIPadding? = container:FindFirstChildOfClass("UIPadding")
			if padding then
				paddingX = padding.PaddingLeft.Offset + padding.PaddingRight.Offset
				paddingY = padding.PaddingTop.Offset + padding.PaddingBottom.Offset
			end

			local contentSize

			if layout then
				local absoluteContentSizeY = 0
				local absoluteContentSizeX = 0
				if layout:IsA("UIGridLayout") then
					absoluteContentSizeY = layout.AbsoluteCellCount.Y * layout.AbsoluteCellSize.Y
					absoluteContentSizeY += layout.AbsoluteCellCount.Y * layout.CellPadding.Y.Offset
					absoluteContentSizeX = layout.AbsoluteCellCount.X * layout.AbsoluteCellSize.X
				elseif layout:IsA("UIListLayout") then
					local frameElements = 0
					local fillDirection = layout.FillDirection
					for _, child in pairs(container:GetChildren()) do
						if child:IsA("GuiObject") then
							if fillDirection == Enum.FillDirection.Vertical then
								absoluteContentSizeY += child.Size.Y.Offset
								absoluteContentSizeX = math.max(absoluteContentSizeX, child.Size.X.Offset)
							else
								absoluteContentSizeX += child.Size.X.Offset
								absoluteContentSizeY = math.max(absoluteContentSizeY, child.Size.Y.Offset)
							end
							frameElements += 1
						end
					end
					if fillDirection == Enum.FillDirection.Vertical and frameElements > 1 then
						absoluteContentSizeY += (frameElements - 1) * layout.Padding.Offset
					elseif frameElements > 1 then
						absoluteContentSizeX += (frameElements - 1) * layout.Padding.Offset
					end
				end
				contentSize = Vector2.new(absoluteContentSizeX, absoluteContentSizeY)
			elseif container:IsA("TextButton") or container:IsA("TextLabel") then
				if typeof(props.maxSize) ~= "Vector2" then
					return
				else
					local maxTextSize =
						Vector2.new(math.min(props.maxSize.X, math.huge), math.min(props.maxSize.Y, math.huge))
					contentSize = TextService:GetTextSize(
						props.textToRead or props.instanceProps.Text,
						props.instanceProps.TextSize,
						container.Font,
						maxTextSize
					) + Vector2.new(2, 2)
				end
			else
				contentSize = Vector2.new(0, 0)

				for _, child in container:GetChildren() do
					if child:IsA("GuiObject") then
						local farX = (child.Position.X.Offset + child.Size.X.Offset)
							- (child.Size.X.Offset * child.AnchorPoint.X)
						local farY = (child.Position.Y.Offset + child.Size.Y.Offset)
							- (child.Size.Y.Offset * child.AnchorPoint.Y)
						contentSize = Vector2.new(math.max(contentSize.X, farX), math.max(contentSize.Y, farY))
					end
				end
			end

			local baseX = math.max(contentSize.X + paddingX, minSize.X)
			local baseY = math.max(contentSize.Y + paddingY, minSize.Y)
			local xClamped: UDim, yClamped: UDim

			if axis == Enum.AutomaticSize.XY then
				xClamped = UDim.new(0, math.min(baseX, maxSize.X))
				yClamped = UDim.new(0, math.min(baseY, maxSize.Y))
			elseif axis == Enum.AutomaticSize.X then
				xClamped = UDim.new(0, math.min(baseX, maxSize.X))
				yClamped = container.Size.Y
			else
				xClamped = container.Size.X
				yClamped = UDim.new(0, math.min(baseY, maxSize.Y))
			end
			setContainerSize(UDim2.new(xClamped, yClamped))
		end,
		DependencyArray(
			props.automaticSize,
			setContainerSize,
			props.instanceProps,
			props.minSize,
			props.maxSize,
			scaleRatio,
			props.textToRead
		) :: { any }
	)

	useEffect(function()
		if not frameRef.current then
			return
		else
			local frame = frameRef.current.current
			assert(frame, "Frame ref is nil")
			assert(janitor.current, "Janitor is nil")
			local layout = frame:FindFirstChildWhichIsA("UIGridStyleLayout")
			if layout then
				janitor.current:Add(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					resizeFrame(frame, layout)
				end))
			end
			if frame.Parent and frame.Parent:IsA("Frame") and layout then
				janitor.current:Add(frame.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					resizeFrame(frame, layout)
				end))
			end
			if frame:IsA("TextButton") or frame:IsA("TextLabel") and layout then
				janitor.current:Add(frame:GetPropertyChangedSignal("TextBounds"):Connect(function()
					resizeFrame(frame, layout)
				end))
			end
			resizeFrame(frame, frame:FindFirstChildWhichIsA("UIGridStyleLayout")) -- Resize frame on initial render.
			return function()
				janitor.current:Cleanup()
			end
		end
	end, { frameRef, resizeFrame, janitor } :: { any })

	return e(
		props.className,
		Sift.Dictionary.merge(props.instanceProps, {
			ref = frameRef.current,
			[React.Event.AncestryChanged] = function(rbx) -- When the parent changes, resize the frame.
				local scrollLayout = rbx:FindFirstChildWhichIsA("UIGridStyleLayout") -- Pass the layout, if there is one.
				if not scrollLayout then
					return
				end
				resizeFrame(rbx, scrollLayout :: UIGridStyleLayout)
			end,
			Size = containerSize,
		}),
		props.children
	)
end

return React.memo(AutomaticFrame)
