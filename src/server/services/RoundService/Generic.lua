--!strict

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local BlinkServer = require("@server/modules/BlinkServer")
local Components = require("@ecs/components")
local InventoryService = require("@services/InventoryService")
local InventoryUtils = require("@utilities/InventoryUtils")
local ItemUtils = require("@utilities/ItemUtils")
local Items = require("@constants/Items")
local Promise = require("@packages/Promise")
local RoundService = require("@services/RoundService")
local StatusService = require("@services/StatusService")
local Timer = require("@packages/Timer")
local Types = require("@constants/Types")

local Generic = {}

function Generic.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: jecs.World, equipGuns: boolean?)
	local roundModeData = RoundService:GetRoundModeData(RoundInstance.RoundMode)

	print("Starting match with mode:", RoundInstance.RoundMode, Match)
	for _, team in Match.Teams do
		for _, entityId in team.Entities do
			local target = World:get(entityId, Components.Target)
			if equipGuns ~= false then
				local plrComponent: Components.PlayerComponent? = World:get(entityId, Components.Player)

				local gunToUse: Types.ItemInfo = Items[2]

				if plrComponent then
					local inventory = InventoryService:GetInventory(plrComponent.player)
					local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
					if #equippedGuns > 0 then
						local itemInfo = ItemUtils.GetItemInfoFromId(equippedGuns[1].Id)
						if itemInfo then
							gunToUse = itemInfo
						end
					end
				end

				local gunId = World:entity()
				print("Created gun entity:", gunId)
				World:add(gunId, replecs.networked)
				World:set(gunId, Components.Gun, gunToUse.GunStatisticalData)
				World:add(gunId, jecs.pair(replecs.reliable, Components.Gun))
				World:set(gunId, Components.Item, { Id = gunToUse.Id })
				World:add(gunId, jecs.pair(replecs.reliable, Components.Item))
				World:add(gunId, jecs.pair(jecs.ChildOf, entityId :: any))
				World:add(gunId, jecs.pair(replecs.relation, jecs.ChildOf))
			end

			if target then
				World:set(entityId, Components.Target, { CanTarget = true })
			end
			World:set(entityId, Components.Team, { name = team.Name })
			World:add(entityId, jecs.pair(replecs.reliable, Components.Team))
		end
	end

	local statusProcessedConnection
	local timeLimitTimer = Timer.new(1)

	statusProcessedConnection = StatusService.StatusProcessed:Connect(function(EntityId: number, Status: Types.Status)
		local renderable: Components.Renderable? = World:get(EntityId, Components.Renderable)
		if Status == "Killed" and renderable then
			for _, team in Match.Teams do
				local isInTeam = table.find(team.Entities, EntityId)
				if isInTeam then
					table.insert(team.Killed, EntityId)

					local playerComponent: Components.PlayerComponent? = World:get(EntityId, Components.Player)

					World:set(EntityId, Components.Target, { CanTarget = false })

					if playerComponent then
						BlinkServer.RoundEndMatch.Fire(playerComponent.player, nil)
					end

					local winningTeam = RoundService:GetWinningTeam(Match)
					if winningTeam then
						RoundService.MatchFinished:Fire(Match.MatchUUID, winningTeam)
						statusProcessedConnection:Disconnect()
						timeLimitTimer:Destroy()
					end
				end
			end
		end
	end)

	if roundModeData.TimeLimit then
		local elapsedSeconds = 0
		timeLimitTimer.Tick:Connect(function()
			elapsedSeconds += 1
			if elapsedSeconds >= roundModeData.TimeLimit then
				RoundService.MatchFinished:Fire(Match.MatchUUID, nil)
				statusProcessedConnection:Disconnect()
				timeLimitTimer:Destroy()
			elseif roundModeData.TimeLimit - elapsedSeconds <= 60 then
				BlinkServer.RoundStatusSync.FireAll("TimeWarning")
			end
		end)
		timeLimitTimer:Start()
	end
end

function Generic.MatchFinishedPromise(Match: Types.Match)
	return Promise.fromEvent(RoundService.MatchFinished, function(MatchUUID: string, _WinningTeam: Types.Team)
		return MatchUUID == Match.MatchUUID
	end)
end

return Generic
