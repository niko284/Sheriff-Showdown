--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.packages.React)

local function ContextStack(props: {
	providers: { React.ReactElement<any, any> },
	children: React.ReactNode,
})
	local mostRecent = props.children

	for providerIndex = #props.providers, 1, -1 do
		mostRecent = React.cloneElement(props.providers[providerIndex], nil, mostRecent)
	end

	return mostRecent
end

return ContextStack
