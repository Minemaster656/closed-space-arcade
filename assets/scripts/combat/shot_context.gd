extends RefCounted
class_name ShotContext

## Один залп. Ракета создаёт контекст и отдаёт его через
## GameState.shot_requested; карточки-поведения могут добавить свои снаряды.

var origin: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.UP
var specs: Array[ShotSpec] = []


static func create(shot_origin: Vector2, shot_direction: Vector2) -> ShotContext:
	var context := ShotContext.new()
	context.origin = shot_origin
	context.direction = shot_direction.normalized()
	context.specs.append(ShotSpec.create(context.direction))
	return context


func add_spec(spec: ShotSpec) -> void:
	if spec == null:
		return
	spec.direction = spec.direction.normalized()
	specs.append(spec)
