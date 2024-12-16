local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(Packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

type HealthRecord = MatterTypes.WorldChangeRecord<Components.Health>

local useDeltaTime = Matter.useDeltaTime

local function healthUpdates(world: Matter.World)
	local deltaTime = useDeltaTime()
	-- regenerate health
	for eid, health in world:query(Components.Health) do
		if health.regenRate ~= 0 and health.health ~= health.maxHealth then
			health = health:patch({ health = math.min(health.health + health.regenRate * deltaTime, health.maxHealth) })
			world:insert(eid, health)
		end
	end

	-- apply health to entities with renderable components when the health changes
	for eid, healthRecord: HealthRecord in world:queryChanged(Components.Health) do
		if healthRecord.new then
			local renderable = world:get(eid, Components.Renderable) :: Components.Renderable?
			if renderable then
				local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
				if humanoid then
					if healthRecord.new.health <= 0 then
						humanoid.Health = 1 -- set to 1 so the character doesn't die immediately
						-- insert kill logic afterwards:
						print("Killed ", renderable.instance.Name)
						world:insert(
							eid,
							Components.Killed({
								killerEntityId = healthRecord.new.causedBy,
								expiry = os.time() + 6, -- 6 seconds duration
							})
						)
					else
						humanoid.MaxHealth = healthRecord.new.maxHealth or humanoid.MaxHealth
						humanoid.Health = healthRecord.new.health
					end
				end
			end
		end
	end
end

return healthUpdates
