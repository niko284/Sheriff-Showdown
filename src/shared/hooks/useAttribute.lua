-- Use Attribute
-- August 12th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)

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
	end, { Instance, AttributeName, setAttributeValue })

	return attributeValue
end

return useAttribute
