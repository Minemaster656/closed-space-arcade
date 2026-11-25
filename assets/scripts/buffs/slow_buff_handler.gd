extends BuffHandler

## Визуальная часть замедления: лёгкий ледяной оттенок ракеты.
## Само замедление задаётся StatModifier'ом в BuffDef.

const TINT_COLOR := Color(0.72, 0.9, 1.0, 1.0)
const TINT_DURATION := 0.2

var _tween: Tween


func _on_start() -> void:
	_tint_to(TINT_COLOR)


func _on_refresh() -> void:
	_tint_to(TINT_COLOR, 0.12)


func _on_end() -> void:
	_tint_to(Color.WHITE, 0.25)


func _tint_to(color: Color, duration: float = TINT_DURATION) -> void:
	var rocket := get_rocket()
	if rocket == null:
		return
	var sprite := rocket.get_node_or_null("Sprite") as CanvasItem
	if sprite == null or not is_instance_valid(sprite):
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
	# Твин привязываем к RunContext, а не к обработчику: обработчик
	# удаляется сразу после _on_end, и его собственный твин был бы убит.
	_tween = context.create_tween() if context != null else create_tween()
	_tween.tween_property(sprite, "modulate", color, duration)
