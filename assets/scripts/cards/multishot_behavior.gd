extends CardBehavior

## Веерный выстрел. Всегда сохраняет пулю в 0°.
## Нечётное количество — симметрично. Чётное — как нечётное плюс одна
## дополнительная пуля, которая каждый залп случайно выбирает сторону.
## Соседние пули расходятся минимум на 5°, максимум — 45° от центра.

const MAX_BULLETS: int = 5
const STEP_DEGREES: float = 5.0
const MAX_SPREAD_DEGREES: float = 45.0


func _on_equip() -> void:
	GameState.shot_requested.connect(_on_shot_requested)


func _on_shot_requested(event: Dictionary) -> void:
	if context == null:
		return

	var shot := event.get("context") as ShotContext
	if shot == null or shot.specs.is_empty():
		return

	var count := clampi(1 + context.get_card_count(&"multishot"), 1, MAX_BULLETS)
	if count <= 1:
		return

	var base := shot.specs[0]
	if base == null:
		return

	var angles := _build_angles(count)
	var index := shot.specs.find(base)
	if index >= 0:
		shot.specs.remove_at(index)

	for angle in angles:
		var spec := ShotSpec.new()
		var radians := deg_to_rad(angle)
		spec.direction = base.direction.rotated(radians).normalized()
		spec.position_offset = base.position_offset.rotated(radians)
		spec.damage_multiplier = base.damage_multiplier
		spec.speed_multiplier = base.speed_multiplier
		spec.pierce_bonus = base.pierce_bonus
		shot.specs.append(spec)


func _build_angles(count: int) -> Array[float]:
	var angles: Array[float] = []
	var odd_count := count if count % 2 == 1 else count - 1
	var half := (odd_count - 1) / 2

	for i in range(-half, half + 1):
		angles.append(float(i) * STEP_DEGREES)

	if count % 2 == 0:
		var side := -1.0 if randi() % 2 == 0 else 1.0
		angles.append(side * float(half + 1) * STEP_DEGREES)

	for i in angles.size():
		angles[i] = clampf(angles[i], -MAX_SPREAD_DEGREES, MAX_SPREAD_DEGREES)

	return angles
