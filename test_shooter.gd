extends Node2D

var _frames: int = 0
var _shooter: Node
var _max_bullets: int = 0
var _max_shards: int = 0


func _ready() -> void:
	var mgr := Node2D.new()
	mgr.name = "Managers"
	add_child(mgr)
	var pool := AsteroidPool.new()
	pool.name = "AsteroidPool"
	pool.default_scene = load("res://assets/prefabs/asteroid.tscn")
	mgr.add_child(pool)
	var ps: PackedScene = load("res://assets/prefabs/shooter_enemy.tscn")
	_shooter = ps.instantiate()
	add_child(_shooter)
	_shooter.global_position = Vector2(400, 300)
	_shooter.base_drift = 0.0


func _process(_delta: float) -> void:
	_frames += 1
	_max_bullets = maxi(_max_bullets, _count_class(self, "EnemyBullet"))
	_max_shards = maxi(_max_shards, _count_shards(self))
	if _frames == 1500 and is_instance_valid(_shooter):
		_shooter.take_damage(5.0)
	if _frames == 1600:
		print("TEST max_bullets=", _max_bullets, " max_shards=", _max_shards)
		print("TEST final_bullets=", _count_class(self, "EnemyBullet"))
		get_tree().quit()


func _count_class(n: Node, cls: String) -> int:
	var total := 0
	if n.is_in_group("enemy_bullet"):
		total += 1
	for c in n.get_children():
		total += _count_class(c, cls)
	return total


func _count_shards(n: Node) -> int:
	var total := 0
	if n is Asteroid and (n as Asteroid).type != null and (n as Asteroid).type.id == &"metal_shard":
		total += 1
	for c in n.get_children():
		total += _count_shards(c)
	return total