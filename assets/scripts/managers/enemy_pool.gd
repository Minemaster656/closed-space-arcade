extends Node2D
class_name EnemyPool

## Пул врагов. Как и AsteroidPool, переиспользует экземпляры сцен.
## Поддерживает несколько типов врагов: сцена берётся из EnemyType.scene,
## а пулы заводятся отдельно под каждую сцену.

## Сцена по умолчанию. Тип врага может переопределить её своим полем scene.
@export var default_scene: PackedScene

## Сколько экземпляров на каждую сцену создать заранее.
@export var prewarm_per_scene: int = 8

var _available: Dictionary = {}
var _active: Array[ShooterEnemy] = []


func _ready() -> void:
	if default_scene == null:
		push_error("EnemyPool: default_scene не задан")
		return
	_ensure_pool(default_scene)


func active_count() -> int:
	return _active.size()


## Достаёт врага из пула и ставит его в указанную точку.
func spawn(type: EnemyType, spawn_position: Vector2) -> ShooterEnemy:
	if type == null:
		return null

	var scene := type.scene if type.scene != null else default_scene
	if scene == null:
		push_error("EnemyPool: не задана сцена для типа %s" % type.id)
		return null

	var available: Array = _ensure_pool(scene)
	var enemy: ShooterEnemy
	if available.is_empty():
		enemy = _create_enemy(scene)
	else:
		enemy = available.pop_back()
	if enemy == null:
		return null

	_active.append(enemy)
	enemy.setup(type, scene, spawn_position)
	return enemy


func _ensure_pool(scene: PackedScene) -> Array:
	if not _available.has(scene):
		var created: Array = []
		for i in prewarm_per_scene:
			var enemy := _create_enemy(scene)
			if enemy != null:
				created.append(enemy)
		_available[scene] = created
	return _available[scene]


func _create_enemy(scene: PackedScene) -> ShooterEnemy:
	var enemy := scene.instantiate() as ShooterEnemy
	if enemy == null:
		push_error("EnemyPool: сцена не является ShooterEnemy: %s" % scene.resource_path)
		return null

	enemy.pool_scene = scene
	add_child(enemy)
	enemy.despawned.connect(_on_enemy_despawned)
	enemy.park()
	return enemy


func _on_enemy_despawned(who: Area2D) -> void:
	var enemy := who as ShooterEnemy
	if enemy == null:
		return

	_active.erase(enemy)
	enemy.park()
	var available: Array = _ensure_pool(enemy.pool_scene)
	available.append(enemy)