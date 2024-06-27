--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrollingFrame = require(Components.frames.AutomaticScrollingFrame)
local CrateItemTemplate = require(Components.shop.crates.CrateItemTemplate)
local Crates = require(ReplicatedStorage.constants.Crates)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local OptionButton = require(Components.buttons.OptionButton)
local RarityUtils = require(ReplicatedStorage.utils.RarityUtils)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type CrateContentsPageProps = Types.FrameProps & {
	crateName: Types.Crate,
	onBack: (crateToView: Types.Crate?) -> (),
}

local function CrateContentsPage(props: CrateContentsPageProps)
	local contentElements = {}
	if props.crateName then
		local crateInfo = Crates[props.crateName]

		local crateItems = {}
		for _, itemName in crateInfo.ItemContents do
			local itemInfo = ItemUtils.GetItemInfoFromName(itemName)
			table.insert(crateItems, itemInfo)
		end

		-- sort by increasing rarity
		table.sort(crateItems, function(a, b)
			local rarityA = RarityUtils.GetRarityProbability(a.Rarity)
			local rarityB = RarityUtils.GetRarityProbability(b.Rarity)
			return rarityA < rarityB
		end)

		for _, itemInfo in crateItems do
			contentElements[itemInfo.Id] = e(CrateItemTemplate, {
				icon = string.format("rbxassetid://%d", itemInfo.Image),
				rarity = RarityUtils.GetRarityProbability(itemInfo.Rarity) * 100,
				itemName = itemInfo.Name,
			})
		end
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Rotation = 0.01,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromScale(1, 1.03),
	}, {

		back = e(OptionButton, {
			size = UDim2.fromOffset(42, 42),
			position = UDim2.fromScale(0.036, 0.075),
			anchorPoint = Vector2.new(0.5, 0.5),
			gradient = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
			backgroundColor3 = Color3.fromRGB(255, 255, 255),
			image = "rbxassetid://18162442811",
			onActivated = function()
				props.onBack(nil)
			end,
		}),

		crateName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.crateName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.083, 0.055),
			Size = UDim2.fromOffset(135, 16),
		}),

		crateItemList = e(AutomaticScrollingFrame, {
			scrollBarThickness = 9,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.00242, 0.195),
			size = UDim2.fromOffset(820, 313),
		}, {
			padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 5),
				PaddingLeft = UDim.new(0, 5),
			}),
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(15, 15),
				CellSize = UDim2.fromOffset(145, 145),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			contents = e(React.Fragment, nil, contentElements),
		}),
	})
end

return React.memo(CrateContentsPage)
