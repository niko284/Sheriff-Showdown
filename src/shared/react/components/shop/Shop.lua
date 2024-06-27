--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components
local Controllers = Players.LocalPlayer.PlayerScripts.controllers
local Contexts = ReplicatedStorage.react.contexts

local Button = require(Components.buttons.Button)
local CloseButton = require(Components.buttons.CloseButton)
local CodeInput = require(Components.shop.CodeInput)
local CratesPage = require(Components.shop.pages.CratesPage)
local CurrencyHolder = require(Components.shop.CurrencyHolder)
local CurrencyPage = require(Components.shop.pages.CurrencyPage)
local FeaturedPage = require(Components.shop.pages.FeaturedPage)
local GamepassPage = require(Components.shop.pages.GamepassPage)
local InterfaceController = require(Controllers.InterfaceController)
local OptionButton = require(Components.buttons.OptionButton)
local React = require(ReplicatedStorage.packages.React)
local Separator = require(Components.other.Separator)
local ShopContext = require(Contexts.ShopContext)
local animateCurrentInterface = require(ReplicatedStorage.react.hooks.animateCurrentInterface)

local e = React.createElement
local useState = React.useState
local useRef = React.useRef
local useContext = React.useContext
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
	Currency = {
		Element = CurrencyPage,
		LayoutOrder = 3,
	},
	Gamepasses = {
		Element = GamepassPage,
		LayoutOrder = 4,
	},
} :: { [ShopCategory]: ShopCategoryData }

type ShopCategory = "Home" | "Crates" | "Currency" | "Gamepasses"
type ShopCategoryData = {
	Element: any,
	LayoutOrder: number,
}
type ShopProps = {}

local function Shop(_props: ShopProps)
	local currentCategory, setCurrentCategory = useState("Home" :: ShopCategory)
	local showCodeInput, setShowCodeInput = useState(false)

	local shopState = useContext(ShopContext)
	local pageRefs = useRef({}) :: { current: { [ShopCategory]: any } }
	local pageLayoutRef = useRef(nil :: UIPageLayout?)

	local _shouldRender, styles = animateCurrentInterface("Shop", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local categoryButtonElements = {} :: { [string]: any }
	for categoryName, categoryInfo in pairs(SHOP_CATEGORIES) do
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
			layoutOrder = categoryInfo.LayoutOrder,
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

		codeInput = showCodeInput and e(CodeInput, {
			position = UDim2.fromOffset(209, 252),
			codesPosition = UDim2.fromScale(0.504, 0.779),
		}),

		optionList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.725, 0.191),
			Size = UDim2.fromOffset(216, 45),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 10),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			giftButton = e(OptionButton, {
				size = UDim2.fromOffset(42, 42),
				image = "rbxassetid://18184690498",
				layoutOrder = 2,
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire("GiftingSelection")
				end,
			}),
			codesButton = e(OptionButton, {
				size = UDim2.fromOffset(42, 42),
				image = "rbxassetid://18184990547",
				onActivated = function()
					setShowCodeInput(function(show)
						return not show
					end)
				end,
				layoutOrder = 1,
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
			pageLayout = e("UIPageLayout", {
				ref = pageLayoutRef,
				Circular = true,
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
				Text = if shopState.giftRecipient == nil
					then "Shop"
					else string.format(
						'<font color="rgb(255,228,80)">Gifting to</font> %s',
						shopState.giftRecipient.Name
					),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				RichText = true,
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
				Image = if shopState.giftRecipient == nil
					then "rbxassetid://18134622781"
					else "rbxassetid://18184643894",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(24, 30),
				Size = UDim2.fromOffset(24, 27),
			}),

			coins = e(CurrencyHolder, {
				currency = "Coins",
				position = UDim2.fromOffset(625, 24),
			}),

			gems = e(CurrencyHolder, {
				currency = "Gems",
				position = UDim2.fromOffset(510, 24),
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
