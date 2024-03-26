--!strict

-- Automatic Scrolling Frame
-- March 4th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hooks = ReplicatedStorage.hooks
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local React = require(Packages.React)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)
local useHookWithRefCallback = require(Hooks.useHookWithRefCallback)
local useScaleRatio = require(Hooks.useScaleRatio)

local e = React.createElement
local useCallback = React.useCallback
local useEffect = React.useEffect

type AutomaticScrollingFrameProps = Types.FrameProps & {
	onScroll: () -> (),
	bottomImage: string,
	topImage: string,
	scrollingDirection: Enum.ScrollingDirection,
	scrollBarThickness: number,
	selectable: boolean,
	canvasPosition: UDim2,
	scrollBarImageColor3: Color3,
	scrollBarImageTransparency: number,
	selectionGroup: boolean?,
	children: { React.ReactElement<any, any> },
}

local defaultProps = {
	anchorPoint = Vector2.new(0.5, 0.5),
	backgroundTransparency = 1,
	scrollBarImageTransparency = 0,
	borderSizePixel = 0,
	topImage = "rbxasset://textures/ui/Scroll/scroll-top.png",
	bottomImage = "rbxasset://textures/ui/Scroll/scroll-bottom.png",
}

-- // Automatic Scrolling Frame \\

local function AutomaticScrollingFrame(props: AutomaticScrollingFrameProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local scrollingFrameRef, assignScrollingFrameRef = useHookWithRefCallback()
	local scaleRatio = useScaleRatio()

	local resizeCanvas = useCallback(function(scrollLayout: UIGridStyleLayout, scrollingFrame: ScrollingFrame)
		local absoluteContentSizeY = 0
		local absoluteContentSizeX = 0
		local uiPadding = scrollingFrame:FindFirstChildOfClass("UIPadding")
		if scrollLayout:IsA("UIGridLayout") then
			absoluteContentSizeY = scrollLayout.AbsoluteCellCount.Y * scrollLayout.AbsoluteCellSize.Y
			absoluteContentSizeY += scrollLayout.AbsoluteCellCount.Y * scrollLayout.CellPadding.Y.Offset
			absoluteContentSizeX = scrollLayout.AbsoluteCellCount.X * scrollLayout.AbsoluteCellSize.X
		elseif scrollLayout:IsA("UIListLayout") then
			local frameElements = 0
			local fillDirection = scrollLayout.FillDirection
			for _, child in scrollingFrame:GetChildren() do
				if child:IsA("GuiObject") then
					if fillDirection == Enum.FillDirection.Vertical then
						absoluteContentSizeY += child.Size.Y.Offset
					else
						absoluteContentSizeX += child.Size.X.Offset
					end
					frameElements += 1
				end
			end
			if fillDirection == Enum.FillDirection.Vertical then
				absoluteContentSizeY += frameElements * scrollLayout.Padding.Offset
			else
				absoluteContentSizeX += frameElements * scrollLayout.Padding.Offset
			end
		end
		if uiPadding then
			absoluteContentSizeY = absoluteContentSizeY
				+ ((uiPadding.PaddingTop.Offset / scaleRatio) + uiPadding.PaddingBottom.Offset / scaleRatio)
			absoluteContentSizeX = absoluteContentSizeX
				+ ((uiPadding.PaddingLeft.Offset / scaleRatio) + (uiPadding.PaddingRight.Offset / scaleRatio))
		end
		scrollingFrame.CanvasSize = UDim2.fromOffset(absoluteContentSizeX, absoluteContentSizeY)
	end, { scaleRatio })

	local attemptResize = useCallback(function(rbx: ScrollingFrame)
		local scrollLayout = rbx:FindFirstChildWhichIsA("UIGridStyleLayout")
		if not rbx:IsDescendantOf(game) or not scrollLayout then
			return
		else
			resizeCanvas(scrollLayout, rbx)
		end
	end, { resizeCanvas })

	useEffect(function()
		if scrollingFrameRef.current then
			local scrollingFrame = scrollingFrameRef.current
			if not scrollingFrame then
				return
			end
			local scrollLayout = scrollingFrame:FindFirstChildWhichIsA("UIGridStyleLayout")
			assert(scrollLayout, "AutomaticScrollingFrame: UIGridStyleLayout not found")
			local sizeChanged = scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				resizeCanvas(scrollLayout, scrollingFrame)
			end)
			resizeCanvas(scrollLayout, scrollingFrame)
			return function()
				sizeChanged:Disconnect()
			end
		end
		return function() end
	end, { resizeCanvas, scrollingFrameRef })
	return e("ScrollingFrame", {
		ref = assignScrollingFrameRef,
		[React.Change.AbsoluteWindowSize] = attemptResize,
		[React.Event.AncestryChanged] = attemptResize,
		[React.Event.ChildAdded] = attemptResize,
		[React.Event.ChildRemoved] = attemptResize,
		[React.Change.AbsoluteSize] = attemptResize,
		[React.Change.CanvasPosition] = props.onScroll,
		AnchorPoint = props.anchorPoint,
		Active = props.active,
		Size = props.size,
		Visible = props.visible,
		Position = props.position,
		BackgroundTransparency = props.backgroundTransparency,
		BottomImage = props.bottomImage,
		TopImage = props.topImage,
		ScrollBarThickness = props.scrollBarThickness,
		BackgroundColor3 = props.backgroundColor3,
		BorderSizePixel = props.borderSizePixel,
		Selectable = props.selectable,
		SelectionGroup = props.selectionGroup,
		ScrollBarImageColor3 = props.scrollBarImageColor3,
		ScrollingDirection = props.scrollingDirection,
		ClipsDescendants = props.clipsDescendants,
		ZIndex = props.zIndex,
		CanvasPosition = props.canvasPosition,
		LayoutOrder = props.layoutOrder,
		ScrollBarImageTransparency = props.scrollBarImageTransparency,
	}, props.children :: any)
end

return React.memo(AutomaticScrollingFrame)
