-- Shop
-- February 23rd, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Hooks = ReplicatedStorage.hooks
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils
local Components = ReplicatedStorage.components
local FrameComponents = Components.frames
local ShopComponents = Components.shop
local Constants = ReplicatedStorage.constants
local PlayerScripts = LocalPlayer.PlayerScripts
local Rodux = PlayerScripts.rodux
local Controllers = PlayerScripts.controllers
local Slices = Rodux.slices

local AutomaticFrame = require(FrameComponents.AutomaticFrame)
local AutomaticScrollingFrame = require(FrameComponents.AutomaticScrollingFrame)
local CategoryButton = require(ShopComponents.menu.CategoryButton)
local CrateContainer = require(ShopComponents.containers.CrateContainer)
local CrateItem = require(ShopComponents.crates.CrateItem)
local CratePurchase = require(ShopComponents.crates.CratePurchase)
local Crates = require(Constants.Crates)
local CurrencyDisplay = require(ShopComponents.topbar.CurrencyDisplay)
local CurrentInterfaceSlice = require(Slices.CurrentInterfaceSlice)
local FeaturedItem = require(ShopComponents.menu.FeaturedItem)
local ItemController = require(Controllers.ItemController)
local ItemUtils = require(Utils.ItemUtils)
local Items = require(Constants.Items)
local React = require(Packages.React)
local ReactRodux = require(Packages.ReactRodux)
local Types = require(Constants.Types)
local createNextOrder = require(Hooks.createNextOrder)
local useCurrentInterface = require(Hooks.useCurrentInterface)

local useCallback = React.useCallback
local useState = React.useState
local e = React.createElement

local SHOP_CATEGORIES = {
	Crates = { Image = 16190731044, ContainerElement = CrateContainer },
	Gamepasses = { Image = 16190731044, ContainerElement = nil },
	Extra = { Image = 16190731044, ContainerElement = nil },
}

-- // Shop \\

local function Shop()
	local viewInfo, setViewInfo = useState(nil :: Types.ShopViewInfo?)
	local cratePurchaseInfo, setCratePurchaseInfo = useState(nil :: Types.CrateInfo?)

	local currentCategory, setCurrentCategory = useState(nil :: string?)

	local contentNextOrder = createNextOrder()

	local _shouldRender, styles = useCurrentInterface("Shop", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.5))
	local dispatch = ReactRodux.useDispatch()

	local onFeaturedItemClicked = useCallback(function(itemInfo: Types.ItemInfo)
		setViewInfo({
			Name = itemInfo.Name,
			Image = itemInfo.Image,
			Type = "Item",
		})
	end, { setViewInfo })

	local changeCategory = useCallback(function(categoryName: string)
		setCurrentCategory(categoryName)
	end, { setCurrentCategory })

	-- Create the featured item contents in the menu
	local featuredItemsElements = {}
	for _, itemInfo in Items do
		if itemInfo.Featured == true then
			featuredItemsElements[itemInfo.Id] = e(FeaturedItem, {
				itemInfo = itemInfo,
				size = UDim2.fromOffset(184, 170),
				onActivated = onFeaturedItemClicked,
			})
		end
	end

	-- Create the category buttons for the shop menu
	local categoryButtonElements = {}

	for categoryName, category in pairs(SHOP_CATEGORIES) do
		categoryButtonElements[categoryName] = e(CategoryButton, {
			categoryName = categoryName,
			categoryImage = category.Image,
			size = UDim2.fromOffset(566, 130),
			onActivated = changeCategory,
			layoutOrder = contentNextOrder(),
		})
	end

	local categoryInfo = nil
	if currentCategory then
		for categoryName, category in pairs(SHOP_CATEGORIES) do
			if categoryName == currentCategory then
				categoryInfo = category
				break
			end
		end
	end

	local selectionContents = {}

	if viewInfo and viewInfo.Type == "Crate" then -- for crates, side view shows the items in the crate
		-- show the items that are in the crate
		local crateInfo = Crates[viewInfo.Name]

		local rarityProbabilities = ItemController:GetRarityProbabilities()

		local crateContents = table.clone(crateInfo.ItemContents) -- we will sort this table so we clone it
		table.sort(crateContents, function(itemAName: string, itemBName: string)
			local aInfo = ItemUtils.GetItemInfoFromName(itemAName)
			local bInfo = ItemUtils.GetItemInfoFromName(itemBName)

			return rarityProbabilities[aInfo.Rarity] < rarityProbabilities[bInfo.Rarity]
		end)

		for _, itemName in crateContents do
			local itemInfo = ItemUtils.GetItemInfoFromName(itemName)
			table.insert(
				selectionContents,
				e(CrateItem, {
					itemInfo = itemInfo,
					key = itemInfo.Id,
					layoutOrder = contentNextOrder(),
				})
			)
		end
	end

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.51),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = styles.position,
		Size = UDim2.fromOffset(805, 603),
	}, {

		cratePurchase = cratePurchaseInfo and e(CratePurchase, {
			crateType = viewInfo.Name,
			setCrateInfo = setCratePurchaseInfo, -- for closing the crate purchase
		}),

		shopName = e("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Text = "Shop",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.0288, 0.0244),
			Size = UDim2.fromOffset(69, 37),
		}),

		gemDisplay = e(CurrencyDisplay, {
			currency = "Gems",
			position = UDim2.fromScale(0.67, 0.023),
			size = UDim2.fromOffset(200, 45),
			gradientColor = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.0657, Color3.fromRGB(229, 255, 255)),
				ColorSequenceKeypoint.new(0.419, Color3.fromRGB(7, 255, 255)),
				ColorSequenceKeypoint.new(0.796, Color3.fromRGB(73, 231, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(88, 106, 120)),
			}),
		}),
		coinDisplay = e(CurrencyDisplay, {
			currency = "Coins",
			position = UDim2.fromScale(0.373, 0.023),
			size = UDim2.fromOffset(200, 45),
			gradientColor = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.121, Color3.fromRGB(255, 234, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 151, 2)),
			}),
		}),

		contents = currentCategory and e(AutomaticScrollingFrame, {
			bottomImage = "",
			scrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			scrollBarImageTransparency = 0.5,
			scrollBarThickness = 10,
			topImage = "",
			active = true,
			anchorPoint = Vector2.new(0, 0),
			backgroundColor3 = Color3.fromRGB(33, 33, 33),
			position = UDim2.fromScale(0.0114, 0.14),
			size = UDim2.fromScale(0.734, 0.844),
		}, {
			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0.01, 0),
			}),

			container = categoryInfo.ContainerElement and e(categoryInfo.ContainerElement, {
				setViewInfo = setViewInfo,
			}),

			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(8, 8),
				CellSize = UDim2.fromOffset(280, 150),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}),

		split = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.7,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.99, 0.116),
			Size = UDim2.fromOffset(-788, 1),
		}),

		closeButton = e("TextButton", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = "X",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			TextSize = 14,
			TextTransparency = 0.1,
			TextWrapped = true,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			[React.Event.Activated] = function()
				dispatch(CurrentInterfaceSlice.actions.SetCurrentInterface({ interface = nil }))
			end,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.935, 0.0154),
			Size = UDim2.fromOffset(52, 49),
		}),

		uiselection = e(AutomaticScrollingFrame, {
			anchorPoint = Vector2.new(0, 0),
			bottomImage = "",
			scrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
			scrollBarImageTransparency = 0.5,
			scrollBarThickness = 10,
			topImage = "",
			active = true,
			backgroundColor3 = Color3.fromRGB(33, 33, 33),
			position = UDim2.fromScale(0.0106, 0.138),
			size = UDim2.fromScale(0.734, 0.844),
			visible = currentCategory == nil,
		}, {

			layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			featuredList = e(AutomaticFrame, {
				instanceProps = {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.fromOffset(578, 171),
					LayoutOrder = 0,
				},
			}, {
				padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 6),
				}),

				contents = e(React.Fragment, nil, featuredItemsElements),

				listLayout = e("UIListLayout", {
					Padding = UDim.new(0, 7),
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),

			mainlist = e(AutomaticFrame, {
				instanceProps = {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 1,
					Position = UDim2.fromOffset(10, 169),
					Size = UDim2.fromOffset(566, 1000),
				},
			}, {
				listLayout = e("UIListLayout", {
					Padding = UDim.new(0, 2),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				contents = e(React.Fragment, nil, categoryButtonElements),
			}),
		}),

		view = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.754, 0.138),
			Size = UDim2.fromOffset(190, 509),
		}, {
			desc = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(116, 116, 116),
				BackgroundTransparency = 0.8,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0316, 0.385),
				Size = UDim2.fromOffset(177, 257),
			}, {
				uICorner = e("UICorner"),

				content = e("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.fromScale(1, 1),
				}, {
					selectionContents = e(AutomaticScrollingFrame, {
						bottomImage = "",
						scrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
						scrollBarImageTransparency = 0.5,
						scrollBarThickness = 10,
						anchorPoint = Vector2.new(0, 0),
						topImage = "",
						backgroundColor3 = Color3.fromRGB(33, 33, 33),
						size = UDim2.fromScale(1, 1),
					}, {
						uIPadding2 = e("UIPadding", {
							PaddingLeft = UDim.new(0.035, 0),
						}),

						content = e(React.Fragment, nil, selectionContents),

						gridLayout = e("UIGridLayout", {
							CellPadding = UDim2.fromOffset(6, 6),
							CellSize = UDim2.fromOffset(75, 75),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					}),
				}),
			}),

			buy = e("TextButton", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Text = "Buy",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextTransparency = 0.2,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.279, 0.904),
				Size = UDim2.fromOffset(130, 42),
				[React.Event.Activated] = function()
					-- handle based on the viewInfo
					if viewInfo.Type == "Crate" then
						setCratePurchaseInfo(Crates[viewInfo.Name])
					end
				end,
			}, {
				uICorner1 = e("UICorner"),

				uIStroke = e("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
					Transparency = 0.7,
				}, {
					uIGradient = e("UIGradient", {
						Rotation = -90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.196, 0.639),
							NumberSequenceKeypoint.new(0.731, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),
			}),

			uIGradient1 = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(116, 116, 116)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(116, 116, 116)),
				}),
				Rotation = -90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.814),
					NumberSequenceKeypoint.new(0.702, 1),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),

			back = e("TextButton", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Text = "<",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextTransparency = 0.2,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0316, 0.904),
				Size = UDim2.fromOffset(42, 42),
				[React.Event.Activated] = function()
					setCurrentCategory(nil)
					setViewInfo(nil)
				end,
			}, {
				uICorner2 = e("UICorner"),

				uIStroke1 = e("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
					Transparency = 0.7,
				}, {
					uIGradient2 = e("UIGradient", {
						Rotation = -90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.196, 0.639),
							NumberSequenceKeypoint.new(0.731, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),
			}),

			selection = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.fromScale(0.034, 0.012),
				Size = UDim2.fromOffset(176, 176),
			}, {
				uIGradient3 = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(116, 116, 116)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(116, 116, 116)),
					}),
					Rotation = -90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.814),
						NumberSequenceKeypoint.new(0.702, 1),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),

				viewImage = e("ImageLabel", {
					Image = viewInfo and string.format("rbxassetid://%d", viewInfo.Image),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(-0.008, 0.295),
					Size = UDim2.fromOffset(176, 176),
				}),

				name = e("TextLabel", {
					FontFace = Font.new(
						"rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Text = viewInfo and viewInfo.Name or "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					TextSize = 14,
					TextTransparency = 0.3,
					TextWrapped = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0.0648, 0.046),
					Size = UDim2.fromOffset(149, 33),
				}),

				uICorner3 = e("UICorner"),
			}),

			uICorner4 = e("UICorner"),
		}),

		uIGradient6 = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 13, 13)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 36)),
			}),
			Rotation = -90,
		}),

		corner = e("UICorner", {
			CornerRadius = UDim.new(0.01, 8),
		}),
	})
end

return Shop
