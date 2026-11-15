extends Node2D
class_name BulletPool

## Сцена пули, экземпляры которой переиспользуются пулом.
@export var bullet_scene: PackedScene

## Сколько пуль создать заранее.
@export var initial_size: int = 32

var _available: Array[Bullet] = []
var _active: Array[Bullet] = []


func _ready() -> void:
	if bullet_scene == null:
		push_error("BulletPool: bullet_scene не задан")
		return

	for i in initial_size:
		_available.append(_create_bullet())


## Достаёт пулю из пула и запускает её в указанной точке и направлении.
func spawn(spawn_position: Vector2, spawn_direction: Vector2) -> Bullet:
	if bullet_scene == null:
		return null

	var bullet: Bullet = _available.pop_back() if not _available.is_empty() else _create_bullet()
	bullet.reset_state()
	bullet.global_position = spawn_position
	bullet.direction = spawn_direction.normalized()
	bullet.visible = true
	bullet.set_process(true)
	bullet.set_deferred("monitoring", true)
	bullet.set_deferred("monitorable", true)
	_active.append(bullet)

	return bullet


func _create_bullet() -> Bullet:
	var bullet := bullet_scene.instantiate() as Bullet
	add_child(bullet)
	bullet.disposed.connect(_on_bullet_disposed)
	_park(bullet)
	return bullet


func _on_bullet_disposed(who: Area2D) -> void:
	var bullet := who as Bullet
	if bullet == null:
		return

	_active.erase(bullet)
	_park(bullet)
	_available.append(bullet)


func _park(bullet: Bullet) -> void:
	bullet.visible = false
	bullet.set_process(false)
	bullet.set_deferred("monitoring", false)
	bullet.set_deferred("monitorable", false)
