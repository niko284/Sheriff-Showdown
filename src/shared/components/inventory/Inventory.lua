-- Inventory
-- February 13th, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local Constants = ReplicatedStorage.constants
local Hooks = ReplicatedStorage.hooks
local CommonComponents = Components.common
local InventoryComponents = Components.inventory
local FrameComponents = Components.frames
local PlayerScripts = LocalPlayer.PlayerScripts
local Rodux = PlayerScripts.rodux
local Slices = Rodux.slices
local Utils = ReplicatedStorage.utils
local SharedAssets = ReplicatedStorage.assets
local Controllers = PlayerScripts.controllers

local CurrentInterfaceSlice = require(Slices.CurrentInterfaceSlice)
local InputBar = require(CommonComponents.InputBar)
local InventoryController = require(Controllers.InventoryController)
local InventoryItemList = require(InventoryComponents.InventoryItemList)
local ItemUtils = require(Utils.ItemUtils)
local React = require(Packages.React)
local ReactRodux = require(Packages.ReactRodux)
local Types = require(Constants.Types)
local ViewportFrame = require(FrameComponents.ViewportFrame)
local useCurrentInterface = require(Hooks.useCurrentInterface)

local GUNS_FOLDER = SharedAssets.guns

local e = React.createElement
local useState = React.useState

-- // Inventory Component \\

type InventoryProps = {}

local function Inventory(_props: InventoryProps)
	local _shouldRender, styles = useCurrentInterface("Inventory", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.5))
	local searchQuery, setSearchQuery = useState("")

	local dispatch = ReactRodux.useDispatch()

	local inventory = ReactRodux.useSelector(function(state)
		return state.Inventory :: Types.Inventory?
	end)

	local equippedGunModel = nil
	local equippedGunItems = InventoryController:GetItemsOfType("Gun", true)
	if #equippedGunItems >= 1 then
		local equippedGun = equippedGunItems[1] -- only one gun can be equipped at a time
		local equippedGunInfo = ItemUtils.GetItemInfoFromId(equippedGun.Id)
		local gunSpecificFolder = GUNS_FOLDER:FindFirstChild(equippedGunInfo.Name)
		if gunSpecificFolder then
			equippedGunModel = gunSpecificFolder:FindFirstChild("Render")
		end
	end

	return e("ImageLabel", {
		Image = "rbxassetid://16155235853",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = styles.position,
		Size = UDim2.fromOffset(819, 637),
	}, {
		inv = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.51),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(719, 543),
		}, {
			name = e("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Text = "Inventory",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				TextSize = 14,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0288, 0.0244),
				Size = UDim2.fromOffset(109, 37),
			}, {
				uICorner = e("UICorner", {
					CornerRadius = UDim.new(0.025, 1),
				}),

				uIStroke = e("UIStroke", {
					Thickness = 2,
					Transparency = 0.8,
				}, {
					uIGradient = e("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
						}),
						Rotation = -90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.498, 1),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),
			}),

			container = e(InventoryItemList, {
				scrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
				scrollBarImageTransparency = 0.5,
				scrollBarThickness = 10,
				anchorPoint = Vector2.new(0, 0),
				inventory = inventory,
				searchQuery = searchQuery,
				backgroundColor3 = Color3.fromRGB(33, 33, 33),
				position = UDim2.fromScale(0.288, 0.14),
				size = UDim2.fromScale(0.702, 0.844),
			}, {
				padding = e("UIPadding", {
					PaddingLeft = UDim.new(0.02, 0),
				}),

				gridLayout = e("UIGridLayout", {
					CellPadding = UDim2.fromOffset(8, 8),
					CellSize = UDim2.fromOffset(113, 130),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),

			gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(13, 13, 13)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(36, 36, 36)),
				}),
				Rotation = -90,
			}),

			split = e("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.7,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.99, 0.121),
				Size = UDim2.fromOffset(-704, 1),
			}),

			gundecal = e("ImageLabel", {
				Image = "rbxassetid://16147319512",
				ImageTransparency = 0.96,
				ScaleType = Enum.ScaleType.Fit,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.0108, 0.29),
				Size = UDim2.fromOffset(199, 459),
				ZIndex = -10,
			}, {
				uIGradient2 = e("UIGradient", {
					Rotation = -45,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.138, 1),
						NumberSequenceKeypoint.new(0.706, 0),
						NumberSequenceKeypoint.new(1, 0),
					}),
				}),
			}),

			inputBar = e(InputBar, {
				position = UDim2.fromScale(0.0288, 0.913),
				size = UDim2.fromOffset(165, 30),
				strokeTransparency = 0,
				placeHolderText = "Codes",
				onTextChanged = function(rbx: TextBox)
					setSearchQuery(rbx.Text)
				end,
			}),

			uICorner2 = e("UICorner", {
				CornerRadius = UDim.new(0.01, 8),
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
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.917, 0.017),
				Size = UDim2.fromOffset(52, 49),
				[React.Event.Activated] = function()
					dispatch(CurrentInterfaceSlice.actions.SetCurrentInterface({ interface = nil }))
				end,
			}),

			gunViewport = e(
				ViewportFrame,
				{
					size = UDim2.fromOffset(189, 198),
					position = UDim2.fromScale(0.011, 0.138),
					backgroundTransparency = 1,
					backgroundColor3 = Color3.fromRGB(0, 0, 0),
					model = equippedGunModel,
					useDirectly = false,
					draggable = false,
					worldModel = true,
					spinSpeed = 1.25,
					listenForDescendants = false,
					scrollToZoom = true,
					zIndex = 0,
				} :: any,
				{
					uICorner3 = e("UICorner"),

					uIStroke2 = e("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 2,
						Transparency = 0.7,
					}, {
						uIGradient4 = e("UIGradient", {
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
								ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
							}),
							Rotation = -90,
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0),
								NumberSequenceKeypoint.new(0.498, 1),
								NumberSequenceKeypoint.new(1, 1),
							}),
						}),
					}),
				}
			),

			uIStroke3 = e("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 3,
				Transparency = 0.3,
			}, {
				uIGradient6 = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
					}),
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.798),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),

			box = e("TextBox", {
				CursorPosition = -1,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Regular,
					Enum.FontStyle.Italic
				),
				PlaceholderColor3 = Color3.fromRGB(213, 213, 213),
				PlaceholderText = "Search",
				Text = "",
				TextColor3 = Color3.fromRGB(213, 213, 213),
				TextSize = 16,
				TextWrapped = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0.437, 0.0244),
				Size = UDim2.fromOffset(270, 43),
			}, {
				uICorner4 = e("UICorner", {
					CornerRadius = UDim.new(1, 1),
				}),

				uIStroke4 = e("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 2,
					Transparency = 0.7,
				}, {
					uIGradient7 = e("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
						}),
						Rotation = -90,
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					}),
				}),

				uIGradient8 = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(94, 94, 94)),
					}),
					Rotation = -90,
				}),
			}),
		}),
	})
end

return Inventory
