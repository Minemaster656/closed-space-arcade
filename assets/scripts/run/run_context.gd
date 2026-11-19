extends Node
class_name RunContext

## Состояние одного забега: характеристики, выбранные карточки и их поведения.
## Создаётся игровой сценой и живёт до смерти ракеты/выхода из забега.

var rocket: Rocket
var game: Node
var asteroid_spawner: AsteroidSpawner
var comet_spawner: Node
var card_pool: CardPool

var stats: StatSheet = StatSheet.new()
var behavior_root: Node
var card_counts: Dictionary = {}

## Показывали ли уже упругую подсказку у кометы в этом забеге.
var hint_shown: bool = false


func setup(
	run_rocket: Rocket,
	run_game: Node,
	run_asteroid_spawner: AsteroidSpawner,
	run_comet_spawner: Node,
	run_card_pool: CardPool
) -> void:
	rocket = run_rocket
	game = run_game
	asteroid_spawner = run_asteroid_spawner
	comet_spawner = run_comet_spawner
	card_pool = run_card_pool

	behavior_root = Node.new()
	behavior_root.name = "CardBehaviors"
	add_child(behavior_root)

	stats.set_base(&"damage", rocket.damage)
	stats.set_base(&"shoot_cooldown", rocket.shoot_cooldown)
	stats.set_base(&"bullet_speed", rocket.bullet_speed)
	stats.set_base(&"bullet_pierce", float(rocket.bullet_pierce))
	stats.set_base(&"hp", rocket.hp)
	stats.recalculate()


## Применяет карточку. Возвращает false, если достигнут лимит стаков.
func apply_card(card: CardDef) -> bool:
	if card == null:
		return false

	var count := get_card_count(card.id)
	if card.max_stacks > 0 and count >= card.max_stacks:
		return false

	card_counts[card.id] = count + 1

	for modifier in card.modifiers:
		stats.add_modifier(modifier)
	stats.recalculate()
	_apply_stats()

	for behavior_scene in card.behaviors:
		if behavior_scene == null:
			continue
		var behavior := behavior_scene.instantiate()
		behavior_root.add_child(behavior)
		if behavior is CardBehavior:
			behavior.equip(self)

	return true


func get_card_count(id: StringName) -> int:
	return int(card_counts.get(id, 0))


func get_stat(stat: StringName, fallback: float = 0.0) -> float:
	return stats.get_value(stat, fallback)


func _apply_stats() -> void:
	if rocket == null:
		return
	rocket.damage = get_stat(&"damage", rocket.damage)
	rocket.shoot_cooldown = maxf(0.02, get_stat(&"shoot_cooldown", rocket.shoot_cooldown))
	rocket.bullet_speed = get_stat(&"bullet_speed", rocket.bullet_speed)
	rocket.bullet_pierce = int(round(get_stat(&"bullet_pierce", float(rocket.bullet_pierce))))
	rocket.hp = maxi(1, int(round(get_stat(&"hp", float(rocket.hp)))))
