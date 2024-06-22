--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local AutomaticScrolling = require(Components.frames.AutomaticScrollingFrame)
local CrateItemTemplate = require(Components.shop.crates.CrateItemTemplate)
local Crates = require(ReplicatedStorage.constants.Crates)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type CrateContentsPageProps = {
	pageRef: (ref: Frame) -> (),
	crateName: Types.Crate,
}

local function CrateContentsPage(props: CrateContentsPageProps)
	local crateInfo = Crates[props.crateName]
	local contentElements = {}

	local crateItems = {}
	for _, itemName in crateInfo.ItemContents do
		local itemInfo = ItemUtils.GetItemInfoFromName(itemName)
		table.insert(crateItems, itemInfo)
	end

	-- sort by increasing rarity
	table.sort(crateItems, function(a, b)
		return a.Rarity < b.Rarity
	end)

	for _, itemInfo in crateItems do
		contentElements[itemInfo.Id] = e(CrateItemTemplate, {
			icon = string.format("rbxassetid://%d", itemInfo.Image),
			rarity = itemInfo.Rarity,
			itemName = itemInfo.Name,
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Rotation = 0.01,
		Size = UDim2.fromScale(1, 1.03),
		ref = function(rbx: Frame)
			props.pageRef(rbx)
		end,
	}, {
		backButton = e("ImageLabel", {
			Image = "rbxasset://psd_ui/ShopCrateContentsPSD/img_2.png",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(9, -48),
			Size = UDim2.fromOffset(42, 42),
		}, {
			arrow = e("ImageLabel", {
				Image = "rbxasset://psd_ui/ShopCrateContentsPSD/img_3.png",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(9, 9),
				Size = UDim2.fromOffset(24, 24),
			}),
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
			Position = UDim2.fromOffset(69, -35),
			Size = UDim2.fromOffset(135, 16),
		}),

		crateItemList = e(AutomaticScrolling, {
			scrollBarThickness = 9,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.00242, 0.195),
			size = UDim2.fromOffset(820, 313),
		}, {
			gridLayout = e("UIGridLayout", {
				CellPadding = UDim2.fromOffset(15, 15),
				CellSize = UDim2.fromOffset(145, 145),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			contents = e(React.Fragment, nil, contentElements),
		}),

		weapons = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Weapons",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 48),
			Size = UDim2.fromOffset(78, 15),
		}),
	})
end

return React.memo(CrateContentsPage)
