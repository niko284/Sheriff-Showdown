--!strict

local Components = require("@ecs/components")
local InventoryService = require("@services/InventoryService")
local InventoryUtils = require("@utilities/InventoryUtils")
local Items = require("@constants/Items")
local Matter = require("@packages/Matter")
local Net = require("@packages/Net")
local Promise = require("@packages/Promise")
local Remotes = require("@network/Remotes")
local RoundService = require("@services/RoundService")
local StatusService = require("@services/StatusService")
local Timer = require("@packages/Timer")
local Types = require("@constants/Types")

local RoundNamespace = Remotes.Server:GetNamespace("Round")
local EndMatchClient = RoundNamespace:Get("EndMatch") :: Net.ServerSenderEvent

-- Generic functions that are used in our Round Service, particularly our mode extensions.
local Generic = {}

function Generic.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: Matter.World, equipGuns: boolean?)
	-- start the match by inserting our equipped guns into the world and assigning our players to the teams.

	local roundModeData = RoundService:GetRoundModeData(RoundInstance.RoundMode)

	for _, team in Match.Teams do
		for _, entityId in team.Entities do
			local target = World:get(entityId, Components.Target)
			if equipGuns ~= false then
				local plrComponent: Components.PlayerComponent? = World:get(entityId, Components.Player)
				local childrenComp: Components.Children<Types.TargetChildren> = World:get(entityId, Components.Children)

				local newChildren = childrenComp and table.clone(childrenComp.children or {})

				local gunToUse = Items[2] -- default gun if nothing is equipped

				if plrComponent then
					local inventory = InventoryService:GetInventory(plrComponent.player)
					local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
					if #equippedGuns > 0 then
						gunToUse = equippedGuns[1] :: any
					end
				end

				local gunId = World:spawn(
					Components.Gun(gunToUse.GunStatisticalData),
					Components.Owner({
						OwnedBy = plrComponent and plrComponent.player,
					}),
					Components.Item({ Id = gunToUse.Id }),
					Components.Parent({ id = entityId }),
					Components.Children({ children = {} })
				)
				newChildren.gunEntityId = gunId

				World:insert(entityId, childrenComp:patch({ children = newChildren }))
			end

			World:insert(entityId, target:patch({ CanTarget = true }))
			World:insert(entityId, Components.Team({ name = team.Name }))
		end
	end

	local statusProcessedConnection
	local timeLimitTimer = Timer.new(1)

	statusProcessedConnection = StatusService.StatusProcessed:Connect(function(EntityId: number, Status: Types.Status)
		local renderable: Components.Renderable<Model> = World:get(EntityId, Components.Renderable)
		if Status == "Killed" and renderable then
			for _, team in Match.Teams do
				local isInTeam = table.find(team.Entities, EntityId)
				if isInTeam then
					table.insert(team.Killed, EntityId)

					local target = World:get(EntityId, Components.Target)
					local playerComponent: Components.PlayerComponent? = World:get(EntityId, Components.Player)

					if target then
						World:insert(EntityId, target:patch({ CanTarget = false }))
					end
					World:insert(EntityId, Components.Children({ children = {} }))

					if playerComponent then
						EndMatchClient:SendToPlayer(playerComponent.player)
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
				-- time limit reached, end round no one wins

				RoundService.MatchFinished:Fire(Match.MatchUUID, nil)

				statusProcessedConnection:Disconnect()
				timeLimitTimer:Destroy()
			elseif roundModeData.TimeLimit - elapsedSeconds <= 60 then
				RoundService.RoundStatus:Set("TimeWarning")
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
