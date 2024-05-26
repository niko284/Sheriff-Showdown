local Components = {}

for _, ComponentModule in ipairs(script:GetChildren()) do
	local Component = require(ComponentModule)
	Components[tostring(Component)] = Component
end

export type Renderable = {
	instance: Instance,
}
export type Gun = {
	Damage: number,
	MaxCapacity: number,
	ReloadTime: number,
	CurrentCapacity: number,
	LocalCooldownMillis: number,
	BulletSpeed: number,
	BulletLifeTime: number,
	BulletSoundId: number,
	CriticalDamage: { [string]: number },
}
export type Owner = {
	OwnedBy: Player?,
}
export type Transform = {
	cframe: CFrame,
	doNotReconcile: boolean?,
}
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
export type Target = {}
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
}
export type WalkSpeed = {
	speed: number,
	modifier: number,
}
export type Health = {
	health: number,
	maxHealth: number,
	regenRate: number, -- amount of health regenerated per second
	causedBy: number?, -- entity id of the entity that caused the damage
}
export type Item = {
	Id: number,
}
export type Team = {
	name: string,
}
export type Killed = {
	killerEntityId: number,
	expiry: number,
}
export type Ragdolled = {}

return Components
