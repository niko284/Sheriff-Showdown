-- Combat Utils
-- February 3rd, 2024
-- Nick

-- // Variables \\

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local EffectUtils = require(Utils.EffectUtils)
local Types = require(Constants.Types)

local CombatUtils = {}

function CombatUtils.Knockback(_Actor: Types.Entity, Entity: Types.Entity)
	EffectUtils.UnlockCharacter(Entity) -- Might've been locked if we're interrupting an ability the entity was doing.

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.one * Entity.HumanoidRootPart.AssemblyMass * workspace.Gravity * 100
	bodyVelocity.Velocity = -Entity.HumanoidRootPart.CFrame.LookVector * 100 + Vector3.new(0, 100, 0)
	bodyVelocity.Parent = Entity.HumanoidRootPart

	Debris:AddItem(bodyVelocity, 0.3)
end

return CombatUtils
