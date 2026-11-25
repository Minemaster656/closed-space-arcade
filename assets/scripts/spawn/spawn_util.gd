extends Object
class_name SpawnUtil

## Единая точка спавна объектов локации. Понимает три вида spawn-объектов:
## AsteroidType, EnemyType и PackedScene со структурой спавна.
## Используется и спавнером локации, и узлами SpawnNode внутри структур.

const ASTEROID_POOL_PATH := "Managers/AsteroidPool"
const ENEMY_POOL_PATH := "Managers/EnemyPool"


## Спавнит объект спавна в точке position. direction/speed учитываются только
## для астероидов; для врагов и структур они игнорируются.
static func spawn(
	spawn_object: Resource,
	position: Vector2,
	direction: Vector2 = Vector2.DOWN,
	speed: float = 0.0
) -> Node:
	var root := Utils.get_game_root()
	var asteroid_pool := root.get_node_or_null(ASTEROID_POOL_PATH) as AsteroidPool
	var enemy_pool := root.get_node_or_null(ENEMY_POOL_PATH) as EnemyPool
	return spawn_with_pools(spawn_object, position, direction, speed, asteroid_pool, enemy_pool, root)


static func spawn_with_pools(
	spawn_object: Resource,
	position: Vector2,
	direction: Vector2,
	speed: float,
	asteroid_pool: AsteroidPool,
	enemy_pool: EnemyPool,
	host: Node
) -> Node:
	if spawn_object is AsteroidType:
		var asteroid_type := spawn_object as AsteroidType
		if asteroid_pool == null:
			push_error("SpawnUtil: AsteroidPool не найден")
			return null
		if speed <= 0.0:
			speed = randf_range(asteroid_type.min_speed, asteroid_type.max_speed)
		var dir := direction.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.DOWN
		return asteroid_pool.spawn(asteroid_type, position, dir, speed)

	if spawn_object is EnemyType:
		var enemy_type := spawn_object as EnemyType
		if enemy_pool == null:
			push_error("SpawnUtil: EnemyPool не найден")
			return null
		return enemy_pool.spawn(enemy_type, position)

	if spawn_object is PackedScene:
		var packed := spawn_object as PackedScene
		var node := packed.instantiate()
		if node == null:
			return null
		var parent := host if host is Node else Utils.get_game_root()
		(parent as Node).add_child(node)
		if node is SpawnStructure:
			(node as SpawnStructure).spawn(position)
		else:
			node.queue_free()
		return node

	push_error("SpawnUtil: неизвестный объект спавна: %s" % spawn_object)
	return null