--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local FeaturedItem = require(Components.shop.FeaturedItem)
local Freeze = require(ReplicatedStorage.packages.Freeze)
local GamepassSlideshow = require(Components.shop.GamepassSlideshow)
local Gamepasses = require(ReplicatedStorage.constants.Gamepasses)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local LargeFeaturedItem = require(Components.shop.LargeFeaturedItem)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type FeaturedPageProps = Types.FrameProps & {
	pageRef: (ref: Frame) -> (),
}

local SMALL_FEATURED_ITEMS = {
	{
		id = 1,
	},
	{
		id = 2,
	},
	{
		id = 3,
	},
}
local LARGE_FEATURED_ITEMS = {
	{
		id = 4,
	},
	{
		id = 5,
	},
}

local function FeaturedPage(props: FeaturedPageProps)
	local smallFeaturedItemElements = {} :: { [string]: any }
	for index, smallFeatured in SMALL_FEATURED_ITEMS do
		local itemInfo = ItemUtils.GetItemInfoFromId(smallFeatured.id)
		smallFeaturedItemElements[itemInfo.Name] = e(FeaturedItem, {
			icon = string.format("rbxassetid://%d", itemInfo.Image),
			rarity = itemInfo.Rarity,
			layoutOrder = index,
			featuredName = itemInfo.Name,
			size = UDim2.fromOffset(163, 163),
		})
	end

	local largeFeaturedItemElements = {} :: { [string]: any }
	for index, largeFeatured in LARGE_FEATURED_ITEMS do
		local itemInfo = ItemUtils.GetItemInfoFromId(largeFeatured.id)
		largeFeaturedItemElements[itemInfo.Name] = e(LargeFeaturedItem, {
			icon = string.format("rbxassetid://%d", itemInfo.Image),
			rarity = itemInfo.Rarity,
			layoutOrder = index,
			featuredName = itemInfo.Name,
			size = UDim2.fromOffset(259, 151),
		})
	end

	local FEATURED_GAMEPASSES = Freeze.List.map(
		Freeze.List.filter(Gamepasses, function(gamepass, _index)
			return gamepass.Featured
		end),
		function(gamepass, _index)
			return {
				id = gamepass.GamepassId,
			}
		end
	)

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.0142, 0.332),
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromOffset(824, 393),
		ref = function(rbx: Frame)
			props.pageRef(rbx)
		end,
	}, {
		largeFeaturedList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0125, 0.569),
			Size = UDim2.fromOffset(539, 164),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 20),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			largeFeaturedItems = e(React.Fragment, nil, largeFeaturedItemElements),
		}),

		gamepassSlides = e(GamepassSlideshow, {
			position = UDim2.fromOffset(562, 50),
			size = UDim2.fromOffset(252, 338),
			gamepasses = FEATURED_GAMEPASSES,
		}),

		smallFeaturedList = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0125, 0.109),
			Size = UDim2.fromOffset(539, 174),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 20),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			featuredElements = e(React.Fragment, nil, smallFeaturedItemElements),
		}),

		featured = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Featured",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(18, 19),
			Size = UDim2.fromOffset(74, 12),
		}),

		gamepasses = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Gamepasses",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(562, 19),
			Size = UDim2.fromOffset(105, 15),
		}),
	})
end

return React.memo(FeaturedPage)
