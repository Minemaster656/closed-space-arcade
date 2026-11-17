extends Control
class_name UpgradeRow

## Одна карточка апгрейда: иконка, название/описание, уровень и кнопка цены.
## Строка не покупает апгрейд сама — она только сообщает менеджеру магазина,
## что игрок нажал на цену. Это позволяет управлять покупкой из одного места.

signal purchase_requested(id: StringName)
signal purchase_succeeded(id: StringName)
signal purchase_failed(id: StringName)

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
	_price_button.pressed.connect(_on_price_pressed)


## Задать апгрейд. Вызывается менеджером магазина после instantiate().
func setup(def: UpgradeDef) -> void:
	_def = def
	if _def == null:
		return
	_icon.texture = _def.icon
	_name_label.text = tr(_def.title_key)
	_desc_label.text = tr(_def.description_key)
	refresh()


## Полная установка отображаемых значений. Можно вызывать снаружи,
## если строке нужно показать не стандартные данные из UpgradeDef.
func set_values(
	title_text: String,
	description_text: String,
	icon_texture: Texture2D,
	level_text: String,
	price_text: String,
	is_maxed: bool,
	can_afford: bool
) -> void:
	_icon.texture = icon_texture
	_name_label.text = title_text
	_desc_label.text = description_text
	_level_label.text = level_text
	_price_button.text = price_text
	_price_button.disabled = is_maxed
	_price_button.modulate = Color.WHITE if (is_maxed or can_afford) else Color(1.0, 1.0, 1.0, 0.55)


func get_upgrade_id() -> StringName:
	if _def == null:
		return &""
	return _def.id


func refresh() -> void:
	if _def == null:
		return

	var level := GameState.get_upgrade_level(_def.id)
	var maxed := _def.is_maxed(level)
	var level_text := ""
	if _def.max_level > 0:
		level_text = tr("upgrade_level_limited") % [level, _def.max_level]
	else:
		level_text = tr("upgrade_level") % level

	var price := _def.price_for_level(level)
	var price_text := tr("upgrade_max") if maxed else str(price)
	var can_afford := GameState.metal >= price

	set_values(
		tr(_def.title_key),
		tr(_def.description_key),
		_def.icon,
		level_text,
		price_text,
		maxed,
		can_afford
	)


## Показать результат покупки. Вызывает менеджер магазина.
func notify_purchase_result(success: bool) -> void:
	if success:
		_price_button.punch(1.16)
		_flash(Color(0.45, 1.0, 0.55, 1.0))
		purchase_succeeded.emit(get_upgrade_id())
	else:
		_price_button.shake()
		_flash(Color(1.0, 0.3, 0.3, 1.0))
		purchase_failed.emit(get_upgrade_id())


func _on_price_pressed() -> void:
	if _def != null:
		purchase_requested.emit(_def.id)


func _flash(color: Color) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.32)


func _update_pivot() -> void:
	pivot_offset = size * 0.5
