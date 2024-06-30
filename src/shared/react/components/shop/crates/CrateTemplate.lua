--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local Button = require(Components.buttons.Button)
local ContentDisplay = require(Components.shop.crates.ContentDisplay)
local Crates = require(ReplicatedStorage.constants.Crates)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local OptionButton = require(Components.buttons.OptionButton)
local React = require(ReplicatedStorage.packages.React)
local Timer = require(ReplicatedStorage.packages.Timer)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef
local useState = React.useState

type CrateTemplateProps = Types.FrameProps & {
	crateImage: string,
	crateName: Types.Crate,
	crateDescription: string,
	rotationTime: number,
	amountOfPreviewItems: number,
	onViewContents: (rbx: Frame) -> (),
}

local function CrateTemplate(props: CrateTemplateProps)
	local crateInfo = Crates[props.crateName]

	local previewContents, setPreviewContents = useState(function()
		local newContents = {}
		local itemNames = table.clone(crateInfo.ItemContents)

		local newPreviewsToAppend = 2

		for _ = 1, newPreviewsToAppend do
			local contents = {}
			for _ = 1, props.amountOfPreviewItems do
				if #itemNames == 0 then
					break
				end
				local randomItemName = table.remove(itemNames, math.random(1, #itemNames)) :: string

				local itemFromName = ItemUtils.GetItemInfoFromName(randomItemName)
				if itemFromName then
					table.insert(contents, itemFromName.Id)
				end
			end
			table.insert(newContents, contents)
		end

		return newContents
	end)

	local contentDisplayRefs = useRef({}) :: { current: any }
	local pageLayoutRef = useRef(nil :: UIPageLayout?)
	local currentIndex = useRef(1) :: { current: number }

	useEffect(function()
		local timer = Timer.new(props.rotationTime)
		timer.Tick:Connect(function()
			if pageLayoutRef.current then
				local nextIndex = currentIndex.current == 1 and 2 or 1
				pageLayoutRef.current:JumpToIndex(nextIndex)
				task.delay(pageLayoutRef.current.TweenTime, function()
					setPreviewContents(function(old)
						local newContents = table.clone(old)
						newContents[nextIndex] = old[nextIndex]

						local contents = {}
						local itemNames = table.clone(crateInfo.ItemContents)
						for _ = 1, props.amountOfPreviewItems do
							if #itemNames == 0 then
								break
							end
							local randomItemName = table.remove(itemNames, math.random(1, #itemNames)) :: string

							local itemFromName = ItemUtils.GetItemInfoFromName(randomItemName)
							if itemFromName then
								table.insert(contents, itemFromName.Id)
							end
						end

						newContents[currentIndex.current] = contents

						return newContents
					end)
				end)
				currentIndex.current = nextIndex
			end
		end)

		timer:StartNow()

		return function()
			timer:Destroy()
		end
	end, {})

	local contentDisplayElements = {}
	for index, itemList in previewContents do
		contentDisplayElements[index] = e(ContentDisplay, {
			itemIds = itemList,
			layoutOrder = index,
			displayRef = function(node: Frame)
				contentDisplayRefs.current[index] = node
			end,
		})
	end

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(255, 255, 255),
		}),

		crateImage = e("ImageLabel", {
			Image = props.crateImage,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(45, 74),
			Size = UDim2.fromOffset(166, 166),
			ZIndex = 0,
		}),

		contentHolder = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(103, 103, 103),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 183),
			ClipsDescendants = true,
			Size = UDim2.fromOffset(253, 81),
		}, {
			contentDisplays = e(React.Fragment, nil, contentDisplayElements),
			pageLayout = e("UIPageLayout", {
				ref = pageLayoutRef,
				SortOrder = Enum.SortOrder.LayoutOrder,
				ScrollWheelInputEnabled = false,
				TouchInputEnabled = false,
				GamepadInputEnabled = false,
				Circular = true,
				EasingDirection = Enum.EasingDirection.InOut,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				TweenTime = 0.75,
				EasingStyle = Enum.EasingStyle.Quad,
			}),
		}),

		purchaseButton = e(Button, {
			text = "Purchase",
			textColor3 = Color3.fromRGB(0, 53, 25),
			gradient = ColorSequence.new(Color3.fromRGB(68, 252, 153), Color3.fromRGB(35, 203, 112)),
			cornerRadius = UDim.new(0, 5),
			textSize = 16,
			anchorPoint = Vector2.new(0.5, 0.5),
			position = UDim2.fromScale(0.388, 0.901),
			size = UDim2.fromOffset(181, 45),
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(255, 255, 255),
			strokeThickness = 1.5,
			gradientRotation = -90,
			onActivated = function()
				
			end
		}),

		viewContents = e(OptionButton, {
			anchorPoint = Vector2.new(0.5, 0.5),
			size = UDim2.fromOffset(45, 45),
			position = UDim2.fromScale(0.852, 0.901),
			image = "rbxassetid://18141436407",
			gradient = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
			backgroundColor3 = Color3.fromRGB(255, 255, 255),
			onActivated = props.onViewContents,
		}),

		crateName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.crateName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 35),
			Size = UDim2.fromOffset(99, 13),
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.crateDescription,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			TextTransparency = 0.369,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(22, 53),
			Size = UDim2.fromOffset(81, 14),
		}),
	})
end

return React.memo(CrateTemplate)
