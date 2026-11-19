extends Node
class_name RunProgression

## XP и уровни внутри одного забега. Уровни дают обычные карточки,
## кометы — отдельные редкие награды.

signal xp_changed(xp: int, needed: int, level: int)
signal level_up(level: int)

const BASE_XP: int = 6
const XP_GROWTH: float = 1.32

var level: int = 1
var xp: int = 0
var xp_to_next: int = BASE_XP

var _context: RunContext


func setup(context: RunContext) -> void:
	_context = context
	level = 1
	xp = 0
	xp_to_next = _xp_for_level(level)
	GameState.xp_granted.connect(add_xp)
	xp_changed.emit(xp, xp_to_next, level)


func add_xp(amount: int) -> void:
	if amount <= 0:
		return

	xp += amount
	var gained_levels := 0
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		gained_levels += 1
		xp_to_next = _xp_for_level(level)

	xp_changed.emit(xp, xp_to_next, level)
	for i in gained_levels:
		level_up.emit(level - gained_levels + i + 1)


func _xp_for_level(current_level: int) -> int:
	return maxi(1, int(round(float(BASE_XP) * pow(XP_GROWTH, float(current_level - 1)))))
