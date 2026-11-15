extends Label

@export var prefix: String = "МЕТАЛЛ: "
@export var punch_scale: float = 1.25
@export var flash_color: Color = Color(1.0, 0.85, 0.35, 1.0)

var _tween: Tween


func _ready() -> void:
	GameState.metal_changed.connect(_refresh)
	resized.connect(_update_pivot)
	_refresh(GameState.metal)


func _refresh(value: int) -> void:
	text = "%s%d" % [prefix, value]
	_update_pivot()

	if _tween != null and _tween.is_valid():
		_tween.kill()

	scale = Vector2.ONE * punch_scale
	modulate = flash_color
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", Color.WHITE, 0.35)


func _update_pivot() -> void:
	pivot_offset = size * 0.5
