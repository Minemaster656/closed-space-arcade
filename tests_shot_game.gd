extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game = (load("res://assets/scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await create_timer(1.5).timeout
	print("game visible=", game.visible, " root visible=", root.get_visible_rect())
	var label = game.get_node("UI/ScoreCounter")
	print("score label=", label.text, " rect=", label.get_global_rect(), " visible=", label.is_visible_in_tree())
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png("/tmp/opencode/game.png")
	print("saved ", img.get_size())
	quit(0)
