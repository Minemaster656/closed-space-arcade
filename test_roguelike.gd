extends Node

## Временный интеграционный тест рогалика.
## Запуск: ROCKET_TEST_NODEATH=1 godot --headless --path . res://test_roguelike.tscn

var _failures: int = 0


func _ready() -> void:
	await _run()
	print("RESULT failures=", _failures)
	get_tree().quit(0 if _failures == 0 else 1)


func _run() -> void:
	var game: Variant = load("res://assets/scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout

	_check(game.run_context != null, "run_context exists")
	_check(game.run_flow != null, "run_flow exists")
	_check(game.card_pool != null, "card_pool exists")
	_check(game.xp_bar != null, "xp_bar exists")

	# Не даём случайным убийствам на старте открыть лишний reward
	# до того, как тест сам выставит нужный порог XP.
	game.run_context.progression.xp = 0
	game.run_context.progression.xp_to_next = 999999

	_test_meta()
	_test_pool(game)
	await _test_multishot(game)
	await _test_xp_reward(game)
	await _test_comet_reward(game)
	_test_pause_confirm(game)
	await _test_exit_to_shop(game)


func _test_meta() -> void:
	_check(GameState.get_upgrade_def(&"damage").max_level == 5, "damage meta max 5")
	_check(GameState.get_upgrade_def(&"fire_rate").max_level == 1, "fire rate meta max 1")
	_check(GameState.get_upgrade_def(&"projectile_speed").max_level == 1, "projectile speed meta max 1")
	_check(GameState.get_upgrade_def(&"piercing").max_level == 1, "piercing meta max 1")
	_check(GameState.get_upgrade_def(&"more_metal").max_level == 1, "more metal meta max 1")
	_check(GameState.get_next_point_price() >= GameState.POINT_PRICE_BASE, "next point price base")


func _test_pool(game: Variant) -> void:
	var normal: Array[CardDef] = game.card_pool.pick_offers(4, game.run_context, &"normal")
	_check(normal.size() >= 2 and normal.size() <= 4, "normal offers count 2..4")
	var ids: Dictionary = {}
	for card in normal:
		ids[card.id] = true
	_check(ids.size() == normal.size(), "normal offers have no duplicates")

	var comet: Array[CardDef] = game.card_pool.pick_offers(2, game.run_context, &"comet")
	_check(comet.size() == 2, "comet offers count 2")
	for card in comet:
		_check(card.tags.has(&"comet"), "comet offer is rare comet card: " + String(card.id))


func _test_multishot(game: Variant) -> void:
	game.rocket.auto_shoot = false
	var multishot: CardDef = load("res://assets/resources/cards/multishot.tres")

	_check(game.run_context.apply_card(multishot), "multishot card applied 1")
	var specs := _emit_shot(game)
	_check(specs.size() == 2, "multishot stack 1 gives 2 bullets")
	_check(_has_angle(specs, 0.0), "even 2 keeps center bullet")
	_check(_has_angle(specs, 5.0) or _has_angle(specs, -5.0), "even 2 adds one side bullet")

	game.run_context.apply_card(multishot)
	specs = _emit_shot(game)
	_check(specs.size() == 3, "multishot stack 2 gives 3 bullets")
	_check(_angles_equal(specs, [-5.0, 0.0, 5.0]), "odd 3 is symmetric")

	game.run_context.apply_card(multishot)
	specs = _emit_shot(game)
	_check(specs.size() == 4, "multishot stack 3 gives 4 bullets")
	_check(_angles_equal(specs, [-5.0, 0.0, 5.0, 10.0]) \
		or _angles_equal(specs, [-10.0, -5.0, 0.0, 5.0]), "even 4 keeps center and random side")

	game.run_context.apply_card(multishot)
	specs = _emit_shot(game)
	_check(specs.size() == 5, "multishot stack 4 gives 5 bullets")
	_check(_angles_equal(specs, [-10.0, -5.0, 0.0, 5.0, 10.0]), "5 bullets are symmetric")

	_check(not game.run_context.apply_card(multishot), "multishot fifth stack rejected")
	_check(game.run_context.get_card_count(&"multishot") == 4, "multishot count stays 4")
	_check(game.run_context.behavior_root.get_child_count() == 1, "one multishot behavior only")


func _test_xp_reward(game: Variant) -> void:
	game.run_context.progression.xp = 0
	game.run_context.progression.xp_to_next = 18
	GameState.xp_granted.emit(18)
	# Сразу поднимаем следующий порог, чтобы фоновые убийства
	# не открыли второй reward во время проверки.
	game.run_context.progression.xp_to_next = 999999
	await get_tree().create_timer(0.8).timeout

	_check(game.run_context.progression.level == 2, "xp level reaches 2")
	_check(PauseManager.is_modal_frozen(), "xp reward frozen modal")
	_check(get_tree().paused, "xp reward pauses tree")
	_check(game.xp_bar.get_node("Level").text == tr("upgrade_level") % 2, "xp bar level label")

	var cards := _card_container(game)
	_check(cards.get_child_count() >= 2, "xp reward shows cards")
	if cards.get_child_count() > 0:
		var view := cards.get_child(0) as CardView
		_check(view != null, "xp reward card is CardView")
		if view != null:
			view.pressed.emit()
			await get_tree().create_timer(0.8).timeout
			_check(not PauseManager.is_modal_frozen(), "xp modal released")
			_check(not get_tree().paused, "xp tree unpaused")
			# Изолируем следующие проверки от случайных level-up'ов
			# из уже выпущенных пуль и астероидов на экране.
			game.run_context.progression.xp = 0
			game.run_context.progression.xp_to_next = 999999


func _test_comet_reward(game: Variant) -> void:
	game.asteroid_spawner.stop()
	game.rocket.auto_shoot = false
	game.set("_distance", 50.0)
	game.comet_spawner.distance = 50.0
	game.comet_spawner.enabled = true
	await get_tree().create_timer(0.15).timeout

	var comet := game.comet_spawner.get_child(0) as Comet
	_check(comet != null, "comet spawned at 50m")
	if comet == null:
		return
	_check(comet.get("_hint") != null, "first comet hint exists")

	comet.collect()
	await get_tree().create_timer(0.8).timeout
	_check(PauseManager.is_modal_frozen(), "comet reward frozen modal")
	_check(get_tree().paused, "comet reward pauses tree")
	var cards := _card_container(game)
	_check(cards.get_child_count() == 2, "comet shows two rare cards")
	if cards.get_child_count() > 0:
		var view := cards.get_child(0) as CardView
		_check(view != null and view.card.tags.has(&"comet"), "comet card is rare")
		if view != null:
			view.pressed.emit()
			await get_tree().create_timer(0.8).timeout
			_check(not PauseManager.is_modal_frozen(), "comet modal released")


func _test_pause_confirm(game: Variant) -> void:
	PauseManager.pause()
	await get_tree().create_timer(0.1).timeout
	_check(PauseManager.is_paused(), "manual pause works")
	game.pause_overlay.call("_on_shop_pressed")
	_check(game.pause_overlay.get_node("Root/ConfirmCenter").visible, "shop confirm opens")
	game.pause_overlay.call("_hide_confirm", false)
	PauseManager.resume()
	await get_tree().create_timer(1.1).timeout
	_check(not PauseManager.is_paused(), "manual resume works")


func _test_exit_to_shop(game: Variant) -> void:
	PauseManager.pause()
	await get_tree().create_timer(0.1).timeout
	game.pause_overlay.call("_on_shop_pressed")
	game.pause_overlay.call("_on_confirm_pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not PauseManager.is_paused(), "shop exit unpauses")
	_check(game.rocket.is_dead() or game.rocket.get("_death_pending"), "shop exit kills rocket")


func _emit_shot(game: Variant) -> Array[ShotSpec]:
	var shot := ShotContext.create(game.rocket.global_position, Vector2.UP)
	GameState.shot_requested.emit({"context": shot, "rocket": game.rocket})
	return shot.specs


func _has_angle(specs: Array[ShotSpec], target: float) -> bool:
	for spec in specs:
		if absf(_angle_of(spec) - target) < 0.01:
			return true
	return false


func _angles_equal(specs: Array[ShotSpec], expected: Array) -> bool:
	if specs.size() != expected.size():
		return false
	var actual: Array[float] = []
	for spec in specs:
		actual.append(snappedf(_angle_of(spec), 0.01))
	actual.sort()
	var sorted_expected: Array[float] = []
	for value in expected:
		sorted_expected.append(float(value))
	sorted_expected.sort()
	for i in actual.size():
		if absf(actual[i] - sorted_expected[i]) > 0.01:
			return false
	return true


func _angle_of(spec: ShotSpec) -> float:
	return rad_to_deg(Vector2.UP.angle_to(spec.direction))


func _card_container(game: Variant) -> HFlowContainer:
	return game.reward_overlay.get_node("Root/Center/Panel/Margin/VBox/Cards") as HFlowContainer


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS ", label)
	else:
		_failures += 1
		push_error("FAIL " + label)
