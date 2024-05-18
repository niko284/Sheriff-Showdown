local Components = {}

for _, ComponentModule in ipairs(script:GetChildren()) do
	local Component = require(ComponentModule)
	Components[tostring(Component)] = Component
end

export type Renderable = {
	instance: Instance,
}
export type Gun = {
	FireRate: number,
	Damage: number,
	MaxCapacity: number,
	ReloadTime: number,
	CurrentCapacity: number,
	LocalCooldownMillis: number,
	BulletLifeTime: number,
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
}
export type Target = {}
export type Collided = {
	raycastResult: RaycastResult?,
}
export type Cooldown = {
	expiry: number,
}

return Components
