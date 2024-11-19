--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local Net = require(ReplicatedStorage.packages.Net)
local PlayerDataService = require(Services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ResourceService = require(Services.ResourceService)
local Rewards = require(ReplicatedStorage.constants.Rewards)
local ServerComm = require(ServerScriptService.ServerComm)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local RewardsNamespace = Remotes.Server:GetNamespace("Rewards")

local ClaimDailyReward = RewardsNamespace:Get("ClaimDailyReward") :: Net.ServerAsyncCallback

local RewardService = {
	Name = "RewardService",
	PlayerRewards = ServerComm:CreateProperty("PlayerRewards", nil),
	DailyRewards = {} :: { [number]: { Types.DailyReward } },
	RewardClaimed = Signal.new() :: Signal.Signal<Player, Types.DailyReward>,
}

function RewardService:OnInit()
	-- Create a list of the daily rewards based on the day they are rewarded.
	for _, Reward: Types.DailyReward in ipairs(Rewards) do
		if Reward.RewardType ~= "Daily" then
			continue
		end
		if not RewardService.DailyRewards[Reward.Day] then
			RewardService.DailyRewards[Reward.Day] = {}
		end
		table.insert(RewardService.DailyRewards[Reward.Day], Reward)
	end

	PlayerDataService.DocumentLoaded:Connect(function(Player: Player, PlayerDocument)
		local playerResources = PlayerDocument:read().Resources
		if playerResources.RewardSeed == -1 then
			ResourceService:SetResource(Player, "RewardSeed", os.time())
		end
		RewardService.PlayerRewards:SetFor(Player, {
			daily = {
				RewardDay = playerResources.RewardDay,
				LastRewardClaim = playerResources.LastRewardClaim,
				Rewards = RewardService:GenerateDailyRewards(playerResources.RewardSeed),
			},
		})
	end)

	ClaimDailyReward:SetCallback(function(Player: Player)
		local response = self:ClaimDailyReward(Player)
		return response
	end)

	-- We can handle any resource rewards here, as they are easy to handle.

	RewardService.RewardClaimed:Connect(function(Player: Player, Reward: Types.DailyReward)
		local resourceExists = ResourceService:GetResource(Player, Reward.Type)
		if resourceExists and typeof(resourceExists) == "number" and Reward.Amount then
			-- amounts can be callbacks that return a number, or a static number.
			local Amount = if typeof(Reward.Amount) == "function" then Reward.Amount(Reward, Player) else Reward.Amount
			ResourceService:IncrementResource(Player, Reward.Type, Amount)
		end
	end)
end

function RewardService:GenerateDailyRewards(Seed: number): { number }
	local RNG = Random.new(Seed)
	local randomRewards = {}

	for Day = 1, 7 do
		local rewardList = RewardService.DailyRewards[Day]
		if not rewardList then
			continue
		end
		local reward = rewardList[RNG:NextInteger(1, #rewardList)]
		local rewardIndex = table.find(Rewards, reward) :: number
		table.insert(randomRewards, rewardIndex)
	end
	return randomRewards
end

function RewardService:ClaimDailyReward(Player: Player): Types.NetworkResponse
	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return {
			Success = false,
			Response = "Player data not found.",
		}
	else
		local playerResources = playerDocument:read().Resources
		local playerRewards = RewardService:GenerateDailyRewards(playerResources.RewardSeed)
		local HoursSinceLastClaim = (os.time() - playerResources.LastRewardClaim) / 3600
		if playerResources.LastRewardClaim == -1 then -- first time claiming
			ResourceService:SetResource(Player, "LastRewardClaim", os.time())
			ResourceService:SetResource(Player, "RewardDay", 2)
			RewardService.RewardClaimed:Fire(Player, Rewards[playerRewards[1]])
			return {
				Success = true,
				Response = "Reward claimed!",
			}
		else
			if HoursSinceLastClaim >= 24 and HoursSinceLastClaim < 48 then
				-- Consecutive Claim
				ResourceService:SetResource(Player, "LastRewardClaim", os.time())
				local rewDay = playerResources.RewardDay
				if rewDay + 1 > #self.DailyRewards then
					-- Last Day claimed
					-- Reset Reward Seed
					ResourceService:SetResource(Player, "RewardSeed", os.time())
					ResourceService:SetResource(Player, "RewardDay", 1)
				else
					ResourceService:SetResource(Player, "RewardDay", rewDay + 1)
				end
				RewardService.RewardClaimed:Fire(Player, Rewards[playerRewards[rewDay]])
				return {
					Success = true,
					Response = "Reward claimed!",
				}
			elseif HoursSinceLastClaim >= 48 then
				-- Reset
				ResourceService:SetResource(Player, "LastRewardClaim", os.time())
				ResourceService:SetResource(Player, "RewardDay", 2)
				ResourceService:SetResource(Player, "RewardSeed", os.time())
				RewardService.RewardClaimed:Fire(Player, Rewards[playerRewards[1]])
				return {
					Success = true,
					Response = "Reward claimed!",
				}
			end
		end
		return {
			Success = false,
			Response = "You can't claim a reward yet!",
		}
	end
end

return RewardService
