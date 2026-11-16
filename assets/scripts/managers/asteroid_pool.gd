extends Node2D
class_name AsteroidPool

## Сцена по умолчанию. Тип астероида может переопределить её своим полем scene.
@export var default_scene: PackedScene

## Сколько экземпляров на каждую сцену создать заранее.
@export var prewarm_per_scene: int = 16

## Множитель скорости всех активных астероидов (растёт, когда ракета поднимается).
var speed_multiplier: float = 1.0

var _available: Dictionary = {}
var _active: Array[Asteroid] = []

var active_count: int:
	get:
		return _active.size()


func _ready() -> void:
	if default_scene == null:
		push_error("AsteroidPool: default_scene не задан")
		return
	_ensure_pool(default_scene)


func spawn(
	type: AsteroidType,
	spawn_position: Vector2,
	direction: Vector2,
	speed: float
) -> Asteroid:
	if type == null:
		return null

	var scene := type.scene if type.scene != null else default_scene
	if scene == null:
		push_error("AsteroidPool: не задана сцена для типа %s" % type.id)
		return null

	var available: Array = _ensure_pool(scene)
	var asteroid: Asteroid
	if available.is_empty():
		asteroid = _create_asteroid(scene)
	else:
		asteroid = available.pop_back()
	if asteroid == null:
		return null

	_active.append(asteroid)
	asteroid.setup(type, self, scene, spawn_position, direction, speed)
	return asteroid


func _ensure_pool(scene: PackedScene) -> Array:
	if not _available.has(scene):
		var created: Array = []
		for i in prewarm_per_scene:
			var asteroid := _create_asteroid(scene)
			if asteroid != null:
				created.append(asteroid)
		_available[scene] = created
	return _available[scene]


func _create_asteroid(scene: PackedScene) -> Asteroid:
	var asteroid := scene.instantiate() as Asteroid
	if asteroid == null:
		push_error("AsteroidPool: сцена не является Asteroid: %s" % scene.resource_path)
		return null

	asteroid.pool_scene = scene
	add_child(asteroid)
	asteroid.despawned.connect(_on_asteroid_despawned)
	asteroid.park()
	return asteroid


func _on_asteroid_despawned(who: Area2D) -> void:
	var asteroid := who as Asteroid
	if asteroid == null:
		return

	_active.erase(asteroid)
	asteroid.park()
	var available: Array = _ensure_pool(asteroid.pool_scene)
	available.append(asteroid)
