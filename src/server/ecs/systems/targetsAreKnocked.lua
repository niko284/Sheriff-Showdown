--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function targetsAreKnocked(world: jecs.World)
	for eid, renderable, _target, knocked in world:query(Components.Renderable, Components.Target, Components.Knocked) do
		local hrp = renderable.instance:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			continue
		end
		local rootAttachment = hrp:FindFirstChild("RootAttachment") :: Attachment?
		if not rootAttachment then
			continue
		end

		local bodyVelocity = knocked.force or Instance.new("BodyVelocity")
		local newVelocity = knocked.direction * knocked.strength

		if not knocked.applied then
			bodyVelocity.MaxForce = Vector3.one * 1e7
			bodyVelocity.Velocity = newVelocity
			bodyVelocity.P = 1e4
			bodyVelocity.Parent = hrp
			world:set(eid, Components.Knocked, {
				direction = knocked.direction,
				strength = knocked.strength,
				expiry = knocked.expiry,
				applied = true,
				force = bodyVelocity,
			})
		elseif newVelocity ~= bodyVelocity.Velocity then
			bodyVelocity.Velocity = newVelocity
		end
	end
	-- Force cleanup on Knocked removal is handled by the OnRemove observer in server/ecs/observers.lua.
	-- Knock impulse on kill is handled by the Killed OnAdd observer in server/ecs/observers.lua.
end

return targetsAreKnocked
