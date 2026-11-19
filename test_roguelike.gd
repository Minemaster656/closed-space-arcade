extends Node

var _failures: int = 0


func _ready() -> void:
	var game: Variant = load("res://assets/scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	_check(game.run_context != null, "run_context exists")
	_check(game.run_flow != null, "run_flow exists")
	_check(game.card_pool != null, "card_pool exists")
	_check(game.card_pool.pick_offers(4, game.run_context).size() == 2, "two offers from two cards")

	game.asteroid_spawner.stop()
	game.rocket.auto_shoot = false
	game.set("_distance", 50.0)
	game.comet_spawner.distance = 50.0
	game.comet_spawner.enabled = true
	await get_tree().create_timer(0.15).timeout

	var comet := game.comet_spawner.get_child(0) as Comet
	_check(comet != null, "comet spawned at 50m")
	if comet == null:
		_finish()
		return
	print("COMET CHILDREN: ", comet.get_children())
	_check(comet.get("_hint") != null, "first comet hint exists")

	comet.collect()
	await get_tree().create_timer(1.0).timeout

	_check(PauseManager.is_modal_frozen(), "reward modal frozen")
	_check(get_tree().paused, "tree paused for reward")
	var cards := game.reward_overlay.get_node("Root/Center/Panel/Margin/VBox/Cards") as HFlowContainer
	_check(cards.get_child_count() == 2, "two card views")
	var view := cards.get_child(0) as CardView
	_check(view != null, "first card view is CardView")

	if view != null:
		var chosen_id := view.card.id
		view.pressed.emit()
		await get_tree().create_timer(0.8).timeout
		_check(not PauseManager.is_modal_frozen(), "modal released after selection")
		_check(not get_tree().paused, "tree unpaused after selection")
		_check(game.run_context.get_card_count(chosen_id) == 1, "card applied once")

	await get_tree().create_timer(1.2).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "time scale returned to 1.0")

	PauseManager.pause()
	_check(PauseManager.is_paused(), "manual pause still works")
	PauseManager.resume()
	await get_tree().create_timer(1.3).timeout
	_check(not PauseManager.is_paused(), "manual resume still works")

	_finish()


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		push_error("FAIL " + label)


func _finish() -> void:
	print("RESULT failures=", _failures)
	get_tree().quit(0 if _failures == 0 else 1)
