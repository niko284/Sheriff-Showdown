local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = {}

local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

for _, ComponentModule in ipairs(script:GetChildren()) do
	local Component = require(ComponentModule)
	Components[tostring(Component)] = Component
end

export type Renderable<T> = {
	instance: T & Instance,
}
export type Gun = {
	Damage: number,
	Disabled: boolean?,
	MaxCapacity: number,
	ReloadTime: number,
	CurrentCapacity: number,
	LocalCooldownMillis: number,
	BulletSpeed: number,
	BulletLifeTime: number,
	BulletSoundId: number,
	KnockStrength: number,
	CriticalDamage: { [string]: number },
}
export type Parent = {
	id: number,
}
export type Owner = {
	OwnedBy: Player,
}
export type Transform = MatterTypes.ComponentInstance<{
	cframe: CFrame,
	doNotReconcile: boolean?,
}>
export type Velocity = {
	velocity: Vector3,
}
export type Lifetime = {
	expiry: number,
}
export type Bullet = {
	gunId: number?,
	filter: { Instance }?,
	origin: CFrame,
}
export type Target = {
	CanTarget: boolean,
}
export type Collided = {
	raycastResult: RaycastResult?,
}
export type Cooldown = {
	expiry: number,
}
export type Identifier = {
	uuid: string,
}
export type Slowed = {
	walkspeedMultiplier: number,
} & StatusEffect

export type Knocked = MatterTypes.ComponentInstance<{
	direction: Vector3,
	strength: number,
	applied: boolean,
	force: BodyVelocity?,
} & StatusEffect>

export type WalkSpeed = {
	speed: number,
	modifier: number,
}
export type Health = {
	health: number,
	maxHealth: number,
	regenRate: number, -- amount of health regenerated per second
	causedBy: number?, -- entity id of the entity that caused the damage
} & { [string]: any }
export type Item = {
	Id: number,
}
export type Team = {
	name: string,
}

export type StatusEffect = {
	expiry: number?,
	processRemoval: boolean?,
}

export type Killed = {
	killerEntityId: number,
} & StatusEffect
export type Ragdolled = {}
export type PlayerComponent = {
	player: Player,
}
export type Children<T> = MatterTypes.ComponentInstance<{
	children: T,
}>
export type MerryGoRound = {
	targetAngularVelocity: number,
	currentAngularVelocity: number,
	angularAcceleration: number,
	maxAngularVelocity: number,
}

export type Animation = {
	animationId: number,
	looped: boolean,
	speed: number,
}

return Components
