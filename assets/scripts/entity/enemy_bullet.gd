extends Area2D
class_name EnemyBullet

## Вражеская пуля. Летит вниз, урон по ракете идёт через группу collision_damage.

signal disposed(who: Area2D)

@export var speed: float = 380.0
@export_range(0.0, 1.0, 0.01) var despawn_margin: float = 0.25

var _dead: bool = false


func reset_state() -> void:
	_dead = false


func park() -> void:
	_dead = true
	visible = false
	set_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _process(delta: float) -> void:
	if _dead:
		return
	global_position.y += speed * delta
	_check_out_of_screen()


func _check_out_of_screen() -> void:
	var rect := Utils.get_visible_world_rect()
	var margin := rect.size * despawn_margin
	var bounds := rect.grow_individual(margin.x, margin.y, margin.x, margin.y)
	if not bounds.has_point(global_position):
		_dispose()


func _dispose() -> void:
	if _dead:
		return
	_dead = true
	disposed.emit(self)