--!strict

-- // Variables \\

local React = require("@packages/React")

-- // Use Attribute \\

local function useAttribute(Instance: Instance?, AttributeName: string)
	local attributeValue, setAttributeValue = React.useState(function()
		return Instance and Instance:GetAttribute(AttributeName) or nil
	end)

	React.useEffect(function()
		local connection = nil
		if Instance then
			connection = Instance:GetAttributeChangedSignal(AttributeName):Connect(function()
				setAttributeValue(Instance:GetAttribute(AttributeName))
			end)
		end

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, { Instance, AttributeName, setAttributeValue } :: { any })

	return attributeValue
end

return useAttribute
