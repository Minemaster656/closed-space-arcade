extends Camera2D
class_name CameraShake2D

## Тряска камеры по "травме": эффект добавляет импульс, камера сама затухает.
## В отличие от SmoothShake2D не трясёт камеру постоянно, а реагирует на события.

@export var max_offset: Vector2 = Vector2(9.0, 9.0)
@export var decay: float = 1.8
@export var noise_speed: float = 28.0

var _trauma: float = 0.0
var _time: float = 0.0
var _noise := FastNoiseLite.new()


func _ready() -> void:
    _noise.seed = randi()
    _noise.frequency = 0.5
    _noise.fractal_octaves = 2


func add_trauma(amount: float) -> void:
    _trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
    if _trauma <= 0.0:
        if offset != Vector2.ZERO:
            offset = Vector2.ZERO
        return

    _trauma = maxf(0.0, _trauma - decay * delta)
    _time += delta * noise_speed
    var strength := _trauma * _trauma
    offset = Vector2(
        _noise.get_noise_2d(_time, 0.0),
        _noise.get_noise_2d(0.0, _time)
    ) * max_offset * strength
