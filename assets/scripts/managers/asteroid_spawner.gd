extends Node
class_name AsteroidSpawner

const SHOOTER_RATE_DIVIDER: float = 3.0

@export var asteroid_pool: AsteroidPool
@export var types: Array[AsteroidType] = []
@export var shooter_pool: ShooterEnemyPool

@export_group("Spawn rate")
@export var base_interval: float = 1.1
@export var min_interval: float = 0.25
@export_range(0.0, 1.0, 0.01) var interval_jitter: float = 0.25
@export var max_active: int = 180

@export_group("Placement")
@export var spawn_margin: float = 50.0
@export_range(0.0, 1.0, 0.01) var horizontal_spread: float = 0.35
@export var horizontal_padding: float = 24.0

var difficulty: float = 0.0
var distance: float = 0.0
var enabled: bool = true

var _timer: float = 0.0
var _total_weight: float = 0.0
var _last_tier: int = -1


func _ready() -> void:
	_timer = base_interval
	_apply_distance_weights()


func _process(delta: float) -> void:
	if not enabled or asteroid_pool == null:
		return

	_timer -= delta
	if _timer > 0.0:
		return

	var interval := lerpf(base_interval, min_interval, clampf(difficulty, 0.0, 1.0))
	interval *= randf_range(1.0 - interval_jitter, 1.0 + interval_jitter)
	_timer = maxf(0.05, interval)
	_spawn()


func stop() -> void:
	enabled = false


func _spawn() -> void:
	if asteroid_pool.active_count >= max_active:
		return

	_apply_distance_weights()
	var type := _pick_type()
	if type == null:
		return

	if type.id == &"shooter":
		_spawn_shooter()
		return

	var rect := Utils.get_visible_world_rect()
	var spawn_x := randf_range(rect.position.x + horizontal_padding, rect.end.x - horizontal_padding)
	var spawn_y := rect.position.y - spawn_margin
	var direction := Vector2.DOWN.rotated(randf_range(-horizontal_spread, horizontal_spread))
	var speed := randf_range(type.min_speed, type.max_speed)
	asteroid_pool.spawn(type, Vector2(spawn_x, spawn_y), direction, speed)


func _spawn_shooter() -> void:
	if shooter_pool == null:
		return
	var rect := Utils.get_visible_world_rect()
	var spawn_x := randf_range(rect.position.x + horizontal_padding, rect.end.x - horizontal_padding)
	var spawn_y := rect.position.y - spawn_margin
	shooter_pool.spawn(Vector2(spawn_x, spawn_y))


func _apply_distance_weights() -> void:
	var tier: int
	if distance < 5.0:
		tier = 0
	elif distance < 10.0:
		tier = 1
	elif distance < 20.0:
		tier = 2
	else:
		tier = 3
	if tier == _last_tier:
		return
	_last_tier = tier
	for t in types:
		if t == null:
			continue
		match t.id:
			&"medium_asteroid", &"medium":
				t.weight = 1.0 if tier == 0 else (1.0 if tier == 1 else (1.0 if tier == 2 else 3.0))
			&"large_asteroid", &"large":
				t.weight = 0.0 if tier == 0 else (1.0 if tier == 1 else (1.0 if tier == 2 else 5.0))
			&"shooter":
				t.weight = (0.0 if tier < 2 else (1.0 if tier == 2 else 3.0)) / SHOOTER_RATE_DIVIDER
	_recalculate_weights()


func _recalculate_weights() -> void:
	_total_weight = 0.0
	for type in types:
		if type != null and type.weight > 0.0:
			_total_weight += type.weight


func _pick_type() -> AsteroidType:
	if _total_weight <= 0.0:
		return null
	var roll := randf() * _total_weight
	for type in types:
		if type == null or type.weight <= 0.0:
			continue
		roll -= type.weight
		if roll <= 0.0:
			return type
	return null