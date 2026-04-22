class_name Upgrade extends Node

@export var Mod : StatChange
@export var ModHow : HowToApply
@export var ModAmount : float

enum StatChange{
	None,
	MoveSpeed,
	TurnSpeed,
	BarrelAimSpeed,
	Health,
	Friction,
	Acceleration,
	MaxBulletsOut,
	PlayerSize,
	BulletCooldown,
	BulletEvenSpread,
	
	BulletDamage,
	BulletSpeed,
	BulletHealth,
	BulletSpread,
	BulletCount,
	BulletBurst,
	BulletBounces,
	BulletSize,
	BulletBounceOffEnemy,
	BulletLifetime,
	
	BulletTron,
	BulletTrailLength,
	
	MineExplosionRadius,
	MineExplosionDamage,
	MineExplosionTimer,
	MineSize,
	MaxMinesOut,
	
}

enum HowToApply{
	None,
	Multiply,
	Add,
	Set,
}
