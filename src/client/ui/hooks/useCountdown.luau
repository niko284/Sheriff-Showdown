--!strict
local RunService = game:GetService("RunService")

local React = require("@packages/React")

-- useCountdown(secondsRemaining) will return a binding that will continuously decrement the time remaining
-- from the secondsRemaining argument until reaching zero. If <0, countdown automatically at 0.

local function useCountdown(seconds: number)
	local timeRemaining, setTimeRemaining = React.useBinding(seconds)

	React.useEffect(function()
		local updateBinding
		updateBinding = RunService.PreSimulation:Connect(function(dt)
			local timeLeft = math.max(timeRemaining:getValue() - dt, 0)
			setTimeRemaining(timeLeft)
			if timeLeft == 0 then
				updateBinding:Disconnect()
				return
			end
		end)
		return function()
			updateBinding:Disconnect()
		end
	end)

	React.useEffect(function()
		setTimeRemaining(seconds > 0 and seconds or 0)
	end, { seconds })

	return timeRemaining
end

return useCountdown
