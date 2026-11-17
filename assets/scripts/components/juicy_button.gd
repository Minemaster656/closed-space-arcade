extends Button
class_name JuicyButton

## Кнопка с мягким hover/press-скейлом и punch/shake для игрового фидбека.

@export var hover_scale: float = 1.035
@export var press_scale: float = 0.94
@export var hover_time: float = 0.12
@export var press_time: float = 0.08
@export var release_time: float = 0.22

var _tween: Tween
var _hovered: bool = false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	resized.connect(_update_pivot)
	_update_pivot()


func punch(target_scale: float = 1.16, duration: float = 0.28) -> void:
	_kill_tween()
	rotation = 0.0
	scale = Vector2.ONE * target_scale
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, duration) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func shake(strength_deg: float = 2.2, duration: float = 0.05) -> void:
	_kill_tween()
	scale = Vector2.ONE
	_update_pivot()
	var strength := deg_to_rad(strength_deg)
	rotation = -strength
	_tween = create_tween()
	_tween.tween_property(self, "rotation", strength, duration)
	_tween.tween_property(self, "rotation", -strength * 0.7, duration * 2.0)
	_tween.tween_property(self, "rotation", 0.0, duration)


func _on_mouse_entered() -> void:
	_hovered = true
	if disabled:
		return
	_animate_scale(hover_scale, hover_time, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	_hovered = false
	_animate_scale(1.0, hover_time, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_down() -> void:
	_animate_scale(press_scale, press_time, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _on_button_up() -> void:
	var target := hover_scale if _hovered and not disabled else 1.0
	_animate_scale(target, release_time, Tween.TRANS_BACK, Tween.EASE_OUT)


func _animate_scale(target: float, duration: float, trans: Tween.TransitionType, ease_type: Tween.EaseType) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * target, duration) \
		.set_trans(trans).set_ease(ease_type)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
