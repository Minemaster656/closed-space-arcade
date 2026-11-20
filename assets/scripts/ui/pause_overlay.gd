extends CanvasLayer
class_name PauseOverlay

## Пауза: затемняющий шейдер, заголовок, продолжение и выход в магазин.
## Слой живёт внутри игрового SubViewport и обрабатывается всегда,
## потому что открывается уже после get_tree().paused = true.

signal shop_requested

const FX_IN: float = 0.28
const FX_OUT: float = 0.18
const CONTENT_IN: float = 0.32

@onready var _root: Control = $Root
@onready var _fx: ColorRect = $Root/Fx
@onready var _title: Label = $Root/Center/Panel/VBox/Title
@onready var _resume_button: Button = $Root/Center/Panel/VBox/ResumeButton
@onready var _audio_row: HBoxContainer = $Root/Center/Panel/VBox/AudioRow
@onready var _music_button: Button = $Root/Center/Panel/VBox/AudioRow/MusicButton
@onready var _sfx_button: Button = $Root/Center/Panel/VBox/AudioRow/SfxButton
@onready var _shop_button: Button = $Root/Center/Panel/VBox/ShopButton
@onready var _confirm_center: CenterContainer = $Root/ConfirmCenter
@onready var _confirm_title: Label = $Root/ConfirmCenter/ConfirmPanel/VBox/Title
@onready var _confirm_text: Label = $Root/ConfirmCenter/ConfirmPanel/VBox/Text
@onready var _cancel_button: Button = $Root/ConfirmCenter/ConfirmPanel/VBox/Buttons/CancelButton
@onready var _confirm_button: Button = $Root/ConfirmCenter/ConfirmPanel/VBox/Buttons/ConfirmButton

var _fx_tween: Tween
var _confirm_tween: Tween
var _intensity: float = 0.0


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fx_tween = null
	_root.visible = false
	_set_intensity(0.0)
	_title.text = tr("ui_paused")
	_resume_button.text = tr("ui_resume")
	_shop_button.text = tr("ui_exit_shop")
	_refresh_audio_labels()
	_confirm_title.text = tr("ui_exit_shop_title")
	_confirm_text.text = tr("ui_exit_shop_text")
	_cancel_button.text = tr("ui_cancel")
	_confirm_button.text = tr("ui_confirm")
	_resume_button.pressed.connect(_on_resume_pressed)
	_music_button.pressed.connect(_on_music_pressed)
	_sfx_button.pressed.connect(_on_sfx_pressed)
	_shop_button.pressed.connect(_on_shop_pressed)
	_cancel_button.pressed.connect(_hide_confirm)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_resume_button.resized.connect(_update_pivots)
	_music_button.resized.connect(_update_pivots)
	_sfx_button.resized.connect(_update_pivots)
	_shop_button.resized.connect(_update_pivots)
	_cancel_button.resized.connect(_update_pivots)
	_confirm_button.resized.connect(_update_pivots)
	_title.resized.connect(_update_pivots)
	_update_pivots()
	PauseManager.paused_changed.connect(_on_paused_changed)
	AudioSettings.changed.connect(_refresh_audio_labels)


func _on_paused_changed(paused: bool) -> void:
	if paused:
		_show()
	else:
		_hide()


func _on_resume_pressed() -> void:
	PauseManager.resume()


func _on_music_pressed() -> void:
	AudioSettings.toggle_music()


func _on_sfx_pressed() -> void:
	AudioSettings.toggle_sfx()


func _refresh_audio_labels() -> void:
	_music_button.text = tr("ui_music_off" if AudioSettings.is_music_muted() else "ui_music_on")
	_sfx_button.text = tr("ui_sfx_off" if AudioSettings.is_sfx_muted() else "ui_sfx_on")


func _show() -> void:
	_kill_tween()
	_hide_confirm(false)
	_root.visible = true
	_set_intensity(0.0)
	_title.text = tr("ui_paused")
	_resume_button.text = tr("ui_resume")
	_shop_button.text = tr("ui_exit_shop")
	_refresh_audio_labels()
	_update_pivots()

	_title.scale = Vector2(0.82, 0.82)
	_title.modulate.a = 0.0
	_resume_button.scale = Vector2(0.92, 0.92)
	_resume_button.modulate.a = 0.0
	_audio_row.scale = Vector2(0.92, 0.92)
	_audio_row.modulate.a = 0.0
	_shop_button.scale = Vector2(0.92, 0.92)
	_shop_button.modulate.a = 0.0

	_fx_tween = PauseManager.modal_tween()
	_fx_tween.set_parallel(true)
	_fx_tween.tween_method(_set_intensity, 0.0, 1.0, FX_IN)
	_fx_tween.tween_property(_title, "modulate:a", 1.0, CONTENT_IN).set_delay(0.04)
	_fx_tween.tween_property(_title, "scale", Vector2.ONE, 0.42) \
		.set_delay(0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_property(_resume_button, "modulate:a", 1.0, CONTENT_IN).set_delay(0.1)
	_fx_tween.tween_property(_resume_button, "scale", Vector2.ONE, 0.36) \
		.set_delay(0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_property(_audio_row, "modulate:a", 1.0, CONTENT_IN).set_delay(0.16)
	_fx_tween.tween_property(_audio_row, "scale", Vector2.ONE, 0.36) \
		.set_delay(0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx_tween.tween_property(_shop_button, "modulate:a", 1.0, CONTENT_IN).set_delay(0.22)
	_fx_tween.tween_property(_shop_button, "scale", Vector2.ONE, 0.36) \
		.set_delay(0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _hide() -> void:
	_kill_tween()
	_hide_confirm(false)
	if not _root.visible:
		return
	_fx_tween = PauseManager.modal_tween()
	_fx_tween.set_parallel(true)
	_fx_tween.tween_method(_set_intensity, _intensity, 0.0, FX_OUT)
	_fx_tween.tween_property(_title, "modulate:a", 0.0, FX_OUT)
	_fx_tween.tween_property(_resume_button, "modulate:a", 0.0, FX_OUT)
	_fx_tween.tween_property(_audio_row, "modulate:a", 0.0, FX_OUT)
	_fx_tween.tween_property(_shop_button, "modulate:a", 0.0, FX_OUT)
	_fx_tween.tween_callback(_finish_hide).set_delay(FX_OUT)


func _finish_hide() -> void:
	_set_intensity(0.0)
	_confirm_center.visible = false
	_root.visible = false


func _on_shop_pressed() -> void:
	if not _root.visible:
		return
	_confirm_center.visible = true
	_confirm_center.modulate.a = 0.0
	var panel := _confirm_center.get_node("ConfirmPanel") as Control
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.9, 0.9)

	_confirm_tween = PauseManager.modal_tween()
	_confirm_tween.set_parallel(true)
	_confirm_tween.tween_property(_confirm_center, "modulate:a", 1.0, 0.18)
	_confirm_tween.tween_property(panel, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_confirm_pressed() -> void:
	shop_requested.emit()


func _hide_confirm(animate: bool = true) -> void:
	if _confirm_tween != null and _confirm_tween.is_valid():
		_confirm_tween.kill()
	_confirm_tween = null
	if not _confirm_center.visible:
		return
	if not animate:
		_confirm_center.visible = false
		return

	_confirm_tween = PauseManager.modal_tween()
	_confirm_tween.tween_property(_confirm_center, "modulate:a", 0.0, 0.15)
	_confirm_tween.tween_callback(func() -> void: _confirm_center.visible = false)


func _set_intensity(value: float) -> void:
	_intensity = value
	var mat := _fx.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("intensity", value)


func _update_pivots() -> void:
	_title.pivot_offset = _title.size * 0.5
	_resume_button.pivot_offset = _resume_button.size * 0.5
	_audio_row.pivot_offset = _audio_row.size * 0.5
	_music_button.pivot_offset = _music_button.size * 0.5
	_sfx_button.pivot_offset = _sfx_button.size * 0.5
	_shop_button.pivot_offset = _shop_button.size * 0.5
	_cancel_button.pivot_offset = _cancel_button.size * 0.5
	_confirm_button.pivot_offset = _confirm_button.size * 0.5


func _kill_tween() -> void:
	if _fx_tween != null and _fx_tween.is_valid():
		_fx_tween.kill()
	_fx_tween = null


func _exit_tree() -> void:
	_kill_tween()
	if _confirm_tween != null and _confirm_tween.is_valid():
		_confirm_tween.kill()
