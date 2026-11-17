extends SceneTree

func _initialize() -> void:
	var ps0: PackedScene = load("res://assets/prefabs/enemy_bullet.tscn")
	var node: Node = ps0.instantiate()
	var s: Script = load("res://assets/scripts/entity/enemy_bullet.gd")
	node.set_script(s)
	var ps := PackedScene.new()
	ps.pack(node)
	ResourceSaver.save(ps, "res://assets/prefabs/enemy_bullet.tscn")
	print("saved script=", node.get_script())
	quit()