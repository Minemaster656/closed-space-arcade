extends Node
class_name AsteroidSpawner

## Спавнер волн активной локации. Не знает о конкретных астероидах/врагах:
## прокатывает пулы волны (старт/конец) и постоянные веса, а затем просит
## SpawnUtil (или CometSpawner для комет) заспавнить выбранный definition.
##
## Волны идут по дистанции: каждые length_meters активная волна сменяется,
## пока не дойдёт до последней. На границе волны спавнится её end_pool и
## start_pool следующей волны. После последней волны игра продолжается.

@export var asteroid_pool: AsteroidPool
@export var enemy_pool: EnemyPool
@export var comet_spawner: CometSpawner
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

## Оставляем для совместимости: игра выставляет опасность, спавнер масштабирует
## ею интервал постоянного спавна.
var difficulty: float = 0.0
var distance: float = 0.0
var enabled: bool = true

var _timer: float = 0.0
var _waves: Array[WaveDef] = []
var _wave_start: PackedFloat32Array = PackedFloat32Array()
var _wave_end: PackedFloat32Array = PackedFloat32Array()
var _start_done: Array[bool] = []
var _end_done: Array[bool] = []
var _current_wave: int = 0
var _built: bool = false


func _ready() -> void:
	_timer = base_interval
	_rebuild_waves()


func _process(delta: float) -> void:
	if not enabled or asteroid_pool == null:
		return

	_update_waves()

	_timer -= delta
	if _timer > 0.0:
		return

	var interval := lerpf(base_interval, min_interval, clampf(difficulty, 0.0, 1.0))
	interval *= randf_range(1.0 - interval_jitter, 1.0 + interval_jitter)
	_timer = maxf(0.05, interval)
	_spawn_ongoing()


func stop() -> void:
	enabled = false


## Пересобирает границы волн. Вызывается при смене локации.
func set_location(value: LocationDef) -> void:
	location = value
	_rebuild_waves()


func _rebuild_waves() -> void:
	_waves.clear()
	_wave_start.clear()
	_wave_end.clear()
	_start_done.clear()
	_end_done.clear()
	_current_wave = 0
	_built = location != null
	if not _built:
		return

	var cursor := 0.0
	for wave in location.waves:
		if wave == null:
			continue
		var length := maxf(0.0, wave.length_meters)
		_waves.append(wave)
		_wave_start.append(cursor)
		cursor += length
		_wave_end.append(cursor)
		_start_done.append(false)
		_end_done.append(false)
	_built = not _waves.is_empty()


func _update_waves() -> void:
	if not _built:
		return

	for i in _waves.size():
		if not _start_done[i] and distance >= _wave_start[i]:
			_start_done[i] = true
			_spawn_pool(_waves[i].start_pool)
		if not _end_done[i] and distance >= _wave_end[i]:
			_end_done[i] = true
			_spawn_pool(_waves[i].end_pool)

	_current_wave = _wave_index_for_distance()


func _wave_index_for_distance() -> int:
	var index := 0
	for i in _wave_start.size():
		if distance >= _wave_start[i]:
			index = i
	return index


func _spawn_ongoing() -> void:
	if asteroid_pool.active_count >= max_active:
		return
	var wave := _current_wave_def()
	if wave == null or wave.entries.is_empty():
		return

	var entry := _pick_entry(wave.entries)
	if entry == null:
		return
	_spawn_definition(entry.spawn)


func _current_wave_def() -> WaveDef:
	if not _built:
		return null
	var index := clampi(_current_wave, 0, _waves.size() - 1)
	return _waves[index]


func _spawn_pool(pool: SpawnPool) -> void:
	if pool == null:
		return
	for definition in pool.roll():
		_spawn_definition(definition)


func _spawn_definition(definition: Resource) -> void:
	if definition == null:
		return
	if definition is CometType:
		if comet_spawner != null:
			comet_spawner.spawn_comet()
		return

	var rect := Utils.get_visible_world_rect()
	var spawn_x := randf_range(rect.position.x + horizontal_padding, rect.end.x - horizontal_padding)
	var spawn_y := rect.position.y - spawn_margin
	var dir := Vector2.DOWN.rotated(randf_range(-horizontal_spread, horizontal_spread))
	SpawnUtil.spawn(definition, Vector2(spawn_x, spawn_y), dir, 0.0)


func _pick_entry(entries: Array[SpawnEntry]) -> SpawnEntry:
	var total := 0.0
	for entry in entries:
		if entry != null and entry.spawn != null:
			total += maxf(0.0, entry.weight)
	if total <= 0.0:
		return null

	var roll := randf() * total
	for entry in entries:
		if entry == null or entry.spawn == null:
			continue
		roll -= maxf(0.0, entry.weight)
		if roll <= 0.0:
			return entry
	return null