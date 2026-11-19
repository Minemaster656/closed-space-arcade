extends Node
class_name RunFlow

## Состояния одного забега вокруг наград.
## Обычные награды приходят с уровней XP, редкие — с комет.
## Сцена сама не знает, какие карточки существуют: она только просит пул
## выдать предложения, а RunContext применяет выбранную карточку.

enum State { PLAYING, SLOWING, REWARD, DEAD }

const SLOW_DURATION: float = 0.45

var state: int = State.PLAYING

var _context: RunContext
var _overlay: RewardOverlay
var _card_pool: CardPool
var _reward_queue: Array[StringName] = []
var _reward_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(context: RunContext, overlay: RewardOverlay, card_pool: CardPool) -> void:
	_context = context
	_overlay = overlay
	_card_pool = card_pool

	if _overlay != null:
		_overlay.card_selected.connect(_on_card_selected)
		_overlay.closed.connect(_on_overlay_closed)
	if _context != null and _context.progression != null:
		_context.progression.level_up.connect(on_level_up)


func on_comet_collected(_comet: Comet) -> void:
	_enqueue_reward(&"comet", true)


func on_level_up(_level: int) -> void:
	_enqueue_reward(&"normal")


func on_run_dead() -> void:
	state = State.DEAD
	_reward_queue.clear()
	_reward_active = false
	if _overlay != null:
		_overlay.abort()


func _enqueue_reward(source: StringName, priority: bool = false) -> void:
	if state == State.DEAD:
		return
	if priority:
		_reward_queue.push_front(source)
	else:
		_reward_queue.append(source)
	if not _reward_active:
		_begin_reward()


func _begin_reward() -> void:
	if _reward_active or _reward_queue.is_empty() or state == State.DEAD:
		return

	_reward_active = true
	if state == State.PLAYING:
		state = State.SLOWING
		_stop_play()
		var frozen := await PauseManager.slow_to_modal(SLOW_DURATION)
		if state == State.DEAD:
			return
		if not frozen:
			_finish_reward()
			return

	state = State.REWARD
	_show_next_offer()


func _show_next_offer() -> void:
	while not _reward_queue.is_empty():
		var source: StringName = _reward_queue.pop_front()
		var offers := _pick_offers(source)
		if offers.is_empty():
			continue
		if _overlay == null:
			break
		_overlay.show_offers(offers)
		return

	_finish_reward()


func _on_card_selected(card: CardDef) -> void:
	if state != State.REWARD:
		return
	if _context != null:
		_context.apply_card(card)


func _on_overlay_closed() -> void:
	if state != State.REWARD:
		return
	if not _reward_queue.is_empty():
		_show_next_offer()
		return
	_finish_reward()


func _finish_reward() -> void:
	_reward_active = false
	if state == State.DEAD:
		return
	state = State.PLAYING
	_restore_play()
	PauseManager.release_modal(PauseManager.RESUME_DURATION)


func _stop_play() -> void:
	if _context == null:
		return
	if _context.asteroid_spawner != null:
		_context.asteroid_spawner.stop()
	if _context.rocket != null:
		_context.rocket.auto_shoot = false


func _restore_play() -> void:
	if _context == null:
		return
	if _context.rocket != null:
		_context.rocket.auto_shoot = true
	if _context.asteroid_spawner != null:
		_context.asteroid_spawner.enabled = true


func _pick_offers(source: StringName) -> Array[CardDef]:
	if _card_pool == null:
		return []
	var count := randi_range(_card_pool.min_offers, _card_pool.max_offers)
	return _card_pool.pick_offers(count, _context, source)
