extends Node2D
class_name ShooterEnemyPool

## Пул вражеских стрелков. Как и AsteroidPool, переиспользует экземпляры сцены.

## Сцена врага, экземпляры которой переиспользуются пулом.
@export var scene: PackedScene

## Сколько врагов создать заранее.
@export var initial_size: int = 8

var _available: Array[ShooterEnemy] = []
var _active: Array[ShooterEnemy] = []


func _ready() -> void:
	if scene == null:
		push_error("ShooterEnemyPool: scene не задана")
		return
	for i in initial_size:
		_available.append(_create_enemy())


func active_count() -> int:
	return _active.size()


## Достаёт врага из пула и ставит его в указанную точку.
func spawn(spawn_position: Vector2) -> ShooterEnemy:
	if scene == null:
		return null

	var enemy: ShooterEnemy = _available.pop_back() if not _available.is_empty() else _create_enemy()
	if enemy == null:
		return null

	_active.append(enemy)
	enemy.spawn_reset(spawn_position)
	return enemy


func _create_enemy() -> ShooterEnemy:
	var enemy := scene.instantiate() as ShooterEnemy
	if enemy == null:
		push_error("ShooterEnemyPool: сцена не является ShooterEnemy: %s" % scene.resource_path)
		return null

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
	_available.append(enemy)
