--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Controllers = Players.LocalPlayer.PlayerScripts.controllers

local Button = require(Components.buttons.Button)
local CloseButton = require(Components.buttons.CloseButton)
local CrateContentsPage = require(Components.shop.pages.CrateContentsPage)
local CratesPage = require(Components.shop.pages.CratesPage)
local CurrencyHolder = require(Components.shop.CurrencyHolder)
local FeaturedPage = require(Components.shop.pages.FeaturedPage)
local InterfaceController = require(Controllers.InterfaceController)
local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local animateCurrentInterface = require(ReplicatedStorage.react.hooks.animateCurrentInterface)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useEffect = React.useEffect

local SHOP_CATEGORIES = {
	Home = {
		Element = FeaturedPage,
		LayoutOrder = 1,
	},
	Crates = {
		Element = CratesPage,
		LayoutOrder = 2,
	},
	CrateContents = {
		Element = CrateContentsPage,
	},
} :: { [ShopCategory]: ShopCategoryData }

type ShopCategory = "Home" | "Crates" | "Currency" | "Gamepass"
type ShopCategoryData = {
	Element: any,
	LayoutOrder: number,
}
type ShopProps = {}

local function Shop(_props: ShopProps)
	local currentCategory, setCurrentCategory = useState("Home" :: ShopCategory)
	local pageRefs = useRef({}) :: { current: { [ShopCategory]: any } }
	local pageLayoutRef = useRef(nil :: UIPageLayout?)

	local _shouldRender, styles = animateCurrentInterface("Shop", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local categoryButtonElements = {} :: { [string]: any }
	for categoryName, _ in pairs(SHOP_CATEGORIES) do
		categoryButtonElements[categoryName] = e(Button, {
			text = categoryName,
			textColor3 = if currentCategory == categoryName
				then Color3.fromRGB(255, 255, 255)
				else Color3.fromRGB(30, 30, 30),
			gradient = if currentCategory == categoryName
				then ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(134, 134, 134)),
					ColorSequenceKeypoint.new(0.0328, Color3.fromRGB(172, 172, 172)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				})
				else ColorSequence.new(Color3.fromRGB(255, 255, 255)),
			backgroundColor3 = if currentCategory == categoryName
				then Color3.fromRGB(72, 72, 72)
				else Color3.fromRGB(255, 255, 255),
			cornerRadius = UDim.new(0, 5),
			textSize = 16,
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			strokeThickness = 0.5,
			size = UDim2.fromOffset(105, 42),
			gradientRotation = -90,
			onActivated = function()
				setCurrentCategory(categoryName)
			end,
		})
	end

	local pageElements = {} :: { [string]: any }

	for categoryName, categoryData in pairs(SHOP_CATEGORIES) do
		pageElements[categoryName] = e(categoryData.Element, {
			layoutOrder = categoryData.LayoutOrder,
			pageRef = function(ref)
				pageRefs.current[categoryName :: ShopCategory] = ref
			end,
			switchToCategory = setCurrentCategory,
		})
	end

	useEffect(function()
		local pageLayoutInstance = pageLayoutRef.current
		if pageLayoutInstance and pageRefs.current[currentCategory] then
			pageLayoutInstance:JumpTo(pageRefs.current[currentCategory])
		end
	end, { currentCategory })

	return e("ImageLabel", {
		Image = "rbxassetid://18134622325",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(848, 608),
	}, {
		separator = e(Separator, {
			image = "rbxassetid://18134633176",
			position = UDim2.fromOffset(26, 188),
			size = UDim2.fromOffset(797, 3),
		}),

		giftButton = e("ImageLabel", {
			Image = "rbxassetid://18134646407",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(782, 119),
			Size = UDim2.fromOffset(42, 42),
		}, {
			giftIcon = e("ImageLabel", {
				Image = "rbxassetid://18134657918",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(9, 9),
				Size = UDim2.fromOffset(23, 23),
			}),
		}),

		shopPages = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.014, 0.332),
			Size = UDim2.fromOffset(830, 406),
		}, {
			uIPageLayout = e("UIPageLayout", {
				ref = pageLayoutRef,
				SortOrder = Enum.SortOrder.LayoutOrder,
				ScrollWheelInputEnabled = false,
				TouchInputEnabled = false,
				GamepadInputEnabled = false,
				EasingDirection = Enum.EasingDirection.InOut,
				TweenTime = 0.2,
				EasingStyle = Enum.EasingStyle.Quad,
			}),
			pages = e(React.Fragment, nil, pageElements),
		}),

		topbar = e("ImageLabel", {
			Image = "rbxassetid://18134658465",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(849, 87),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18134622429",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(849, 87),
			}),

			shop = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Shop",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(64, 35),
				Size = UDim2.fromOffset(58, 21),
			}),

			close = e(CloseButton, {
				size = UDim2.fromOffset(42, 42),
				position = UDim2.fromScale(0.945, 0.51),
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire(nil)
				end,
			}),

			shopIcon = e("ImageLabel", {
				Image = "rbxassetid://18134622781",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(24, 30),
				Size = UDim2.fromOffset(24, 27),
			}),

			coins = e(CurrencyHolder, {
				currency = "Coins",
				position = UDim2.fromOffset(625, 24),
			}),
		}),

		categoryButtonList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0259, 0.184),
			Size = UDim2.fromOffset(421, 56),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 8),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			categoryButtonList = e(React.Fragment, nil, categoryButtonElements),
		}),
	})
end

return Shop
