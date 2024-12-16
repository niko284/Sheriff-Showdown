local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local StatisticsService = require(Services.StatisticsService)

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
			print("Killed expired for ", renderable.instance.Name)
			local plrFromRenderable: Components.PlayerComponent? = world:get(eid, Components.Player)
			print("Plr from renderable initial", plrFromRenderable)
			if not plrFromRenderable then
				plrFromRenderable = { player = Players:GetPlayerFromCharacter(renderable.instance) }
				print("Trying to get player from character instead:", plrFromRenderable)
			end
			if plrFromRenderable then
				print("Respawning ", plrFromRenderable.player.Name)
				task.spawn(plrFromRenderable.player.LoadCharacter, plrFromRenderable.player)
			else
				if renderable and renderable.instance:IsDescendantOf(game) then
					print("Destroying ", renderable.instance.Name)
					renderable.instance:Destroy()
				end
			end
		end
	end

	-- killed entities are ragdolled
	for eid, killedRecord: KilledRecord in world:queryChanged(Components.Killed) do
		if killedRecord.new then -- killed entities are ragdolled
			local ragdolled = world:get(eid, Components.Ragdolled)
			if ragdolled == nil then
				world:insert(eid, Components.Ragdolled())
			end

			local killedByPlayer = getPlayerKillerFromKilled(world, killedRecord.new)
			if killedByPlayer then
				StatisticsService:IncrementStatistic(killedByPlayer, "TotalKills", 1)
				local longestKillStreak = StatisticsService:GetStatistic(killedByPlayer, "LongestKillStreak")

				local newKillStreak = StatisticsService:IncrementStatistic(killedByPlayer, "KillStreak", 1)

				if newKillStreak > longestKillStreak then
					StatisticsService:SetStatistic(killedByPlayer, "LongestKillStreak", newKillStreak)
				end
			end

			local killedPlayer: Components.PlayerComponent? = world:get(eid, Components.Player)
			if killedPlayer then
				StatisticsService:IncrementStatistic(killedPlayer.player, "TotalDeaths", 1)

				local killStreak = StatisticsService:GetStatistic(killedPlayer.player, "KillStreak")
				if killStreak > 0 then -- lost kill streak since we died
					StatisticsService:SetStatistic(killedPlayer.player, "KillStreak", 0)
				end
			end
		end
	end
end

return {
	priority = 0,
	system = killsAreProcessed,
}
