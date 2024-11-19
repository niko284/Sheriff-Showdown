--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local PlayerScripts = LocalPlayer.PlayerScripts

local CloseButton = require(ReplicatedStorage.react.components.buttons.CloseButton)
local Currency = require(ReplicatedStorage.constants.Currencies)
local DailyRewardTemplate = require(ReplicatedStorage.react.components.dailyRewards.DailyRewardTemplate)
local DaySevenTemplate = require(ReplicatedStorage.react.components.dailyRewards.DaySevenTemplate)
local InterfaceController = require(PlayerScripts.controllers.InterfaceController)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Net = require(ReplicatedStorage.packages.Net)
local React = require(ReplicatedStorage.packages.React)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Rewards = require(ReplicatedStorage.constants.Rewards)
local RewardsContext = require(ReplicatedStorage.react.contexts.RewardsContext)
local Types = require(ReplicatedStorage.constants.Types)
local animateCurrentInterface = require(ReplicatedStorage.react.hooks.animateCurrentInterface)

local RewardsNamespace = Remotes.Client:GetNamespace("Rewards")

local ClaimDailyReward = RewardsNamespace:Get("ClaimDailyReward") :: Net.ClientAsyncCaller

local useContext = React.useContext
local useEffect = React.useEffect
local useCallback = React.useCallback
local e = React.createElement

type DailyRewardProps = {}

local function getRewardImageId(reward: Types.DailyReward): number
	if reward.Type == "Coins" then
		local amt = reward.Amount :: number
		local coins = (Currency :: any).Coins :: Types.CurrencyData
		for i, currency in coins.Packs do
			if amt < currency.Amount then
				if i == 1 then
					return currency.Image
				else
					return coins.Packs[i - 1].Image
				end
			end
		end
	elseif reward.Type == "Item" then
		local itemId = reward.ItemId :: number
		return ItemUtils.GetItemInfoFromId(itemId).Image
	end
	return 0
end

local function DailyRewards(_props: DailyRewardProps)
	local rewardsCont = useContext(RewardsContext)

	local _shouldRender, styles =
		animateCurrentInterface("DailyRewards", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local claimReward = useCallback(function(dayToClaim: number)
		if not rewardsCont.rewards.daily then
			return
		end

		local oldRewards = rewardsCont.rewards

		local newRewards = table.clone(rewardsCont.rewards)
		local newDailyRewards = table.clone(rewardsCont.rewards.daily)

		newDailyRewards.LastRewardClaim = os.time()
		newDailyRewards.RewardDay = dayToClaim
		newRewards.daily = newDailyRewards

		rewardsCont.set(newRewards)

		ClaimDailyReward:CallServerAsync()
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					rewardsCont.set(oldRewards)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
				rewardsCont.set(oldRewards)
			end)
	end, { rewardsCont })

	local dailyRewards = rewardsCont.rewards.daily

	local rewardElements = {}

	local dayToClaim = nil
	if dailyRewards then
		local lastRewardDay = dailyRewards.RewardDay - 1
		-- Let's see if we can find a reward to claim
		if dailyRewards.LastRewardClaim == -1 then
			dayToClaim = 1
		else
			local hoursSinceLastClaim = (os.time() - dailyRewards.LastRewardClaim) / 3600
			if hoursSinceLastClaim >= 24 and hoursSinceLastClaim < 48 then
				dayToClaim = dailyRewards.RewardDay
			elseif hoursSinceLastClaim >= 48 then
				lastRewardDay = 1
				dayToClaim = 1 -- They haven't claimed a reward in the last 24 hours. Reset the day to 1.
			end
		end
		for day, rewardIndex in dailyRewards.Rewards do
			local reward = Rewards[rewardIndex]

			rewardElements[reward.Day] = e(day ~= 7 and DailyRewardTemplate or DaySevenTemplate, {
				canClaim = dayToClaim == reward.Day,
				claimed = reward.Day <= lastRewardDay and dayToClaim and dayToClaim > reward.Day or false,
				size = UDim2.fromOffset(254, 131),
				reward = "Day " .. reward.Day,
				icon = getRewardImageId(reward),
				day = reward.Day,
				claim = claimReward,
			})
		end
	end

	useEffect(function()
		if rewardsCont and rewardsCont.rewards.daily then -- Determine if we should open the rewards window, when the player rewards change.
			local daily = rewardsCont.rewards.daily
			local shouldShow = false
			if daily.LastRewardClaim == -1 then
				shouldShow = true
			else
				local hoursSinceLastClaim = (os.time() - daily.LastRewardClaim) / 3600
				if hoursSinceLastClaim >= 24 and hoursSinceLastClaim < 48 or hoursSinceLastClaim >= 48 then
					shouldShow = true
				end
			end
			if shouldShow then
				InterfaceController.InterfaceChanged:Fire("DailyRewards")
			end
		end
		return function() end
	end, { rewardsCont })

	return e("ImageLabel", {
		Image = "rbxassetid://18250424460",
		BackgroundTransparency = 1,
		Position = styles.position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(849, 609),
	}, {
		topbar = e("ImageLabel", {
			Image = "rbxassetid://18250424775",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0.143),
		}, {
			pattern = e("ImageLabel", {
				Image = "rbxassetid://18250424840",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}),

			title = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Daily Rewards",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.0742, 0.391),
				Size = UDim2.fromScale(0.172, 0.264),
			}),

			close = e(CloseButton, {
				size = UDim2.fromOffset(43, 43),
				position = UDim2.fromScale(0.945, 0.511),
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire(nil)
				end,
			}),

			icon = e("ImageLabel", {
				Image = "rbxassetid://18250436220",
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.0271, 0.356),
				Size = UDim2.fromScale(0.0318, 0.31),
			}),
		}),

		frame = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.021, 0.187),
			Size = UDim2.fromOffset(813, 462),
		}, {
			uIListLayout = e("UIListLayout", {
				Padding = UDim.new(0, 15),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,

				Wraps = true,

				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				VerticalFlex = Enum.UIFlexAlignment.Fill,
			}),

			uIPadding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 5),
			}),

			dayElements = e(React.Fragment, nil, rewardElements),
		}),

		dailyTimer = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(627, 24),
			Size = UDim2.fromOffset(132, 42),
		}, {
			timeLeft = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "12:53:14",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(52, 15),
				Size = UDim2.fromOffset(61, 13),
			}),

			timerIcon3 = e("ImageLabel", {
				Image = "rbxassetid://18442700585",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(132, 42),
			}),

			timerIcon2 = e("ImageLabel", {
				Image = "rbxassetid://18442700645",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(29, 15),
				Size = UDim2.fromOffset(8, 8),
			}),

			timerIcon = e("ImageLabel", {
				Image = "rbxassetid://18442700730",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(20, 11),
				Size = UDim2.fromOffset(21, 21),
			}),
		}),
	})
end

return DailyRewards
