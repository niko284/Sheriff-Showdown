--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local Slide = require(script.Slide)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useEffect = React.useEffect

type SlideData = {
	icon: string,
	slideName: string,
	price: number,
	key: string,
	description: string,
}
type SlideshowFrameProps = Types.FrameProps & {
	slides: { SlideData },
}

local function Slideshow(props: SlideshowFrameProps)
	local currentSlide, setCurrentSlide = useState(1)
	local slideRefs = useRef({}) :: { current: { [number]: GuiObject } }
	local pageLayoutRef = useRef(nil :: UIPageLayout?)

	local slideElements = {}
	for index, slideData in ipairs(props.slides) do
		slideElements[index] = e(Slide, {
			key = slideData.key,
			icon = slideData.icon,
			description = slideData.description,
			slideName = slideData.slideName,
			price = slideData.price,
			slideRef = function(ref)
				slideRefs.current[index] = ref
			end,
			layoutOrder = index,
		})
	end

	local dotElements = {}
	for index, _ in ipairs(props.slides) do
		dotElements[index] = e("ImageButton", {
			BackgroundColor3 = if currentSlide == index
				then Color3.fromRGB(255, 255, 255)
				else Color3.fromRGB(148, 148, 148),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Image = "",
			Position = UDim2.fromOffset(98, 313),
			Size = UDim2.fromOffset(12, 12),
			[React.Event.Activated] = function()
				setCurrentSlide(index)
			end,
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		})
	end

	useEffect(function()
		local slideInstance = slideRefs.current[currentSlide]
		local pageLayout = pageLayoutRef.current

		if pageLayout and slideInstance then
			pageLayout:JumpTo(slideInstance)
		end

		return function() end
	end, { currentSlide })

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = props.position,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		gradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(72, 72, 72)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(72, 72, 72)),
			}),
			Rotation = 90,
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
		}),

		panels = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(251, 286),
		}, {
			pageLayout = e("UIPageLayout", {
				EasingDirection = Enum.EasingDirection.InOut,
				TweenTime = 0.2,
				EasingStyle = Enum.EasingStyle.Quad,
				SortOrder = Enum.SortOrder.LayoutOrder,
				ref = pageLayoutRef,
				[React.Change.CurrentPage] = function(pageLayout: UIPageLayout)
					-- set current slide to this page (find the index of the slide)
					for index, slide in ipairs(slideRefs.current) do
						if slide == pageLayout.CurrentPage then
							setCurrentSlide(index)
						end
					end
				end,
			}),
			slides = e(React.Fragment, nil, slideElements),
		}),

		separator = e(Separator, {
			position = UDim2.fromOffset(20, 296),
			size = UDim2.fromOffset(212, 3),
		}),

		dotList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.143, 0.926),
			Size = UDim2.fromOffset(179, 14),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 6),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			dots = e(React.Fragment, nil, dotElements),
		}),
	})
end

return React.memo(Slideshow)
