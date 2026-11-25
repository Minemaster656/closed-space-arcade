extends Node
class_name AsteroidSpawner

## Спавнер объектов активной локации. Не знает о конкретных астероидах/врагах:
## берёт взвешенную запись из LocationDef и просит SpawnUtil заспавнить её.
## Тиры сложности и редкие типы тоже описаны данными (SpawnEntry), а не хардкодом.

@export var asteroid_pool: AsteroidPool
@export var enemy_pool: EnemyPool
@export var location: LocationDef

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
var _tier: int = -1


func _ready() -> void:
	_timer = base_interval


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

	_update_tier()
	var entry := _pick_entry()
	if entry == null:
		return

	var rect := Utils.get_visible_world_rect()
	var spawn_x := randf_range(rect.position.x + horizontal_padding, rect.end.x - horizontal_padding)
	var spawn_y := rect.position.y - spawn_margin
	var direction := Vector2.DOWN.rotated(randf_range(-horizontal_spread, horizontal_spread))
	SpawnUtil.spawn(entry.spawn, Vector2(spawn_x, spawn_y), direction, 0.0)


func _update_tier() -> void:
	var tier := _tier_for_distance()
	if tier == _tier:
		return
	_tier = tier


func _tier_for_distance() -> int:
	if distance < 5.0:
		return 0
	elif distance < 10.0:
		return 1
	elif distance < 20.0:
		return 2
	return 3


func _pick_entry() -> SpawnEntry:
	if location == null:
		return null

	# Сначала редкие типы с независимым шансом.
	for entry in location.entries:
		if entry == null or entry.spawn == null or entry.spawn_chance <= 0.0:
			continue
		if randf() < entry.spawn_chance:
			return entry

	var total := 0.0
	for entry in location.entries:
		total += _entry_weight(entry)
	if total <= 0.0:
		return null

	var roll := randf() * total
	for entry in location.entries:
		var weight := _entry_weight(entry)
		if weight <= 0.0:
			continue
		roll -= weight
		if roll <= 0.0:
			return entry
	return null


func _entry_weight(entry: SpawnEntry) -> float:
	if entry == null or entry.spawn == null:
		return 0.0
	if not entry.tier_weights.is_empty():
		var index := clampi(_tier, 0, entry.tier_weights.size() - 1)
		return maxf(0.0, entry.tier_weights[index])
	return maxf(0.0, entry.weight)