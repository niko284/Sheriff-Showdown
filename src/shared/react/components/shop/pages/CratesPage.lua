--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CrateContentsPage = require(Components.shop.pages.CrateContentsPage)
local CrateTemplate = require(Components.shop.crates.CrateTemplate)
local Crates = require(ReplicatedStorage.constants.Crates)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useEffect = React.useEffect

type CratePageProps = Types.FrameProps & {
	pageRef: (ref: Frame) -> (),
	switchToCategory: (category: string) -> (),
}

local function CratePage(props: CratePageProps)
	local crateToView, setCrateToView = useState(nil :: Types.Crate?)
	local pageLayoutRef = useRef(nil :: UIPageLayout?)

	local crateElements = {}
	for crateName, crateInfo in Crates do
		crateElements[crateName] = e(CrateTemplate, {
			crateImage = string.format("rbxassetid://%d", crateInfo.ShopImage),
			crateName = crateName,
			crateDescription = string.format("Contains %d items", #crateInfo.ItemContents),
			rotationTime = 1,
			amountOfPreviewItems = 4,
			size = UDim2.fromOffset(254, 339),
			onViewContents = function()
				setCrateToView(crateName)
			end,
		})
	end

	useEffect(function()
		if pageLayoutRef.current then
			pageLayoutRef.current:JumpToIndex(crateToView and 2 or 1)
		end
	end, { crateToView })

	return e("Frame", {
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.fromScale(1, 1.03),
		ref = function(rbx: Frame)
			props.pageRef(rbx)
		end,
		LayoutOrder = props.layoutOrder,
	}, {

		pageLayout = e("UIPageLayout", {
			Circular = true,
			ref = pageLayoutRef,
			SortOrder = Enum.SortOrder.LayoutOrder,
			ScrollWheelInputEnabled = false,
			TouchInputEnabled = false,
			GamepadInputEnabled = false,
			EasingDirection = Enum.EasingDirection.InOut,
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			TweenTime = 0.2,
			EasingStyle = Enum.EasingStyle.Quad,
		}),

		cratePurchasePage = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 1),
		}, {
			crates = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Crates",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 19),
				Size = UDim2.fromOffset(54, 13),
			}),

			cratesList = e(AutomaticScrollingFrame, {
				scrollBarThickness = 5,
				scrollingDirection = Enum.ScrollingDirection.X,
				active = true,
				backgroundTransparency = 1,
				anchorPoint = Vector2.new(0, 0),
				borderSizePixel = 0,
				position = UDim2.fromScale(0.00723, 0.104),
				size = UDim2.fromOffset(806, 356),
			}, {
				listLayout = e("UIListLayout", {
					Padding = UDim.new(0, 16),
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),

				padding = e("UIPadding", {
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 7),
				}),

				crates = e(React.Fragment, nil, crateElements :: any),
			}),
		}),

		crateContents = e(CrateContentsPage, {
			crateName = crateToView,
			layoutOrder = 1,
			onBack = setCrateToView,
		}),
	})
end

return React.memo(CratePage)
