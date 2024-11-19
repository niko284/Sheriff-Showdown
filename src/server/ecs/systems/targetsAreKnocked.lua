--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)
local Types = require(ReplicatedStorage.constants.Types)

type KnockedChangeRecord = MatterTypes.WorldChangeRecord<Components.Knocked>
type KilledChangeRecord = MatterTypes.WorldChangeRecord<Components.Killed>

local function targetsAreKnocked(world: Matter.World)
	-- apply force to knocked targets
	for eid, renderable: Components.Renderable<Types.Character>, _target: Components.Target, knocked: Components.Knocked in
		world:query(Components.Renderable, Components.Target, Components.Knocked)
	do
		if not renderable.instance:FindFirstChild("HumanoidRootPart") then
			continue
		end
		local rootAttachment = renderable.instance.HumanoidRootPart:FindFirstChild("RootAttachment") :: Attachment?
		if rootAttachment then
			local bodyVelocity = knocked.force or Instance.new("BodyVelocity")

			local newVelocity = knocked.direction * knocked.strength
			if newVelocity ~= bodyVelocity.Velocity then
				bodyVelocity.Velocity = newVelocity
			end

			if not knocked.applied then
				bodyVelocity.MaxForce = Vector3.one * 1e7
				bodyVelocity.Velocity = newVelocity
				bodyVelocity.P = 1e4

				world:insert(eid, knocked:patch({ applied = true, force = bodyVelocity }))
				bodyVelocity.Parent = renderable.instance.HumanoidRootPart
			end
		end
	end

	-- cleanup force on expired knock
	for _eid, knockedRecord: KnockedChangeRecord in world:queryChanged(Components.Knocked) do
		if knockedRecord.old and knockedRecord.old.force and knockedRecord.new == nil then
			knockedRecord.old.force:Destroy()
		end
	end

	-- add knocked to killed entities
	for eid, killedRecord: KilledChangeRecord in world:queryChanged(Components.Killed) do
		if killedRecord.new then
			local killedBy = killedRecord.new.killerEntityId

			local gun = world:contains(killedBy) and world:get(killedBy, Components.Gun) :: Components.Gun?

			if gun then
				local parent: Components.Parent? = world:get(killedBy, Components.Parent)
				local killerRenderable = parent
					and world:get(parent.id, Components.Renderable) :: Components.Renderable<Types.Character>?
				if killerRenderable then
					local targetRenderable =
						world:get(eid, Components.Renderable) :: Components.Renderable<Types.Character>?
					if targetRenderable then
						local direction = (
							(
								targetRenderable.instance.HumanoidRootPart.Position
								- killerRenderable.instance.HumanoidRootPart.Position
							) :: any
						).Unit
						world:insert(
							eid,
							Components.Knocked({
								direction = direction,
								strength = gun.KnockStrength,
								expiry = DateTime.now().UnixTimestampMillis / 1000 + 0.1,
							})
						)
					end
				end
			else
				local targetRenderable =
					world:get(eid, Components.Renderable) :: Components.Renderable<Types.Character>?
				if targetRenderable then
					world:insert(
						eid,
						Components.Knocked({
							direction = -targetRenderable.instance.HumanoidRootPart.CFrame.LookVector,
							strength = 100,
							expiry = DateTime.now().UnixTimestampMillis / 1000 + 0.1,
						})
					)
				end
			end
		end
	end
end

return targetsAreKnocked
