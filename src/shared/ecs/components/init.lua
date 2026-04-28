local jecs = require("@packages/jecs")

export type StatusEffect = {
	expiry: number?,
	processRemoval: boolean?,
}

export type AnimationTrack = {
	track: AnimationTrack?,
	looped: boolean,
	speed: number,
	played: boolean,
}

export type DestructionRadius = {
	radius: number,
	shape: "Sphere" | "Box",
	falloff: "None" | "Linear",
	explosionForce: number,
	debrisLifetime: number,
}

export type Projectile = {
	gunId: number?,
	filter: { Instance }?,
	origin: CFrame?,
}

export type VoxelConfig = {
	cellSize: number,
	solid: boolean,
}

export type VoxelGrid = {
	data: buffer,
	sizeX: number,
	sizeY: number,
	sizeZ: number,
	cellSize: number,
}

export type Collided = {
	raycastResult: RaycastResult?,
}

export type Cooldown = {
	expiry: number,
}

export type ExtendedHitbox = {
	hitbox: BasePart,
}

export type Gun = {
	LocalCooldownMillis: number,
	ReloadTimeMillis: number,
	Damage: number,
	CriticalDamage: { [string]: number },
	BulletLifeTime: number,
	MaxCapacity: number,
	ReloadTime: number,
	CurrentCapacity: number,
	BulletSpeed: number,
	BulletSoundId: number,
	KnockStrength: number,
	Disabled: boolean?,
	Reloading: boolean?,
	VoxelDestructionRadius: number?,
	VoxelExplosionForce: number?,
	VoxelDebrisLifetime: number?,
}

export type Health = {
	health: number,
	maxHealth: number,
	regenRate: number,
	causedBy: number?,
}

export type Identifier = {
	uuid: string,
}

export type Item = {
	Id: number,
}

export type Killed = StatusEffect & {
	killerEntityId: number,
	markedKill: boolean?,
}

export type Knocked = StatusEffect & {
	direction: Vector3,
	strength: number,
	applied: boolean,
	force: BodyVelocity?,
}

export type Lifetime = {
	expiry: number,
}

export type Children = {
	[string]: number,
}

export type StatModifier = {
	Category: "Flat" | "PercentSum" | "Mult",
	Stat: string,
	Value: number,
}

export type MerryGoRound = {
	targetAngularVelocity: number,
	currentAngularVelocity: number,
	angularAcceleration: number,
	maxAngularVelocity: number,
	hardStopIn: number?,
}

export type Owner = {
	OwnedBy: Player,
}

export type PlayerComponent = {
	player: Player,
}

export type Renderable = {
	instance: Instance,
}

export type Target = {
	CanTarget: boolean,
}

export type Team = {
	name: string,
}

export type Transform = {
	cframe: CFrame,
	doNotReconcile: boolean?,
}

export type Velocity = {
	velocity: Vector3,
}

export type WalkSpeed = {
	speed: number,
	modifier: number,
}

return {
	Affects = jecs.component(),
	AnimatedRig = jecs.tag(),
	AnimationTrack = jecs.component() :: jecs.Id<AnimationTrack>,
	DestructionRadius = jecs.component() :: jecs.Id<DestructionRadius>,
	Projectile = jecs.component() :: jecs.Id<Projectile>,
	VoxelConfig = jecs.component() :: jecs.Id<VoxelConfig>,
	VoxelGrid = jecs.component() :: jecs.Id<VoxelGrid>,
	Voxelized = jecs.tag(),
	Children = jecs.component() :: jecs.Id<Children>,
	Collided = jecs.component() :: jecs.Id<Collided>,
	Cooldown = jecs.component() :: jecs.Id<Cooldown>,
	ExtendedHitbox = jecs.component() :: jecs.Id<ExtendedHitbox>,
	Gun = jecs.component() :: jecs.Id<Gun>,
	Health = jecs.component() :: jecs.Id<Health>,
	Identifier = jecs.component() :: jecs.Id<Identifier>,
	Item = jecs.component() :: jecs.Id<Item>,
	Killed = jecs.component() :: jecs.Id<Killed>,
	Knocked = jecs.component() :: jecs.Id<Knocked>,
	Lifetime = jecs.component() :: jecs.Id<Lifetime>,
	MerryGoRound = jecs.component() :: jecs.Id<MerryGoRound>,
	Owner = jecs.component() :: jecs.Id<Owner>,
	Player = jecs.component() :: jecs.Id<PlayerComponent>,
	Ragdolled = jecs.tag(),
	Renderable = jecs.component() :: jecs.Id<Renderable>,
	Slowed = jecs.tag(),
	StatModifier = jecs.component() :: jecs.Id<StatModifier>,
	Target = jecs.component() :: jecs.Id<Target>,
	Team = jecs.component() :: jecs.Id<Team>,
	Transform = jecs.component() :: jecs.Id<Transform>,
	Velocity = jecs.component() :: jecs.Id<Velocity>,
	WalkSpeed = jecs.component() :: jecs.Id<WalkSpeed>,
}
