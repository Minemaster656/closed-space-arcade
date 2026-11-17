extends Node

signal metal_changed(total: int)
signal record_distance_changed(value: float)
signal record_metal_changed(value: int)
signal upgrades_changed

# Gameplay events (interceptable/modifiable by perks via listeners)
signal damage_taken(event: Dictionary)
signal shot_fired(event: Dictionary)
signal projectile_hit_meteor(event: Dictionary)
signal meteor_shatter_requested(event: Dictionary)

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "records"
const UPGRADES_SECTION := "upgrades"

const UPGRADE_DAMAGE: StringName = &"damage"
const UPGRADE_FIRE_RATE: StringName = &"fire_rate"
const UPGRADE_PROJECTILE_SPEED: StringName = &"projectile_speed"
const UPGRADE_PIERCING: StringName = &"piercing"
const UPGRADE_MORE_METAL: StringName = &"more_metal"

const UPGRADE_ORDER: Array[StringName] = [
	UPGRADE_DAMAGE,
	UPGRADE_FIRE_RATE,
	UPGRADE_PROJECTILE_SPEED,
	UPGRADE_PIERCING,
	UPGRADE_MORE_METAL,
]

const UPGRADE_DEFS: Dictionary = {
	UPGRADE_DAMAGE: preload("res://assets/resources/upgrades/damage.tres"),
	UPGRADE_FIRE_RATE: preload("res://assets/resources/upgrades/fire_rate.tres"),
	UPGRADE_PROJECTILE_SPEED: preload("res://assets/resources/upgrades/projectile_speed.tres"),
	UPGRADE_PIERCING: preload("res://assets/resources/upgrades/piercing.tres"),
	UPGRADE_MORE_METAL: preload("res://assets/resources/upgrades/more_metal.tres"),
}

var metal: int = 0
var record_distance: float = 0.0
var record_metal: int = 0
var upgrade_levels: Dictionary = {}

## Накопленная дробная часть бонуса металла, чтобы +10% не терялись на мелких дропах.
var _metal_fraction: float = 0.0


func _ready() -> void:
	load_save()


func add_metal(amount: int = 1) -> void:
	if amount <= 0:
		return

	_metal_fraction += float(amount) * get_metal_multiplier()
	var whole := int(floor(_metal_fraction))
	if whole <= 0:
		return
	_metal_fraction -= float(whole)
	metal += whole
	metal_changed.emit(metal)
	_update_record_metal(metal)


func reset_metal() -> void:
	metal = 0
	_metal_fraction = 0.0
	metal_changed.emit(metal)


## Полностью удаляет сохранение и сбрасывает прогресс в памяти.
## Нужно для отладки «с нуля».
func reset_save() -> void:
	metal = 0
	record_distance = 0.0
	record_metal = 0
	_metal_fraction = 0.0
	upgrade_levels.clear()

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	metal_changed.emit(metal)
	record_distance_changed.emit(record_distance)
	record_metal_changed.emit(record_metal)
	upgrades_changed.emit()


func submit_distance(distance: float) -> void:
	if distance <= record_distance:
		return
	record_distance = distance
	record_distance_changed.emit(record_distance)
	save()


func get_upgrade_def(id: StringName) -> UpgradeDef:
	return UPGRADE_DEFS.get(id) as UpgradeDef


func get_upgrade_level(id: StringName) -> int:
	return int(upgrade_levels.get(id, 0))


func get_upgrade_price(id: StringName) -> int:
	var def := get_upgrade_def(id)
	if def == null:
		return 0
	return def.price_for_level(get_upgrade_level(id))


func is_upgrade_maxed(id: StringName) -> bool:
	var def := get_upgrade_def(id)
	if def == null:
		return true
	return def.is_maxed(get_upgrade_level(id))


func can_buy_upgrade(id: StringName) -> bool:
	if is_upgrade_maxed(id):
		return false
	return metal >= get_upgrade_price(id)


func buy_upgrade(id: StringName) -> bool:
	if not can_buy_upgrade(id):
		return false
	var level := get_upgrade_level(id)
	metal -= get_upgrade_price(id)
	upgrade_levels[id] = level + 1
	metal_changed.emit(metal)
	upgrades_changed.emit()
	save()
	return true


func get_damage_bonus() -> float:
	return float(get_upgrade_level(UPGRADE_DAMAGE))


func get_shoot_rate_multiplier() -> float:
	return pow(2.0, float(get_upgrade_level(UPGRADE_FIRE_RATE)))


func get_bullet_speed_multiplier() -> float:
	return 1.0 + 0.5 * float(get_upgrade_level(UPGRADE_PROJECTILE_SPEED))


func get_bullet_pierce() -> int:
	return get_upgrade_level(UPGRADE_PIERCING)


func get_metal_multiplier() -> float:
	return 1.0 + 0.1 * float(get_upgrade_level(UPGRADE_MORE_METAL))


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
	cfg.set_value(SAVE_SECTION, "metal_fraction", _metal_fraction)
	for id in UPGRADE_ORDER:
		var level := get_upgrade_level(id)
		if level > 0:
			cfg.set_value(UPGRADES_SECTION, String(id), level)
	cfg.save(SAVE_PATH)


func load_save() -> void:
	upgrade_levels.clear()
	_metal_fraction = 0.0

	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	record_distance = float(cfg.get_value(SAVE_SECTION, "record_distance", 0.0))
	metal = int(cfg.get_value(SAVE_SECTION, "metal", 0))
	record_metal = int(cfg.get_value(SAVE_SECTION, "record_metal", 0))
	_metal_fraction = float(cfg.get_value(SAVE_SECTION, "metal_fraction", 0.0))
	for id in UPGRADE_ORDER:
		var level := int(cfg.get_value(UPGRADES_SECTION, String(id), 0))
		if level > 0:
			upgrade_levels[id] = level
