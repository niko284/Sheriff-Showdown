--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local React = require("@packages/React")
local RewardsContext = require("@ui/contexts/RewardsContext")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function RewardsProvider(props)
	local rewards, setRewards = useState({})

	useEffect(function()
		local disconnect = BlinkClient.RewardsSync.On(function(newRewards: { [string]: any })
			setRewards(newRewards)
		end)

		return disconnect
	end, {})

	return e(RewardsContext.Provider, {
		value = {
			rewards = rewards,
			set = setRewards,
		},
	}, props.children)
end

return RewardsProvider
