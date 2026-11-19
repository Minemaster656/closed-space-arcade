extends RefCounted
class_name ShotSpec

## Описание одного снаряда в залпе. Поведения карточек могут добавлять
## новые ShotSpec в ShotContext, не трогая код ракеты.

var direction: Vector2 = Vector2.UP
var position_offset: Vector2 = Vector2.ZERO
var damage_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var pierce_bonus: int = 0


static func create(shot_direction: Vector2) -> ShotSpec:
	var spec := ShotSpec.new()
	spec.direction = shot_direction.normalized()
	return spec
