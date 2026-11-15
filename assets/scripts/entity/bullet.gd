extends Area2D
class_name Bullet

## Скорость полёта в пикселях в секунду.
@export var speed: float = 900.0

## Направление полёта (единичный вектор).
@export var direction: Vector2 = Vector2.UP

## Урон, который пуля передаст цели.
@export var damage: float = 1.0

## На сколько долей экрана пуля может вылететь за границы, прежде чем вернётся в пул.
@export_range(0.0, 1.0, 0.01) var despawn_margin: float = 0.25

signal disposed(who: Area2D)

var _disposed: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	_check_out_of_screen()


func reset_state() -> void:
	_disposed = false


func _on_area_entered(area: Area2D) -> void:
	if _disposed:
		return
	if not area.is_in_group("damageable"):
		return
	if area.has_method("is_damageable") and not area.is_damageable():
		return
	if not area.has_method("take_damage"):
		return

	area.take_damage(damage)
	_dispose()


func _check_out_of_screen() -> void:
	if _disposed:
		return

	var rect := Utils.get_visible_world_rect()
	var margin := rect.size * despawn_margin
	var bounds := rect.grow_individual(margin.x, margin.y, margin.x, margin.y)

	if not bounds.has_point(global_position):
		_dispose()


func _dispose() -> void:
	if _disposed:
		return
	_disposed = true
	disposed.emit(self)
