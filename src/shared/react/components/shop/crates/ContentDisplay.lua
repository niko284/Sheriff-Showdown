--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local React = require(ReplicatedStorage.packages.React)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement

type ContentDisplayProps = Types.FrameProps & {
	itemIds: { number },
	displayRef: ((node: Frame) -> ())?,
}

local function ContentDisplay(props: ContentDisplayProps)
	local previewElements = {}

	for _, itemId in props.itemIds do
		local itemInfo = ItemUtils.GetItemInfoFromId(itemId)
		previewElements[itemId] = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(133, 133, 133),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(14, 14),
			Size = UDim2.fromOffset(53, 53),
		}, {
			contentImage = e("ImageLabel", {
				Image = string.format("rbxassetid://%d", itemInfo.Image),
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(6, 6),
				Size = UDim2.fromOffset(42, 43),
			}),

			corner = e("UICorner", {
				CornerRadius = UDim.new(0, 3),
			}),

			stroke = e("UIStroke", {
				Color = Color3.fromRGB(158, 158, 158),
			}),
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.0435, 0.111),
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromOffset(231, 62),
		ref = props.displayRef,
	}, {
		listLayout = e("UIListLayout", {
			Padding = UDim.new(0, 6),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		previews = e(React.Fragment, nil, previewElements),
	})
end

return React.memo(ContentDisplay)
