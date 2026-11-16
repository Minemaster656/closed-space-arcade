extends Node

signal metal_changed(total: int)
signal record_distance_changed(value: float)
signal record_metal_changed(value: int)

# Gameplay events (interceptable/modifiable by perks via listeners)
signal damage_taken(event: Dictionary)
signal shot_fired(event: Dictionary)
signal projectile_hit_meteor(event: Dictionary)
signal meteor_shatter_requested(event: Dictionary)

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "records"

var metal: int = 0
var record_distance: float = 0.0
var record_metal: int = 0


func _ready() -> void:
	load_save()


func add_metal(amount: int = 1) -> void:
	if amount == 0:
		return
	metal += amount
	metal_changed.emit(metal)
	_update_record_metal(metal)


func reset_metal() -> void:
	metal = 0
	metal_changed.emit(metal)


func submit_distance(distance: float) -> void:
	if distance <= record_distance:
		return
	record_distance = distance
	record_distance_changed.emit(record_distance)
	save()


func _update_record_metal(value: int) -> void:
	if value <= record_metal:
		return
	record_metal = value
	record_metal_changed.emit(record_metal)
	save()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, "record_distance", record_distance)
	cfg.set_value(SAVE_SECTION, "metal", metal)
	cfg.set_value(SAVE_SECTION, "record_metal", record_metal)
	cfg.save(SAVE_PATH)


func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	record_distance = float(cfg.get_value(SAVE_SECTION, "record_distance", 0.0))
	metal = int(cfg.get_value(SAVE_SECTION, "metal", 0))
	record_metal = int(cfg.get_value(SAVE_SECTION, "record_metal", 0))
