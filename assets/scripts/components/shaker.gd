extends Node2D
class_name SmoothShake2D

## Плавная тряска Node2D.
## Покачивает локальную позицию узла по X и Y,
## используя сумму синусоид разной частоты для "живого" дрожания.

@export_group("Shake")

## Максимальный оффсет по X (в пикселях).
@export var max_offset_x: float = 10.0
## Максимальный оффсет по Y (в пикселях).
@export var max_offset_y: float = 10.0
## Сила тряски (амплитуда, множитель).
@export_range(0.0, 5.0, 0.01) var strength: float = 1.0
## Скорость тряски (частота).
@export_range(0.0, 100.0, 0.1) var speed: float = 15.0

## Включить/выключить тряску.
@export var enabled: bool = true

var _time: float = 0.0
var _last_offset: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	if not enabled:
		# Возвращаем узел в исходное состояние, если отключили во время тряски.
		if _last_offset != Vector2.ZERO:
			position -= _last_offset
			_last_offset = Vector2.ZERO
		return

	_time += delta * speed

	# Сумма синусоид даёт неповторяющееся, но плавное дрожание.
	var ox: float = (
		sin(_time * 1.00) * 0.55 +
		sin(_time * 2.31 + 1.3) * 0.30 +
		sin(_time * 3.73 + 2.7) * 0.15
	)
	var oy: float = (
		cos(_time * 1.17 + 0.6) * 0.55 +
		cos(_time * 2.71 + 2.1) * 0.30 +
		cos(_time * 4.13 + 1.7) * 0.15
	)

	var new_offset := Vector2(
		ox * max_offset_x,
		oy * max_offset_y
	) * strength

	# Применяем дельту смещения — так внешний код может свободно двигать узел.
	position += new_offset - _last_offset
	_last_offset = new_offset
