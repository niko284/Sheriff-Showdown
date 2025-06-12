local Players = game:GetService("Players")

local Components = require("@ecs/components")
local Matter = require("@packages/Matter")
local MatterTypes = require("@ecs/MatterTypes")
local ResourceService = require("@services/ResourceService")
local StatisticsService = require("@services/StatisticsService")

type KilledRecord = MatterTypes.WorldChangeRecord<Components.Killed>

local function getPlayerKillerFromKilled(world: Matter.World, killed: Components.Killed): Player?
	local causedBy = killed.killerEntityId
	if not world:contains(causedBy) then
		return nil
	end
	local gun: Components.Gun? = world:get(causedBy, Components.Gun)
	if gun then -- only guns cause kills from players atm.
		local gunParent: Components.Parent? = world:get(causedBy, Components.Parent)
		if gunParent then
			local player: Components.PlayerComponent? = world:get(gunParent.id, Components.Player)
			if player then
				return player.player
			end
		end
	end
	return nil
end

local function killsAreProcessed(world: Matter.World)
	-- killed components are removed when they expire
	for eid, killed: MatterTypes.ComponentInstance<Components.Killed> in world:query(Components.Killed) do
		local renderable = world:get(eid, Components.Renderable) :: Components.Renderable<Model>?
		if os.time() >= killed.expiry then
			killed = killed:patch({ processRemoval = Matter.None })
			world:insert(eid, killed)
			local plrFromRenderable: Components.PlayerComponent? = world:get(eid, Components.Player)
			if not plrFromRenderable then
				plrFromRenderable = { player = Players:GetPlayerFromCharacter(renderable.instance) }
			end
			if plrFromRenderable then
				task.spawn(plrFromRenderable.player.LoadCharacter, plrFromRenderable.player)
			else
				if renderable and renderable.instance:IsDescendantOf(game) then
					renderable.instance:Destroy()
				end
			end
		end
	end

	-- killed entities are ragdolled
	for eid, killedRecord: KilledRecord in world:queryChanged(Components.Killed) do
		if killedRecord.new and not killedRecord.new.markedKill then -- killed entities are ragdolled
			local ragdolled = world:get(eid, Components.Ragdolled)
			if ragdolled == nil then
				world:insert(eid, Components.Ragdolled())
			end

			local killed = world:get(eid, Components.Killed)
			world:insert(
				eid,
				killed:patch({
					markedKill = true,
				})
			)

			local killedPlayerComponent: Components.PlayerComponent? = world:get(eid, Components.Player)
			local killedPlayer = killedPlayerComponent and killedPlayerComponent.player

			local killedByPlayer = getPlayerKillerFromKilled(world, killedRecord.new)
			if killedByPlayer and killedByPlayer ~= killedPlayer then -- don't count our own kills..
				StatisticsService:IncrementStatistic(killedByPlayer, "TotalKills", 1)
				ResourceService:IncrementResource(killedByPlayer, "Coins", 5)

				local longestKillStreak = StatisticsService:GetStatistic(killedByPlayer, "LongestKillStreak")

				local newKillStreak = StatisticsService:IncrementStatistic(killedByPlayer, "KillStreak", 1)

				if newKillStreak > longestKillStreak then
					StatisticsService:SetStatistic(killedByPlayer, "LongestKillStreak", newKillStreak)
				end
			end

			if killedPlayerComponent then
				StatisticsService:IncrementStatistic(killedPlayerComponent.player, "TotalDeaths", 1)

				local killStreak = StatisticsService:GetStatistic(killedPlayerComponent.player, "KillStreak")
				if killStreak > 0 then -- lost kill streak since we died
					StatisticsService:SetStatistic(killedPlayerComponent.player, "KillStreak", 0)
				end
			end
		end
	end
end

return {
	priority = 0,
	system = killsAreProcessed,
}
