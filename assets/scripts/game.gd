extends Node2D

@export var shake_strength_min: float = 0.35
@export var shake_strength_max: float = 3.0
@export var asteroid_speed_multiplier_max: float = 2.4
@export var rocket_screen_margin: float = 40.0

@onready var rocket: Rocket = $Rocket
@onready var asteroid_pool: AsteroidPool = $Managers/AsteroidPool
@onready var asteroid_spawner: AsteroidSpawner = $Managers/AsteroidSpawner


func _ready() -> void:
	var rect := Utils.get_visible_world_rect().grow(-rocket_screen_margin)
	var follower := rocket.get_node_or_null("FingerFollower") as FollowFinger2D
	if follower != null:
		follower.area = rect
	rocket.died.connect(_on_rocket_died)


func _process(_delta: float) -> void:
	if not is_instance_valid(rocket) or rocket.is_dead():
		return

	var rect := Utils.get_visible_world_rect()
	var danger := clampf(
		inverse_lerp(rect.end.y, rect.position.y, rocket.global_position.y),
		0.0,
		1.0
	)

	rocket.set_danger(danger)
	asteroid_spawner.difficulty = danger
	asteroid_pool.speed_multiplier = lerpf(1.0, asteroid_speed_multiplier_max, danger)


func _on_rocket_died() -> void:
	asteroid_spawner.stop()
