extends Node2D
class_name VfxEffect

## Один переиспользуемый эффект: несколько слоёв CPUParticles2D + таймер жизни.
## Сцена эффекта создаётся один раз пулом и потом только перезапускается.

signal finished(effect: VfxEffect)

const TEX_SPARK := preload("res://assets/sprites/fx/atlas_spark.png")
const TEX_SMOKE := preload("res://assets/sprites/fx/atlas_smoke.png")
const TEX_FLASH := preload("res://assets/sprites/fx/atlas_flash.png")
const TEX_MUZZLE := preload("res://assets/sprites/fx/atlas_muzzle.png")
const TEX_RING := preload("res://assets/sprites/fx/atlas_ring.png")
const TEX_PICKUP := preload("res://assets/sprites/fx/atlas_pickup.png")
const TEX_DEBRIS_ROCK := preload("res://assets/sprites/fx/atlas_debris_rock.png")
const TEX_DEBRIS_ICE := preload("res://assets/sprites/fx/atlas_debris_ice.png")
const TEX_DEBRIS_METAL := preload("res://assets/sprites/fx/atlas_debris_metal.png")

@onready var _sparks: CPUParticles2D = $Sparks
@onready var _debris: CPUParticles2D = $Debris
@onready var _smoke: CPUParticles2D = $Smoke
@onready var _flash: CPUParticles2D = $Flash
@onready var _ring: CPUParticles2D = $Ring
@onready var _sparkles: CPUParticles2D = $Sparkles
@onready var _timer: Timer = $Timer

var priority: int = 0
var particle_budget: int = 0

var _playing: bool = false
var _layers: Array[CPUParticles2D] = []
var _fading: bool = false
var _fade_elapsed: float = 0.0
var _fade_delay: float = 0.0
var _fade_duration: float = 0.0


func _ready() -> void:
    _layers = [_sparks, _debris, _smoke, _flash, _ring, _sparkles]
    for layer in _layers:
        layer.anim_speed_min = 0.0
        layer.anim_speed_max = 0.0
        layer.anim_offset_max = 0.999
    _timer.timeout.connect(_on_timer_timeout)
    park()


func play(
    preset: Dictionary,
    world_position: Vector2,
    direction: Vector2,
    tint: Color,
    scale_mult: float,
    quality: int
) -> void:
    if _playing:
        park()

    _playing = true
    _fading = false
    _fade_elapsed = 0.0
    visible = true
    set_process(true)
    position = world_position
    rotation = direction.angle() + PI * 0.5 if direction != Vector2.ZERO else 0.0
    scale = Vector2.ONE * scale_mult
    modulate = Color.WHITE

    var q_sparks := 1.0
    var q_debris := 1.0
    var q_smoke := 1.0
    var q_ring := 1.0
    var q_sparkles := 1.0
    if quality <= 0:
        q_sparks = 0.35
        q_debris = 0.0
        q_smoke = 0.0
        q_ring = 0.0
        q_sparkles = 0.5
    elif quality == 1:
        q_sparks = 0.7
        q_debris = 0.6
        q_smoke = 0.5
        q_sparkles = 0.8

    var speed := float(preset.get("speed", 1.0))
    var debris_texture := _debris_texture(preset.get("debris_tex", &"rock"))
    var flash_texture := TEX_MUZZLE if preset.get("flash_tex", &"flash") == &"muzzle" else TEX_FLASH

    _setup_layer(_sparks, _amount(preset, "sparks", q_sparks), TEX_SPARK, tint, 70.0 * speed, 240.0 * speed)
    _setup_layer(_debris, _amount(preset, "debris", q_debris), debris_texture, tint.darkened(0.15), 90.0 * speed, 260.0 * speed)
    _setup_layer(_smoke, _amount(preset, "smoke", q_smoke), TEX_SMOKE, Color(0.65, 0.65, 0.7).lerp(tint, 0.25), 10.0 * speed, 50.0 * speed)
    _setup_layer(_flash, _amount(preset, "flash", 1.0), flash_texture, tint, 0.0, 0.0)
    _setup_layer(_ring, _amount(preset, "ring", q_ring), TEX_RING, tint, 0.0, 0.0)
    _setup_layer(_sparkles, _amount(preset, "sparkles", q_sparkles), TEX_PICKUP, tint, 30.0 * speed, 90.0 * speed)

    var lifetime := maxf(0.05, float(preset.get("lifetime", 0.5)))
    _fade_duration = clampf(float(preset.get("fade", 0.15)), 0.01, lifetime)
    _fade_delay = maxf(0.0, lifetime - _fade_duration - 0.03)
    _timer.wait_time = lifetime
    _timer.start()


func _process(delta: float) -> void:
    if not _playing or _fading and _fade_elapsed >= _fade_duration:
        return

    _fade_elapsed += delta
    if not _fading:
        if _fade_elapsed < _fade_delay:
            return
        _fading = true
        _fade_elapsed = 0.0

    var t := clampf(_fade_elapsed / _fade_duration, 0.0, 1.0)
    modulate.a = 1.0 - t


## Быстрое затухание, если эффект нужно освободить под более важный.
func fade_out(duration: float = 0.1) -> void:
    if not _playing:
        return
    _fading = true
    _fade_delay = 0.0
    _fade_duration = maxf(0.01, duration)
    _fade_elapsed = 0.0
    _timer.stop()
    _timer.wait_time = _fade_duration
    _timer.start()
    set_process(true)


func park() -> void:
    _playing = false
    _fading = false
    _fade_elapsed = 0.0
    set_process(false)
    _timer.stop()
    for layer in _layers:
        layer.emitting = false
        layer.visible = false
    visible = false
    position = Vector2(0.0, 100000.0)
    priority = 0
    particle_budget = 0


func is_playing() -> bool:
    return _playing


func _setup_layer(
    layer: CPUParticles2D,
    amount: int,
    texture: Texture2D,
    layer_color: Color,
    speed_min: float,
    speed_max: float
) -> void:
    layer.emitting = false
    layer.visible = amount > 0
    if amount <= 0:
        return

    layer.amount = amount
    layer.texture = texture
    layer.color = layer_color
    layer.initial_velocity_min = speed_min
    layer.initial_velocity_max = speed_max
    layer.restart()
    layer.emitting = true


func _amount(preset: Dictionary, key: String, quality_scale: float) -> int:
    var base := int(preset.get(key, 0))
    if base <= 0:
        return 0
    return maxi(1, int(round(float(base) * quality_scale)))


func _debris_texture(kind: StringName) -> Texture2D:
    match kind:
        &"ice":
            return TEX_DEBRIS_ICE
        &"metal":
            return TEX_DEBRIS_METAL
        _:
            return TEX_DEBRIS_ROCK


func _on_timer_timeout() -> void:
    if not _playing:
        return
    _playing = false
    modulate.a = 0.0
    set_process(false)
    finished.emit(self)
