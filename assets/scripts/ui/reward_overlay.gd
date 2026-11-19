extends CanvasLayer
class_name RewardOverlay

## Модальный выбор карточек после кометы. Живёт всегда, потому что
## открывается уже после get_tree().paused = true.

signal card_selected(card: CardDef)
signal closed

const FX_IN: float = 0.3
const FX_OUT: float = 0.18
const CONTENT_IN: float = 0.32
const CARD_STAGGER: float = 0.06

@onready var _root: Control = $Root
@onready var _fx: ColorRect = $Root/Fx
@onready var _center: CenterContainer = $Root/Center
@onready var _panel: PanelContainer = $Root/Center/Panel
@onready var _title: Label = $Root/Center/Panel/Margin/VBox/Title
@onready var _cards: HFlowContainer = $Root/Center/Panel/Margin/VBox/Cards

var _tween: Tween
var _closing: bool = false
var _intensity: float = 0.0


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_set_intensity(0.0)
	_title.text = tr("ui_reward_title")
	_panel.resized.connect(_update_pivot)
	_update_pivot()


func show_offers(offers: Array[CardDef]) -> void:
	_kill_tween()
	_closing = false
	_clear_cards()
	_root.visible = true
	_title.text = tr("ui_reward_title")
	_set_intensity(0.0)

	var index := 0
	for card in offers:
		if card == null:
			continue
		var view := preload("res://assets/prefabs/card_view.tscn").instantiate() as CardView
		_cards.add_child(view)
		view.setup(card)
		view.card_chosen.connect(_on_card_chosen)
		_prepare_card_animation(view, index)
		index += 1

	_update_pivot()
	_panel.modulate.a = 1.0
	_panel.scale = Vector2(0.92, 0.92)

	_tween = PauseManager.modal_tween()
	_tween.set_parallel(true)
	_tween.tween_method(_set_intensity, 0.0, 1.0, FX_IN)
	_tween.tween_property(_panel, "scale", Vector2.ONE, CONTENT_IN) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not _root.visible or _closing:
		return
	_closing = true
	_animate_close()


func abort() -> void:
	_kill_tween()
	_closing = false
	_root.visible = false
	_set_intensity(0.0)


func _prepare_card_animation(view: CardView, index: int) -> void:
	view.modulate.a = 0.0
	view.scale = Vector2(0.86, 0.86)
	var tween := PauseManager.modal_tween()
	tween.set_parallel(true)
	tween.tween_property(view, "modulate:a", 1.0, 0.24).set_delay(index * CARD_STAGGER)
	tween.tween_property(view, "scale", Vector2.ONE, 0.38) \
		.set_delay(index * CARD_STAGGER) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_card_chosen(card: CardDef) -> void:
	if _closing:
		return
	_closing = true
	_disable_cards()
	card_selected.emit(card)
	_animate_close()


func _animate_close() -> void:
	_kill_tween()
	_tween = PauseManager.modal_tween()
	_tween.set_parallel(true)
	_tween.tween_method(_set_intensity, _intensity, 0.0, FX_OUT)
	_tween.tween_property(_panel, "modulate:a", 0.0, FX_OUT)
	_tween.tween_property(_panel, "scale", Vector2(0.94, 0.94), FX_OUT)
	_tween.tween_callback(_finish_close).set_delay(FX_OUT)


func _finish_close() -> void:
	_root.visible = false
	_set_intensity(0.0)
	_closing = false
	closed.emit()


func _clear_cards() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()


func _disable_cards() -> void:
	for child in _cards.get_children():
		var view := child as CardView
		if view != null:
			view.disabled = true


func _set_intensity(value: float) -> void:
	_intensity = value
	var mat := _fx.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("intensity", value)


func _update_pivot() -> void:
	_panel.pivot_offset = _panel.size * 0.5


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _exit_tree() -> void:
	_kill_tween()
