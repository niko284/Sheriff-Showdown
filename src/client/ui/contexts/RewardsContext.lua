--!strict

local React = require("@packages/React")

return React.createContext({} :: {
	rewards: {
		daily: { RewardDay: number, LastRewardClaim: number, Rewards: { number } }?,
	},
	set: (newRewards: {
		daily: { RewardDay: number, LastRewardClaim: number, Rewards: { number } }?,
	}) -> (),
})
