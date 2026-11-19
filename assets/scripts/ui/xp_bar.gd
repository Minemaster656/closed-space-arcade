extends Control
class_name RunXpBar

## Тонкая полоска XP под счётчиком дистанции и номер уровня.

@onready var _bar: ProgressBar = $Bar
@onready var _level: Label = $Level


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level.text = tr("upgrade_level") % 1


func setup(progression: RunProgression) -> void:
	if progression == null:
		return
	progression.xp_changed.connect(_on_xp_changed)
	_on_xp_changed(progression.xp, progression.xp_to_next, progression.level)


func _on_xp_changed(xp: int, needed: int, level: int) -> void:
	_bar.max_value = float(maxi(1, needed))
	_bar.value = float(clampi(xp, 0, needed))
	_level.text = tr("upgrade_level") % level
