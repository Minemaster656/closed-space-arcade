extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	TranslationServer.set_locale("ru")
	var meta = (load("res://assets/scenes/meta_progression.tscn") as PackedScene).instantiate()
	root.add_child(meta)
	await process_frame
	await process_frame
	meta.get_node("Pages/MainPage/Center/VBox/ShopButton").pressed.emit()
	await create_timer(1.0).timeout
	var rows = meta.get_node("Pages/ShopPage/Margin/VBox/Scroll/Rows")
	print("window=", DisplayServer.window_get_size(), " vp=", root.get_visible_rect())
	for i in rows.get_child_count():
		print("row ", i, " rect=", rows.get_child(i).get_global_rect(), " visible=", rows.get_child(i).is_visible_in_tree())
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var err := img.save_png("/tmp/opencode/shop.png")
	print("screenshot err=", err, " size=", img.get_size())
	quit(0)
