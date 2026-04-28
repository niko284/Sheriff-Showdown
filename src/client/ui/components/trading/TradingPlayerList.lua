--!strict

local HttpService = game:GetService("HttpService")

local BlinkClient = require("@client/modules/BlinkClient")
local InterfaceController = require("@controllers/InterfaceController")
local NotificationController = require("@controllers/NotificationController")
local NotificationElement = require("@ui/components/notification/NotificationElement")
local PlayerSelectionList = require("@ui/components/frames/SelectionList/PlayerSelectionList")
local Promise = require("@packages/Promise")
local React = require("@packages/React")
local ResourceContext = require("@ui/contexts/ResourceContext")
local Types = require("@constants/Types")
local animateCurrentInterface = require("@ui/hooks/animateCurrentInterface")

local e = React.createElement
local useCallback = React.useCallback
local useContext = React.useContext

local TRADING_LEVEL_REQUIREMENT = 15

type TradingPlayerListProps = {}

local function TradingPlayerList(_props: TradingPlayerListProps)
	local _shouldRender, styles = animateCurrentInterface("Trading", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local resources = useContext(ResourceContext) :: any

	local sendTradeToPlayer = useCallback(function(_rbx: TextButton, player: Player)
		local level = resources and resources.Level
		if level and level < TRADING_LEVEL_REQUIREMENT then
			local tradeNotification: Types.Notification = {
				UUID = HttpService:GenerateGUID(false),
				Title = "Level Requirement",
				Description = `Must be level {TRADING_LEVEL_REQUIREMENT}+ to trade!`,
				Component = NotificationElement,
				Duration = 5,
				Props = {
					size = UDim2.fromOffset(303, 227),
				},
			}
			NotificationController:AddNotification(tradeNotification)
			return
		end

		Promise.new(function(resolve, reject)
			local ok, result = pcall(BlinkClient.TradingSendTradeToPlayer.Invoke, player)
			if ok then
				resolve(result)
			else
				reject(result)
			end
		end)
			:andThen(function(response: Types.NetworkResponse)
				--print(response)
				if response.Success == true then
					local tradeNotification: Types.Notification = {
						UUID = HttpService:GenerateGUID(false),
						Title = "Trade sent!",
						Description = `Successfully sent trade to {player.Name}`,
						Component = NotificationElement,
						Duration = 5,
						size = UDim2.fromOffset(303, 227),
					}
					NotificationController:AddNotification(tradeNotification)
				else
					local tradeNotification: Types.Notification = {
						UUID = HttpService:GenerateGUID(false),
						Title = "Trade failed.",
						Description = response.Message :: string,
						Component = NotificationElement,
						size = UDim2.fromOffset(303, 227),
						Duration = 5,
					}
					NotificationController:AddNotification(tradeNotification)
				end
			end)
			:catch(function(err)
				warn(tostring(err))
			end)
	end, { resources })

	local onClose = useCallback(function()
		InterfaceController.InterfaceChanged:Fire(nil)
	end, {})

	return e(PlayerSelectionList, {
		position = styles.position,
		listTitle = "Trading",
		selectionText = "Trade",
		subtitle = "Trading",
		selectionDescription = "Select a player to trade with!",
		selectionActivated = sendTradeToPlayer,
		onClose = onClose,
	})
end

return TradingPlayerList
