extends CanvasLayer

## Пауза: затемняющий шейдер, заголовок и кнопка продолжения.
## Слой живёт внутри игрового SubViewport и обрабатывается всегда,
## потому что открывается уже после get_tree().paused = true.

const FX_IN: float = 0.28
const FX_OUT: float = 0.18
const CONTENT_IN: float = 0.32

@onready var _root: Control = $Root
@onready var _fx: ColorRect = $Root/Fx
@onready var _title: Label = $Root/Center/Panel/VBox/Title
@onready var _resume_button: Button = $Root/Center/Panel/VBox/ResumeButton

var _fx_tween: Tween
var _intensity: float = 0.0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fx_tween = null
	_root.visible = false
	_set_intensity(0.0)
	_title.text = tr("ui_paused")
	_resume_button.text = tr("ui_resume")
	_resume_button.pressed.connect(_on_resume_pressed)
	_resume_button.resized.connect(_update_pivots)
	_title.resized.connect(_update_pivots)
	_update_pivots()
	PauseManager.paused_changed.connect(_on_paused_changed)


func _on_paused_changed(paused: bool) -> void:
	if paused:
		_show()
	else:
		_hide()


func _on_resume_pressed() -> void:
	PauseManager.resume()


func _show() -> void:
	_kill_tween()
	_root.visible = true
	_set_intensity(0.0)
	_title.text = tr("ui_paused")
	_resume_button.text = tr("ui_resume")
	_update_pivots()

	_title.scale = Vector2(0.82, 0.82)
	_title.modulate.a = 0.0
	_resume_button.scale = Vector2(0.92, 0.92)
	_resume_button.modulate.a = 0.0

	_fx_tween = PauseManager.modal_tween()
	_fx_tween.set_parallel(true)
	_fx_tween.tween_method(_set_intensity, 0.0, 1.0, FX_IN)
	_fx_tween.tween_property(_title, "modulate:a", 1.0, CONTENT_IN).set_delay(0.04)
	_fx_tween.tween_property(_title, "scale", Vector2.ONE, 0.42) \
		.set_delay(0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_property(_resume_button, "modulate:a", 1.0, CONTENT_IN).set_delay(0.1)
	_fx_tween.tween_property(_resume_button, "scale", Vector2.ONE, 0.36) \
		.set_delay(0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide() -> void:
	_kill_tween()
	if not _root.visible:
		return
	_fx_tween = PauseManager.modal_tween()
	_fx_tween.set_parallel(true)
	_fx_tween.tween_method(_set_intensity, _intensity, 0.0, FX_OUT)
	_fx_tween.tween_property(_title, "modulate:a", 0.0, FX_OUT)
	_fx_tween.tween_property(_resume_button, "modulate:a", 0.0, FX_OUT)
	_fx_tween.tween_callback(_finish_hide).set_delay(FX_OUT)


func _finish_hide() -> void:
	_set_intensity(0.0)
	_root.visible = false


func _set_intensity(value: float) -> void:
	_intensity = value
	var mat := _fx.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("intensity", value)


func _update_pivots() -> void:
	_title.pivot_offset = _title.size * 0.5
	_resume_button.pivot_offset = _resume_button.size * 0.5


func _kill_tween() -> void:
	if _fx_tween != null and _fx_tween.is_valid():
		_fx_tween.kill()
	_fx_tween = null


func _exit_tree() -> void:
	_kill_tween()
