extends Control
class_name UpgradeRow

## Одна карточка апгрейда: иконка, название/описание, уровень и кнопка цены.

signal purchase_succeeded(id: StringName)

@onready var _icon: TextureRect = $Margin/HBox/Icon
@onready var _name_label: Label = $Margin/HBox/Info/Name
@onready var _desc_label: Label = $Margin/HBox/Info/Desc
@onready var _level_label: Label = $Margin/HBox/Info/Level
@onready var _price_button: JuicyButton = $Margin/HBox/PriceButton

var _def: UpgradeDef
var _flash_tween: Tween


func _ready() -> void:
	resized.connect(_update_pivot)
	_update_pivot()


func setup(def: UpgradeDef) -> void:
	_def = def
	if _def == null:
		return
	_icon.texture = _def.icon
	_name_label.text = tr(_def.title_key)
	_desc_label.text = tr(_def.description_key)
	_price_button.pressed.connect(_on_price_pressed)
	refresh()


func refresh() -> void:
	if _def == null:
		return

	var level := GameState.get_upgrade_level(_def.id)
	var maxed := _def.is_maxed(level)
	if _def.max_level > 0:
		_level_label.text = tr("upgrade_level_limited") % [level, _def.max_level]
	else:
		_level_label.text = tr("upgrade_level") % level

	if maxed:
		_price_button.text = tr("upgrade_max")
		_price_button.disabled = true
		_price_button.modulate = Color.WHITE
		return

	var price := _def.price_for_level(level)
	_price_button.text = str(price)
	_price_button.disabled = false
	_price_button.modulate = Color(1.0, 1.0, 1.0, 0.55) if GameState.metal < price else Color.WHITE


func _on_price_pressed() -> void:
	if _def == null:
		return

	if GameState.buy_upgrade(_def.id):
		_price_button.punch(1.16)
		_flash(Color(0.45, 1.0, 0.55, 1.0))
		purchase_succeeded.emit(_def.id)
	else:
		_price_button.shake()
		_flash(Color(1.0, 0.3, 0.3, 1.0))


func _flash(color: Color) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.32)


func _update_pivot() -> void:
	pivot_offset = size * 0.5
