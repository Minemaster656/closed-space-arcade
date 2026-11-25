extends Node2D
class_name SpawnNode

## Узел структуры спавна. Держит либо одну definition, либо набор вариантов
## definition: вес (SpawnVariant). definition — AsteroidType или EnemyType.
##
## Такие узлы собираются в сцену-структуру (SpawnStructure) и задают, что
## именно появляется в каждой точке относительно начала структуры.

@export_group("Definition")
## Один вариант спавна. Если задан — variants игнорируются.
@export var definition: Resource
## Взвешенный набор вариантов (используется, если definition не задан).
@export var variants: Array[SpawnVariant] = []

@export_group("Placement")
@export var direction: Vector2 = Vector2.DOWN
## Случайный разброс направления в градусах (±).
@export_range(0.0, 180.0, 0.1) var spread_degrees: float = 0.0
## 0 — брать скорость из min_speed/max_speed типа астероида.
@export var speed_override: float = 0.0


func spawn() -> void:
	var def := _pick_definition()
	if def == null:
		return
	var dir := direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	if spread_degrees > 0.0:
		dir = dir.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
	SpawnUtil.spawn(def, global_position, dir, speed_override)


func _pick_definition() -> Resource:
	if definition != null:
		return definition
	if variants.is_empty():
		return null

	var total := 0.0
	for variant in variants:
		if variant != null and variant.definition != null:
			total += maxf(0.0, variant.weight)
	if total <= 0.0:
		return null

	var roll := randf() * total
	for variant in variants:
		if variant == null or variant.definition == null:
			continue
		roll -= maxf(0.0, variant.weight)
		if roll <= 0.0:
			return variant.definition
	return null