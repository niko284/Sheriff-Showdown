--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local React = require("@packages/React")
local Sift = require("@packages/Sift")
local StatisticsContext = require("@ui/contexts/StatisticsContext")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function StatisticsProvider(props)
	local statistics, setStatistics = useState({})

	useEffect(function()
		local disconnect = BlinkClient.StatisticsSync.On(function(newStatistics: { [string]: any })
			setStatistics(function(oldStatistics: { [string]: any })
				return Sift.Dictionary.join(oldStatistics, newStatistics)
			end)
		end)

		return disconnect
	end, {})

	return e(StatisticsContext.Provider, {
		value = statistics,
	}, props.children)
end

return StatisticsProvider
