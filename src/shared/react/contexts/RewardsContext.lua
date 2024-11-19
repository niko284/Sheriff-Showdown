--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

return React.createContext({} :: {
	rewards: {
		daily: { RewardDay: number, LastRewardClaim: number, Rewards: { number } }?,
	},
	set: (newRewards: {
		daily: { RewardDay: number, LastRewardClaim: number, Rewards: { number } }?,
	}) -> (),
})
