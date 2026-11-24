extends Control
class_name UpgradeRow

## Одна карточка апгрейда: иконка, название/описание, уровень и кнопки +/−.
## Строка не меняет состояние сама — она только сообщает менеджеру магазина,
## какое действие игрок хочет выполнить.

signal allocate_requested(id: StringName)
signal deallocate_requested(id: StringName)

@onready var _icon: TextureRect = $Margin/HBox/Icon
@onready var _name_label: Label = $Margin/HBox/Info/Name
@onready var _desc_label: Label = $Margin/HBox/Info/Desc
@onready var _level_label: Label = $Margin/HBox/Info/Level
@onready var _minus_button: JuicyButton = $Margin/HBox/Actions/MinusButton
@onready var _plus_button: JuicyButton = $Margin/HBox/Actions/PlusButton

var _def: UpgradeDef
var _flash_tween: Tween
var _level_tween: Tween


func _ready() -> void:
	resized.connect(_update_pivot)
	_level_label.resized.connect(_update_level_pivot)
	_update_pivot()
	_update_level_pivot()
	_minus_button.pressed.connect(_on_minus_pressed)
	_plus_button.pressed.connect(_on_plus_pressed)
	_minus_button.tooltip_text = tr("upgrade_minus_tip")
	_plus_button.tooltip_text = tr("upgrade_plus_tip")


## Задать апгрейд. Вызывается менеджером магазина после instantiate().
func setup(def: UpgradeDef) -> void:
	_def = def
	if _def == null:
		return
	_icon.texture = _def.icon
	_name_label.text = tr(_def.title_key)
	_desc_label.text = tr(_def.description_key)
	refresh()


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
	_level_label.text = level_text

	_minus_button.disabled = level <= 0
	_plus_button.disabled = maxed or GameState.upgrade_points <= 0
	_plus_button.tooltip_text = tr("upgrade_max") if maxed else tr("upgrade_plus_tip")

	# Приглушаем недоступную кнопку, чтобы состояние читалось без наведения.
	_minus_button.modulate.a = 1.0 if not _minus_button.disabled else 0.55
	_plus_button.modulate.a = 1.0 if not _plus_button.disabled else 0.55


## Визуальный отклик на попытку вложить/снять очко.
func notify_allocation_result(success: bool, added: bool) -> void:
	if success:
		if added:
			_plus_button.punch(1.12)
			_flash(Color(0.5, 1.0, 0.62, 1.0))
		else:
			_minus_button.punch(1.12)
			_flash(Color(1.0, 0.78, 0.5, 1.0))
	else:
		if added:
			_plus_button.shake()
		else:
			_minus_button.shake()
		_flash(Color(1.0, 0.35, 0.35, 1.0))


## Пунч уровня в момент, когда к строке «прилетело» очко.
func bump_level() -> void:
	if _level_tween != null and _level_tween.is_valid():
		_level_tween.kill()
	_level_label.pivot_offset = _level_label.size * 0.5
	_level_label.scale = Vector2.ONE * 1.28
	_level_label.modulate = Color(1.0, 0.95, 0.55, 1.0)
	_level_tween = create_tween().set_parallel(true)
	_level_tween.tween_property(_level_label, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_level_tween.tween_property(_level_label, "modulate", Color.WHITE, 0.35)


## Куда летит очко: центр кнопки + или − в глобальных координатах.
func get_action_anchor(added: bool) -> Vector2:
	var button := _plus_button if added else _minus_button
	return button.get_global_rect().get_center()


func _on_minus_pressed() -> void:
	if _def != null:
		deallocate_requested.emit(_def.id)


func _on_plus_pressed() -> void:
	if _def != null:
		allocate_requested.emit(_def.id)


func _flash(color: Color) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.32)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _update_level_pivot() -> void:
	_level_label.pivot_offset = _level_label.size * 0.5
