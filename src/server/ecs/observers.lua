--!strict

local jecs = require("@packages/jecs")
local replecs = require("@packages/replecs")

local Components = require("@ecs/components")
local RagdollService = require("@services/RagdollService")
local ResourceService = require("@services/ResourceService")
local StatisticsService = require("@services/StatisticsService")

local function getKillerPlayer(world: jecs.World, killed: Components.Killed): Player?
	local causedBy = killed.killerEntityId
	if causedBy == 0 or not world:contains(causedBy) then
		return nil
	end
	local gun = world:get(causedBy, Components.Gun)
	if not gun then
		return nil
	end
	local parentId = world:parent(causedBy)
	if not parentId then
		return nil
	end
	local playerComp = world:get(parentId, Components.Player)
	return playerComp and playerComp.player or nil
end

local function registerServerObservers(world: jecs.World, services: { [string]: any })
	local StatusService = services.StatusService

	world:set(Components.Health, jecs.OnChange, function(entity: jecs.Entity, _id: jecs.Id, value: Components.Health)
		local renderable = world:get(entity, Components.Renderable)
		if not renderable then
			return
		end
		local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		if value.health <= 0 then
			humanoid.Health = 1
			if not world:has(entity, Components.Killed) then
				world:set(entity, Components.Killed, {
					killerEntityId = value.causedBy or 0,
					expiry = os.time() + 6,
					processRemoval = false,
				})
			end
		else
			humanoid.MaxHealth = value.maxHealth
			humanoid.Health = value.health
		end
	end)

	-- Killed OnAdd: ragdoll, statistics, knock impulse, StatusService signal.
	-- Consolidates logic from killsAreProcessed, targetsAreKnocked, and statusesAreProcessed.
	world:set(
		Components.Killed,
		jecs.OnAdd,
		function(entity: jecs.Entity, _id: jecs.Id, value: Components.Killed)
			world:add(entity, jecs.pair(replecs.reliable, Components.Killed))
			StatusService.StatusProcessed:Fire(entity, "Killed")

			if value.markedKill then
				return
			end

			if not world:has(entity, Components.Ragdolled) then
				world:add(entity, Components.Ragdolled)
				world:add(entity, jecs.pair(replecs.reliable, Components.Ragdolled))
			end

			world:set(entity, Components.Killed, {
				killerEntityId = value.killerEntityId,
				expiry = value.expiry,
				processRemoval = value.processRemoval,
				markedKill = true,
			})

			local killedPlayerComp = world:get(entity, Components.Player)
			local killedPlayer = killedPlayerComp and killedPlayerComp.player

			local killerPlayer = getKillerPlayer(world, value)
			if killerPlayer and killerPlayer ~= killedPlayer then
				StatisticsService:IncrementStatistic(killerPlayer, "TotalKills", 1)
				ResourceService:IncrementResource(killerPlayer, "Coins", 5)
				local longest = StatisticsService:GetStatistic(killerPlayer, "LongestKillStreak")
				local streak = StatisticsService:IncrementStatistic(killerPlayer, "KillStreak", 1)
				if streak > longest then
					StatisticsService:SetStatistic(killerPlayer, "LongestKillStreak", streak)
				end
			end

			if killedPlayerComp then
				StatisticsService:IncrementStatistic(killedPlayerComp.player, "TotalDeaths", 1)
				if StatisticsService:GetStatistic(killedPlayerComp.player, "KillStreak") > 0 then
					StatisticsService:SetStatistic(killedPlayerComp.player, "KillStreak", 0)
				end
			end

			local killedBy = value.killerEntityId
			local gun = (killedBy ~= 0 and world:contains(killedBy)) and world:get(killedBy, Components.Gun) or nil
			local targetRenderable = world:get(entity, Components.Renderable)

			if targetRenderable and targetRenderable.instance:FindFirstChild("HumanoidRootPart") then
				local hrp = targetRenderable.instance.HumanoidRootPart :: BasePart
				local direction: Vector3
				if gun then
					local killerParentId = world:parent(killedBy)
					local killerRenderable = killerParentId and world:get(killerParentId, Components.Renderable)
					if killerRenderable and killerRenderable.instance:FindFirstChild("HumanoidRootPart") then
						direction = (
							(hrp.Position - (killerRenderable.instance.HumanoidRootPart :: BasePart).Position) :: any
						).Unit
					else
						direction = -hrp.CFrame.LookVector
					end
					world:set(entity, Components.Knocked, {
						direction = direction,
						strength = gun.KnockStrength,
						expiry = DateTime.now().UnixTimestampMillis / 1000 + 0.1,
						applied = false,
					})
				else
					world:set(entity, Components.Knocked, {
						direction = -hrp.CFrame.LookVector,
						strength = 100,
						expiry = DateTime.now().UnixTimestampMillis / 1000 + 0.1,
						applied = false,
					})
				end
			end
		end
	)

	world:set(
		Components.Slowed,
		jecs.OnAdd,
		function(entity: jecs.Entity, _id: jecs.Id, _value: Components.Slowed)
			StatusService.StatusProcessed:Fire(entity, "Slowed")
		end
	)

	world:set(
		Components.Knocked,
		jecs.OnAdd,
		function(entity: jecs.Entity, _id: jecs.Id, _value: Components.Knocked)
			world:add(entity, jecs.pair(replecs.reliable, Components.Knocked))
			StatusService.StatusProcessed:Fire(entity, "Knocked")
		end
	)

	world:set(
		Components.Knocked,
		jecs.OnRemove,
		function(entity: jecs.Entity)
			if not world:contains(entity) then
				return
			end
			local knocked = world:get(entity, Components.Knocked)
			if knocked and knocked.force then
				knocked.force:Destroy()
			end
		end
	)

	world:set(
		Components.Ragdolled,
		jecs.OnRemove,
		function(entity: jecs.Entity)
			if not world:contains(entity) then
				return
			end
			local renderable = world:get(entity, Components.Renderable)
			if renderable then
				local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
				if humanoid then
					RagdollService:Unragdoll(renderable.instance :: any)
				end
			end
		end
	)
end

return registerServerObservers
