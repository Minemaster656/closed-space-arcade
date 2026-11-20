extends Node

signal metal_changed(total: int)
signal record_distance_changed(value: float)
signal record_metal_changed(value: int)
signal upgrades_changed
signal loaded

# Gameplay events (interceptable/modifiable by perks via listeners)
signal damage_taken(event: Dictionary)
signal shot_requested(event: Dictionary)
signal shot_fired(event: Dictionary)
signal projectile_hit_meteor(event: Dictionary)
signal meteor_shatter_requested(event: Dictionary)
signal asteroid_destroyed(event: Dictionary)
signal xp_granted(amount: int)

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "records"
const UPGRADES_SECTION := "upgrades"
const UNLOCKS_SECTION := "unlocks"
const SETTINGS_SECTION := "settings"

## Один ключ на весь прогресс. На вебе он читается и пишется только через
## Bridge.storage, чтобы Яндекс/Playgama могли хранить сохранение в облаке.
const STORAGE_KEY := "closed_space_arcade_save"
const SAVE_VERSION := 1

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
var unlocked_cards: Dictionary = {}
var music_muted: bool = false
var sfx_muted: bool = false

## Накопленная дробная часть бонуса металла, чтобы +10% не терялись на мелких дропах.
var _metal_fraction: float = 0.0

var _loaded: bool = false
var _loading: bool = false
var _web_storage: bool = false
var _save_in_flight: bool = false
var _save_pending: bool = false
var _save_countdown: float = -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_web_storage = OS.has_feature(&"web")
	load_save()


func _process(delta: float) -> void:
	if _save_countdown < 0.0:
		return
	_save_countdown -= delta
	if _save_countdown <= 0.0:
		_save_countdown = -1.0
		_flush_save()


func _notification(what: int) -> void:
	# Не теряем металл, если игрок свернул вкладку или закрыл игру сразу
	# после подобранного дропа, не дождавшись отложенного сохранения.
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, \
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			_flush_save()


func is_loaded() -> bool:
	return _loaded


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
	# Дропы приходят часто; пишем их пачкой, но обязательно сохраняем
	# прогресс, даже если рекорд по металлу не обновился.
	queue_save(1.0)


func reset_metal() -> void:
	metal = 0
	_metal_fraction = 0.0
	metal_changed.emit(metal)


## Полностью удаляет сохранение и сбрасывает прогресс в памяти.
## Нужно для отладки «с нуля». Настройки звука не сбрасываются.
func reset_save() -> void:
	var keep_music_muted := music_muted
	var keep_sfx_muted := sfx_muted

	metal = 0
	record_distance = 0.0
	record_metal = 0
	_metal_fraction = 0.0
	upgrade_levels.clear()
	unlocked_cards.clear()
	music_muted = keep_music_muted
	sfx_muted = keep_sfx_muted

	metal_changed.emit(metal)
	record_distance_changed.emit(record_distance)
	record_metal_changed.emit(record_metal)
	upgrades_changed.emit()

	if _web_storage:
		Bridge.storage.delete(STORAGE_KEY, _on_web_storage_deleted)
	else:
		_delete_local_save()
		_save_after_reset()


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


func is_card_unlocked(id: StringName) -> bool:
	return bool(unlocked_cards.get(id, false))


func unlock_card(id: StringName) -> void:
	if id == &"" or is_card_unlocked(id):
		return
	unlocked_cards[id] = true
	upgrades_changed.emit()
	save()


func buy_upgrade(id: StringName) -> bool:
	if not can_buy_upgrade(id):
		return false
	var def := get_upgrade_def(id)
	var level := get_upgrade_level(id)
	metal -= get_upgrade_price(id)
	upgrade_levels[id] = level + 1
	if def != null and def.unlock_card != null:
		unlocked_cards[def.unlock_card.id] = true
	metal_changed.emit(metal)
	upgrades_changed.emit()
	save()
	return true


func get_damage_bonus() -> float:
	return float(get_upgrade_level(UPGRADE_DAMAGE))


func get_shoot_rate_multiplier() -> float:
	return 1.0 + 0.5 * float(get_upgrade_level(UPGRADE_FIRE_RATE))


func get_bullet_speed_multiplier() -> float:
	return 1.0 + 0.5 * float(get_upgrade_level(UPGRADE_PROJECTILE_SPEED))


func get_bullet_pierce() -> int:
	return get_upgrade_level(UPGRADE_PIERCING)


func get_metal_multiplier() -> float:
	return 1.0 + 0.25 * float(get_upgrade_level(UPGRADE_MORE_METAL))


func set_music_muted(value: bool) -> void:
	if music_muted == value:
		return
	music_muted = value
	save()


func set_sfx_muted(value: bool) -> void:
	if sfx_muted == value:
		return
	sfx_muted = value
	save()


func _update_record_metal(value: int) -> void:
	if value <= record_metal:
		return
	record_metal = value
	record_metal_changed.emit(record_metal)


func save() -> void:
	_save_countdown = -1.0
	_flush_save()


func queue_save(delay: float = 1.0) -> void:
	if delay <= 0.0:
		save()
		return
	if _save_countdown < 0.0:
		_save_countdown = delay
	else:
		_save_countdown = maxf(_save_countdown, delay)


func load_save() -> void:
	if _loaded or _loading:
		return
	_loading = true

	if _web_storage:
		Bridge.storage.get(STORAGE_KEY, _on_web_storage_loaded, true)
	else:
		_load_local_save()


func _build_save_data() -> Dictionary:
	var upgrades: Dictionary = {}
	for id in UPGRADE_ORDER:
		var level := get_upgrade_level(id)
		if level > 0:
			upgrades[String(id)] = level

	var unlocks: Dictionary = {}
	for id in unlocked_cards.keys():
		if bool(unlocked_cards[id]):
			unlocks[String(id)] = true

	return {
		"version": SAVE_VERSION,
		"record_distance": record_distance,
		"metal": metal,
		"record_metal": record_metal,
		"metal_fraction": _metal_fraction,
		"upgrade_levels": upgrades,
		"unlocked_cards": unlocks,
		"music_muted": music_muted,
		"sfx_muted": sfx_muted,
	}


func _apply_save_data(data: Dictionary) -> void:
	record_distance = float(data.get("record_distance", 0.0))
	metal = int(data.get("metal", 0))
	record_metal = int(data.get("record_metal", 0))
	_metal_fraction = float(data.get("metal_fraction", 0.0))
	music_muted = bool(data.get("music_muted", false))
	sfx_muted = bool(data.get("sfx_muted", false))

	upgrade_levels.clear()
	var upgrades: Variant = data.get("upgrade_levels", {})
	if typeof(upgrades) == TYPE_DICTIONARY:
		for key in upgrades:
			var id := StringName(key)
			if UPGRADE_DEFS.has(id):
				upgrade_levels[id] = int(upgrades[key])

	unlocked_cards.clear()
	var unlocks: Variant = data.get("unlocked_cards", {})
	if typeof(unlocks) == TYPE_DICTIONARY:
		for key in unlocks:
			if bool(unlocks[key]):
				unlocked_cards[StringName(key)] = true

	metal_changed.emit(metal)
	record_distance_changed.emit(record_distance)
	record_metal_changed.emit(record_metal)
	upgrades_changed.emit()


func _mark_loaded() -> void:
	_loading = false
	if _loaded:
		return
	_loaded = true
	loaded.emit()
	if _save_pending:
		_save_pending = false
		_flush_save()


func _on_web_storage_loaded(success: bool, data: Variant) -> void:
	if not success:
		push_warning("GameState: не удалось прочитать сохранение из Bridge.storage")
		_apply_save_data({})
		_mark_loaded()
		return

	var save_data: Dictionary = {}
	if typeof(data) == TYPE_DICTIONARY:
		save_data = data
	elif typeof(data) == TYPE_STRING and not String(data).is_empty():
		var json := JSON.new()
		if json.parse(String(data)) == OK and typeof(json.data) == TYPE_DICTIONARY:
			save_data = json.data

	_apply_save_data(save_data)
	_mark_loaded()


func _load_local_save() -> void:
	var data: Dictionary = {}
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		data["record_distance"] = float(cfg.get_value(SAVE_SECTION, "record_distance", 0.0))
		data["metal"] = int(cfg.get_value(SAVE_SECTION, "metal", 0))
		data["record_metal"] = int(cfg.get_value(SAVE_SECTION, "record_metal", 0))
		data["metal_fraction"] = float(cfg.get_value(SAVE_SECTION, "metal_fraction", 0.0))
		data["music_muted"] = bool(cfg.get_value(SETTINGS_SECTION, "music_muted", false))
		data["sfx_muted"] = bool(cfg.get_value(SETTINGS_SECTION, "sfx_muted", false))

		var upgrades: Dictionary = {}
		for id in UPGRADE_ORDER:
			var level := int(cfg.get_value(UPGRADES_SECTION, String(id), 0))
			if level > 0:
				upgrades[String(id)] = level
		data["upgrade_levels"] = upgrades

		var unlocks: Dictionary = {}
		if cfg.has_section(UNLOCKS_SECTION):
			for key in cfg.get_section_keys(UNLOCKS_SECTION):
				if bool(cfg.get_value(UNLOCKS_SECTION, key, false)):
					unlocks[String(key)] = true
		data["unlocked_cards"] = unlocks

	_apply_save_data(data)
	_mark_loaded()


func _flush_save() -> void:
	if not _loaded:
		_save_pending = true
		return
	if _save_in_flight:
		_save_pending = true
		return

	var data := _build_save_data()
	if _web_storage:
		_save_in_flight = true
		Bridge.storage.set(STORAGE_KEY, data, _on_web_storage_saved)
	else:
		_save_local_save(data)
		if _save_pending:
			_save_pending = false
			queue_save(0.1)


func _on_web_storage_saved(success: bool) -> void:
	_save_in_flight = false
	if not success:
		push_warning("GameState: не удалось записать сохранение в Bridge.storage")
		queue_save(2.0)
		return
	if _save_pending:
		_save_pending = false
		_flush_save()


func _save_local_save(data: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SAVE_SECTION, "record_distance", float(data.get("record_distance", 0.0)))
	cfg.set_value(SAVE_SECTION, "metal", int(data.get("metal", 0)))
	cfg.set_value(SAVE_SECTION, "record_metal", int(data.get("record_metal", 0)))
	cfg.set_value(SAVE_SECTION, "metal_fraction", float(data.get("metal_fraction", 0.0)))
	cfg.set_value(SETTINGS_SECTION, "music_muted", bool(data.get("music_muted", false)))
	cfg.set_value(SETTINGS_SECTION, "sfx_muted", bool(data.get("sfx_muted", false)))

	var upgrades: Variant = data.get("upgrade_levels", {})
	if typeof(upgrades) == TYPE_DICTIONARY:
		for key in upgrades:
			cfg.set_value(UPGRADES_SECTION, String(key), int(upgrades[key]))

	var unlocks: Variant = data.get("unlocked_cards", {})
	if typeof(unlocks) == TYPE_DICTIONARY:
		for key in unlocks:
			if bool(unlocks[key]):
				cfg.set_value(UNLOCKS_SECTION, String(key), true)
	cfg.save(SAVE_PATH)


func _delete_local_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _on_web_storage_deleted(_success: bool) -> void:
	_save_after_reset()


func _save_after_reset() -> void:
	if _loaded:
		save()
