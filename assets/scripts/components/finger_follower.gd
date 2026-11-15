extends Node2D
class_name FollowFinger2D

@export var target: Node2D                  ## Что двигаем (если null — двигаем родителя)
@export var follow_speed: float = 12.0      ## Больше — резче
@export var finger_offset: Vector2 = Vector2.ZERO

@export_group("Rect")
@export var area: Rect2 = Rect2(-200, -200, 400, 400)
@export var drag_anywhere: bool = true
@export var grab_radius: float = 60.0

var _dragging := false
var _touch_index := -1
var _touch_mode := false
var _target_global: Vector2

func _ready() -> void:
	if target == null:
		target = get_parent() as Node2D
		if target == null:
			push_error("FollowFinger2D: target не задан и родитель не Node2D")
			return
	_target_global = target.global_position
	_apply_position(_target_global)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_touch_mode = true
	elif _touch_mode and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return

	if event is InputEventScreenTouch:
		_on_press(event.pressed, _screen_to_world(event.position), event.index)
	elif event is InputEventScreenDrag:
		if _dragging and event.index == _touch_index:
			_set_target(_screen_to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_press(event.pressed, _screen_to_world(event.position), -1)
	elif event is InputEventMouseMotion:
		if _dragging and _touch_index == -1:
			_set_target(_screen_to_world(event.position))

func _on_press(pressed: bool, world_pos: Vector2, index: int) -> void:
	if pressed:
		if _dragging or target == null:
			return
		if not drag_anywhere and world_pos.distance_to(target.global_position) > grab_radius:
			return
		_dragging = true
		_touch_index = index
		_set_target(world_pos)
	else:
		if index == _touch_index:
			_dragging = false
			_touch_index = -1

func _set_target(world_pos: Vector2) -> void:
	var desired := world_pos + finger_offset
	_target_global = Vector2(
		clamp(desired.x, area.position.x, area.end.x),
		clamp(desired.y, area.position.y, area.end.y)
	)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_pos

func _apply_position(global_pos: Vector2) -> void:
	# Учитываем случай, когда target — потомок трансформированного родителя.
	if target.get_parent() is Node2D:
		target.global_position = global_pos
	else:
		target.global_position = global_pos

func _process(delta: float) -> void:
	if not _dragging or target == null:
		return
	var t := 1.0 - exp(-follow_speed * delta)
	_apply_position(target.global_position.lerp(_target_global, t))
