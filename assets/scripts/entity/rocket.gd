extends Node2D

@export var pool: BulletPool
@export var hp: float = 1
@export var damage: float = 1
@export var shoot_cooldown: float = 0.5
@export var bullet_speed: float = 900.0
@export var auto_shoot: bool = true

@onready var _shoot_point: Node2D = $ShootPoint

var _shoot_timer: float = 0.0


func _process(delta: float) -> void:
	if not auto_shoot or pool == null:
		return

	_shoot_timer -= delta
	if _shoot_timer > 0.0:
		return

	_shoot()
	_shoot_timer = shoot_cooldown


func _shoot() -> void:
	var bullet := pool.spawn(
		_shoot_point.global_position,
		-_shoot_point.global_transform.y.normalized()
	)
	if bullet == null:
		return

	bullet.speed = bullet_speed
	bullet.damage = damage
