--!strict

local React = require("@packages/React")
local RewardsContext = require("@ui/contexts/RewardsContext")

local ClientComm = require("@client/ClientComm")

local ReplicatedRewards = ClientComm:GetProperty("PlayerRewards")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function RewardsProvider(props)
	local rewards, setRewards = useState({})

	useEffect(function()
		local rewardsChanged = ReplicatedRewards:Observe(function(newRewards: { [string]: any })
			setRewards(newRewards)
		end)

		return function()
			rewardsChanged:Disconnect()
		end
	end, {})

	return e(RewardsContext.Provider, {
		value = {
			rewards = rewards,
			set = setRewards,
		},
	}, props.children)
end

return RewardsProvider
