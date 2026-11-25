extends Control
class_name BuffHud

## Колонка активных баффов в правом верхнем углу.

@export var icon_scene: PackedScene
@onready var _list: VBoxContainer = $List

var _icons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(buffs: BuffSystem) -> void:
	if buffs == null or icon_scene == null:
		return
	if not buffs.buff_started.is_connected(_on_buff_started):
		buffs.buff_started.connect(_on_buff_started)
		buffs.buff_refreshed.connect(_on_buff_refreshed)
		buffs.buff_ended.connect(_on_buff_ended)
	for instance in buffs.get_active():
		_add_icon(instance)


func _on_buff_started(instance: BuffInstance) -> void:
	_add_icon(instance)


func _on_buff_refreshed(instance: BuffInstance) -> void:
	var icon: BuffIconView = _icons.get(instance)
	if icon != null and is_instance_valid(icon):
		icon.pulse()


func _on_buff_ended(instance: BuffInstance) -> void:
	var icon: BuffIconView = _icons.get(instance)
	_icons.erase(instance)
	if icon != null and is_instance_valid(icon):
		icon.play_outro()


func _add_icon(instance: BuffInstance) -> void:
	if _icons.has(instance):
		return
	var icon := icon_scene.instantiate() as BuffIconView
	if icon == null:
		return
	_icons[instance] = icon
	_list.add_child(icon)
	icon.setup(instance)
