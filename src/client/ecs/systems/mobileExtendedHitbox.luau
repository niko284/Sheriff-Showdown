--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Input = require(Packages.Input)
local Matter = require(Packages.Matter)
local Types = require(ReplicatedStorage.constants.Types)

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Other = Assets:FindFirstChild("other") :: Folder

local EXTENDED_HITBOX = Other:FindFirstChild("ExtendedHitbox") :: BasePart

local PreferredInput = Input.PreferredInput

local function mobileExtendedHitbox(world: Matter.World)
	for entityId, renderable: Components.Renderable<Types.Character>, _target in
		world:query(Components.Renderable, Components.Target):without(Components.ExtendedHitbox)
	do
		if PreferredInput.Current == "Touch" then
			local hrp = renderable.instance.HumanoidRootPart

			local extendedHitbox = EXTENDED_HITBOX:Clone()
			extendedHitbox.CanCollide = false
			extendedHitbox.Massless = true
			extendedHitbox.Anchored = false
			extendedHitbox.CFrame = CFrame.new(hrp.CFrame.Position) * CFrame.Angles(0, 0, math.rad(90))
			extendedHitbox.Parent = renderable.instance

			local weldConst = Instance.new("WeldConstraint")
			weldConst.Part0 = hrp
			weldConst.Part1 = extendedHitbox
			weldConst.Parent = extendedHitbox

			world:insert(
				entityId,
				Components.ExtendedHitbox({
					hitbox = extendedHitbox,
				})
			)
		end
	end

	for
		entityId,
		_renderable: Components.Renderable<Types.Character>,
		_target,
		extendedHitbox: Components.ExtendedHitbox
	in world:query(Components.Renderable, Components.Target, Components.ExtendedHitbox) do
		if PreferredInput.Current ~= "Touch" then
			extendedHitbox.hitbox:Destroy()
			world:remove(entityId, Components.ExtendedHitbox)
		end
	end
end

return mobileExtendedHitbox
