--!strict

-- Action Popup Manager
-- January 22nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Components = ReplicatedStorage.components

local AutomaticFrame = require(Components.frames.AutomaticFrame)
local React = require(Packages.React)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useCallback = React.useCallback

type ActionPopupManagerProps = Types.FrameProps & {
	padding: UDim,
	maxPopups: number,
	component: any,
	componentSize: UDim2,
	popupAdded: any,
	popupRemoved: any,
}
type ActionPopupInternal = {
	id: string,
	title: string?,
	isActive: boolean?,
}

-- // Action Popup Manager \\

local function ActionPopupManager(props: ActionPopupManagerProps)
	local actionPopups, setActionPopups = useState({} :: { ActionPopupInternal })

	local addActionPopup = useCallback(function(actionPopup: Types.ActionPopup & { UUID: string })
		setActionPopups(function(oldActionPopups)
			local newActionPopups = table.clone(oldActionPopups)
			table.insert(newActionPopups, 1, {
				key = actionPopup.UUID,
				id = actionPopup.UUID,
				title = actionPopup.State,
			})
			return newActionPopups
		end)
	end, { setActionPopups, props.padding } :: { any })

	local disableActionPopup = useCallback(function(id: string)
		setActionPopups(function(oldActionPopups: { ActionPopupInternal })
			local newActionPopups = table.clone(oldActionPopups)
			for i, actionPopup in newActionPopups do
				if actionPopup.id == id then
					newActionPopups[i] = table.clone(actionPopup)
					newActionPopups[i].isActive = false
					break
				end
			end
			return newActionPopups
		end)
	end, { setActionPopups })

	local removeActionPopup = useCallback(function(id: string)
		setActionPopups(function(oldActionPopups: { any })
			local newActionPopups = table.clone(oldActionPopups)
			for i, actionPopup in newActionPopups do
				if actionPopup.id == id then
					table.remove(newActionPopups, i)
					break
				end
			end
			return newActionPopups
		end)
	end, { setActionPopups })

	-- Create the actionPopup elements

	local actionPopupElements = {}
	for index, actionPopup in actionPopups do
		-- Check if the actionPopup is still valid.
		local isActive = index <= props.maxPopups
		if actionPopup.isActive == false then
			isActive = false -- the actionPopup was dismissed manually.
		end
		table.insert(
			actionPopupElements,
			e(
				props.component,
				Sift.Dictionary.merge(actionPopup, {
					size = props.componentSize,
					isActive = isActive,
					removeActionPopup = removeActionPopup,
				})
			)
		)
	end

	useEffect(function()
		local addedConnection = nil
		local removedConnection = nil
		if props.popupAdded then
			addedConnection = props.popupAdded:Connect(function(actionPopup: Types.ActionPopup & { UUID: string })
				addActionPopup(actionPopup)
			end)
		end
		if props.popupRemoved then
			removedConnection = props.popupRemoved:Connect(function(id: string)
				disableActionPopup(id)
			end)
		end
		return function()
			if addedConnection then
				addedConnection:Disconnect()
			end
			if removedConnection then
				removedConnection:Disconnect()
			end
		end
	end, { props.popupAdded, addActionPopup, disableActionPopup, props.popupRemoved })

	return e(AutomaticFrame, {
		instanceProps = {
			BackgroundTransparency = 1,
			Position = props.position,
			AnchorPoint = props.anchorPoint,
		},
	}, {
		elements = React.createElement(React.Fragment, nil, actionPopupElements),
	})
end

return ActionPopupManager
