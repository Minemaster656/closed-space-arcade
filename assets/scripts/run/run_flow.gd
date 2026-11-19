extends Node
class_name RunFlow

## Состояния одного забега вокруг награды за комету.
## Сцена сама не знает, какие карточки существуют: она только просит пул
## выдать предложения, а RunContext применяет выбранную карточку.

enum State { PLAYING, SLOWING, REWARD, DEAD }

const SLOW_DURATION: float = 0.45

var state: int = State.PLAYING

var _context: RunContext
var _overlay: RewardOverlay
var _card_pool: CardPool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(context: RunContext, overlay: RewardOverlay, card_pool: CardPool) -> void:
	_context = context
	_overlay = overlay
	_card_pool = card_pool

	if _overlay != null:
		_overlay.card_selected.connect(_on_card_selected)
		_overlay.closed.connect(_on_overlay_closed)


func on_comet_collected(_comet: Comet) -> void:
	if state != State.PLAYING:
		return

	state = State.SLOWING
	if _context.asteroid_spawner != null:
		_context.asteroid_spawner.stop()
	if _context.rocket != null:
		_context.rocket.auto_shoot = false

	var frozen := await PauseManager.slow_to_modal(SLOW_DURATION)
	if state == State.DEAD:
		return
	if not frozen:
		_restore_play()
		return

	state = State.REWARD
	var offers := _pick_offers()
	if offers.is_empty():
		_finish_reward()
		return
	if _overlay != null:
		_overlay.show_offers(offers)
	else:
		_finish_reward()


func on_run_dead() -> void:
	state = State.DEAD
	if _overlay != null:
		_overlay.abort()


func _on_card_selected(card: CardDef) -> void:
	if state != State.REWARD:
		return
	if _context != null:
		_context.apply_card(card)


func _on_overlay_closed() -> void:
	if state != State.REWARD:
		return
	state = State.PLAYING
	_restore_play()
	PauseManager.release_modal(PauseManager.RESUME_DURATION)


func _finish_reward() -> void:
	state = State.PLAYING
	_restore_play()
	PauseManager.release_modal(PauseManager.RESUME_DURATION)


func _restore_play() -> void:
	if _context == null:
		return
	if _context.rocket != null:
		_context.rocket.auto_shoot = true
	if _context.asteroid_spawner != null:
		_context.asteroid_spawner.enabled = true


func _pick_offers() -> Array[CardDef]:
	if _card_pool == null:
		return []
	var count := randi_range(_card_pool.min_offers, _card_pool.max_offers)
	return _card_pool.pick_offers(count, _context)
