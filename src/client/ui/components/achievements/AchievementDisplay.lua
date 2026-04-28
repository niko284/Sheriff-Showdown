--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local Button = require("@ui/components/buttons/Button")
local Currencies = require("@constants/Currencies")
local ItemUtils = require("@utilities/ItemUtils")
local Promise = require("@packages/Promise")
local Rarities = require("@constants/Rarities")
local React = require("@packages/React")
local Types = require("@constants/Types")
local UUIDSerde = require("@utilities/UUIDSerde")

local e = React.createElement
local useCallback = React.useCallback

type AchievementDisplayProps = {
	achievementName: string,
	achievement: Types.Achievement,
	rewards: { Types.AchievementReward },
	timesClaimed: number?,
	setSelectedAchievementUUID: (string?) -> (),
}

local function AchievementDisplay(props: AchievementDisplayProps)
	local rewardsText = ""

	local claimAchievement = useCallback(function(achievement: Types.Achievement)
		local serializedUUID = UUIDSerde.Serialize(achievement.UUID)

		props.setSelectedAchievementUUID(nil)
		Promise.new(function(resolve, reject)
			local ok, result = pcall(BlinkClient.AchievementsClaimAchievement.Invoke, serializedUUID)
			if ok then resolve(result) else reject(result) end
		end)
			:andThen(function(networkResponse: Types.NetworkResponse)
				if networkResponse.Success == false then
					warn(networkResponse.Response)
				end
			end)
			:catch(function(err: any)
				warn(tostring(err))
			end)
	end, { props.setSelectedAchievementUUID })

	for _, reward in props.rewards do
		if reward.Type == "Currency" then
			-- use rich text to color the currency text differently
			local currencyInfo = Currencies[reward.Currency]

			local rewardAmount = typeof(reward.Amount) == "function" and reward.Amount(props.achievement)
				or reward.Amount :: number

			rewardsText = rewardsText
				.. ", "
				.. string.format(
					'<font color="#%s">%d %s</font>',
					currencyInfo.Color:ToHex(),
					rewardAmount,
					reward.Currency
				)
		elseif reward.Type == "Item" then
			-- use the rarity color for the item text
			local itemInfo = ItemUtils.GetItemInfoFromId(reward.ItemId :: number)
			local rarityInfo = Rarities[itemInfo.Rarity :: Types.ItemRarity]
			local rarityColorHex = rarityInfo.Color:ToHex()

			rewardsText = rewardsText
				.. ", "
				.. string.format('<font color="#%s">%s</font>', rarityColorHex, itemInfo.Name)
		elseif reward.Type == "Badge" then
			-- @TODO: Add badge support
		end
	end

	local goal = props.achievement.Requirements[1].Goal
	local progress = props.achievement.Requirements[1].Progress

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(571, 246),
		Size = UDim2.fromOffset(253, 339),
	}, {
		claimButton = e(Button, {
			fontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			text = "Claim",
			textColor3 = Color3.fromRGB(0, 54, 25),
			anchorPoint = Vector2.new(0.5, 0.5),
			textSize = 16,
			size = UDim2.fromOffset(228, 39),
			position = UDim2.fromScale(0.502, 0.881),
			strokeThickness = 1.5,
			layoutOrder = 1,
			applyStrokeMode = Enum.ApplyStrokeMode.Border,
			strokeColor = Color3.fromRGB(128, 118, 118),
			cornerRadius = UDim.new(0, 5),
			gradient = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(68, 252, 153)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 203, 112)),
			}),
			gradientRotation = -90,
			onActivated = function()
				claimAchievement(props.achievement)
			end,
		}),

		rewardsBackground = e("ImageLabel", {
			Image = "rbxassetid://18442712213",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 190),
			Size = UDim2.fromOffset(253, 51),
		}, {
			rewardText = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Medium,
					Enum.FontStyle.Normal
				),
				Text = rewardsText:sub(3),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 13,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				RichText = true,
				Size = UDim2.fromScale(0.9, 0.9),
			}),
		}),

		separator = e("ImageLabel", {
			Image = "rbxassetid://18442712410",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 267),
			Size = UDim2.fromOffset(228, 4),
		}),

		separator1 = e("ImageLabel", {
			Image = "rbxassetid://18442712624",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(13, 149),
			Size = UDim2.fromOffset(228, 4),
		}),

		sliderBar = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(93, 93, 93),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(15, 125),
			Size = UDim2.fromOffset(209, 7),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			progress = e("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(progress / goal, 1),
			}, {
				corner = e("UICorner"),
			}),
		}),

		completion = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d%% Completed", math.clamp(math.round(progress / goal * 100), 0, 100)),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(15, 103),
			Size = UDim2.fromOffset(115, 13),
		}),

		rewards = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = "Rewards",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0, 165),
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(58, 11),
		}),

		selectedDescription = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = string.format("%d %s", #props.rewards, #props.rewards == 1 and "Reward" or "Rewards"),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(15, 55),
			Size = UDim2.fromOffset(144, 13),
		}),

		selectedName = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.achievementName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 17,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(15, 30),
			Size = UDim2.fromOffset(201, 15),
		}),

		uICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		uIStroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 1.5,
		}),
	})
end

return AchievementDisplay
