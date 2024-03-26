--!strict

-- Use Hook with Ref Callback
-- December 5th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)

local useState = React.useState
local useCallback = React.useCallback

-- // Hook \\

local function useHookWithRefCallback(): (any, (node: GuiObject) -> ())
	local refState, setRefState = useState(React.createRef())
	local assignRef = useCallback(function(node: GuiObject?)
		if node and refState.current ~= node then -- If the node is not nil and the ref is not already assigned to the node. This prevents the ref from being reassigned to the same node.
			local ref = React.createRef()
			ref.current = node
			setRefState(ref)
		end
	end, { refState, setRefState } :: { any })
	return refState, assignRef
end

return useHookWithRefCallback
