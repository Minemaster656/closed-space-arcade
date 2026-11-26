extends Node2D
class_name VfxManager

## Пул VFX. Подписывается на игровые сигналы и проигрывает переиспользуемые
## эффекты. Никаких instantiate/free и AudioStreamPlayer на каждый хит.

const ROCK_TINT := Color(1.0, 0.62, 0.26)
const ICE_TINT := Color(0.55, 0.9, 1.0)
const METAL_TINT := Color(1.0, 0.85, 0.35)
const ENEMY_TINT := Color(1.0, 0.36, 0.24)
const GOLD_TINT := Color(1.0, 0.82, 0.3)
const COMET_TINT := Color(0.65, 0.85, 1.0)
const PLAYER_TINT := Color(1.0, 0.55, 0.25)

const PRESETS := {
    &"muzzle": {
        "lifetime": 0.18, "fade": 0.05, "priority": 0, "cooldown": 0.01,
        "sparks": 2, "flash": 1, "flash_tex": &"muzzle", "speed": 0.65,
        "scale": 0.75, "sound": &"shoot", "sound_volume": -5.0,
    },
    &"hit": {
        "lifetime": 0.42, "fade": 0.12, "priority": 0, "cooldown": 0.02,
        "sparks": 3, "flash": 1, "speed": 0.9, "scale": 0.65,
        "sound_volume": -3.0,
    },
    &"hit_heavy": {
        "lifetime": 0.5, "fade": 0.15, "priority": 1, "cooldown": 0.03,
        "sparks": 6, "flash": 1, "speed": 1.0,
        "scale": 0.8, "shake": 0.05, "sound_volume": -2.0,
    },
    &"break_rock": {
        "lifetime": 1.1, "fade": 0.2, "priority": 1, "cooldown": 0.04,
        "sparks": 5, "debris": 6, "debris_tex": &"rock", "smoke": 2,
        "flash": 1, "speed": 1.0, "scale": 0.8, "shake": 0.07,
        "sound": &"break_rock", "sound_volume": -2.0,
    },
    &"break_rock_large": {
        "lifetime": 1.25, "fade": 0.25, "priority": 2, "cooldown": 0.06,
        "sparks": 8, "debris": 10, "debris_tex": &"rock", "smoke": 4,
        "flash": 1, "speed": 1.15, "scale": 0.95, "shake": 0.14,
        "sound": &"break_rock", "sound_volume": -1.0,
    },
    &"break_ice": {
        "lifetime": 1.1, "fade": 0.2, "priority": 1, "cooldown": 0.04,
        "sparks": 5, "debris": 6, "debris_tex": &"ice", "smoke": 2,
        "flash": 1, "speed": 1.0, "scale": 0.8, "shake": 0.07,
        "sound": &"break_ice", "sound_volume": -2.0,
    },
    &"break_metal": {
        "lifetime": 1.05, "fade": 0.2, "priority": 1, "cooldown": 0.04,
        "sparks": 6, "debris": 4, "debris_tex": &"metal", "smoke": 1,
        "flash": 1, "speed": 1.0, "scale": 0.8, "shake": 0.07,
        "sound": &"break_metal", "sound_volume": -2.0,
    },
    &"explosion_enemy": {
        "lifetime": 1.2, "fade": 0.25, "priority": 2, "cooldown": 0.06,
        "sparks": 10, "debris": 4, "debris_tex": &"metal", "smoke": 4,
        "flash": 1, "speed": 1.25, "scale": 0.9, "shake": 0.18,
        "screen_flash": 0.05, "sound": &"explosion_enemy", "sound_volume": -1.0,
    },
    &"explosion_player": {
        "lifetime": 1.25, "fade": 0.25, "priority": 3, "cooldown": 0.0,
        "sparks": 18, "debris": 8, "debris_tex": &"rock", "smoke": 6,
        "flash": 1, "speed": 1.5, "scale": 1.1,
        "shake": 0.5, "screen_flash": 0.22,
    },
    &"pickup": {
        "lifetime": 0.55, "fade": 0.15, "priority": 0, "cooldown": 0.03,
        "sparkles": 3, "flash": 1, "speed": 0.7, "scale": 0.6,
        "sound": &"pickup_shard", "sound_volume": -5.0,
    },
    &"comet_pickup": {
        "lifetime": 0.8, "fade": 0.2, "priority": 1, "cooldown": 0.1,
        "sparkles": 8, "flash": 1, "speed": 0.9,
        "shake": 0.04, "screen_flash": 0.03, "scale": 0.85,
        "sound": &"pickup_comet", "sound_volume": -3.0,
    },
}

@export var effect_scene: PackedScene
@export var prewarm: int = 16
@export var max_active: int = 18
@export var max_instances: int = 28
@export var max_particles: int = 220
@export_range(0, 2, 1) var quality: int = 2
@export var auto_quality: bool = true
@export var camera_path: NodePath = ^"../../Camera2D"
@export var screen_flash_path: NodePath = ^"../../UI/ScreenFlash"

var _available: Array[VfxEffect] = []
var _active: Array[VfxEffect] = []
var _last_played: Dictionary = {}
var _total_created: int = 0
var _active_particles: int = 0

var _camera_shake: CameraShake2D
var _screen_flash: ScreenFlash
var _rocket: Rocket

var _fps_time: float = 0.0
var _fps_frames: int = 0
var _low_fps_time: float = 0.0


func _ready() -> void:
    _camera_shake = get_node_or_null(camera_path) as CameraShake2D
    _screen_flash = get_node_or_null(screen_flash_path) as ScreenFlash
    _rocket = get_tree().get_first_node_in_group("player") as Rocket
    if _rocket != null:
        _rocket.died.connect(_on_rocket_died)

    if effect_scene == null:
        push_error("VfxManager: effect_scene не задан")
        return

    for i in prewarm:
        var effect := _instantiate_effect()
        if effect != null:
            _available.append(effect)

    GameState.shot_requested.connect(_on_shot_requested)
    GameState.projectile_hit_resolved.connect(_on_hit_resolved)
    GameState.asteroid_destroyed.connect(_on_asteroid_destroyed)
    GameState.asteroid_broken.connect(_on_asteroid_broken)
    GameState.enemy_destroyed.connect(_on_enemy_destroyed)
    GameState.shard_collected.connect(_on_shard_collected)
    GameState.comet_collected.connect(_on_comet_collected)


func _process(delta: float) -> void:
    if not auto_quality:
        return
    _fps_time += delta
    _fps_frames += 1
    if _fps_time < 1.0:
        return

    var fps := float(_fps_frames) / _fps_time
    _fps_time = 0.0
    _fps_frames = 0
    if fps < 48.0:
        _low_fps_time += 1.0
    else:
        _low_fps_time = maxf(0.0, _low_fps_time - 1.0)

    if _low_fps_time >= 2.0 and quality > 0:
        quality -= 1
        _low_fps_time = 0.0


func set_quality(value: int) -> void:
    quality = clampi(value, 0, 2)


func play(
    id: StringName,
    world_position: Vector2,
    direction: Vector2 = Vector2.ZERO,
    tint: Color = Color.WHITE,
    scale_mult: float = 1.0,
    sound_key: StringName = &""
) -> bool:
    var preset: Dictionary = PRESETS.get(id, {})
    if preset.is_empty():
        return false

    var now := Time.get_ticks_msec()
    var cooldown := float(preset.get("cooldown", 0.0))
    if cooldown > 0.0:
        var last := int(_last_played.get(id, -1000000))
        if now - last < int(cooldown * 1000.0):
            return false

    var rect := Utils.get_visible_world_rect().grow(160.0)
    if not rect.has_point(world_position):
        return false

    var priority := int(preset.get("priority", 1))
    var particles := _estimate_particles(preset)
    if _active.size() >= max_active:
        if not _make_room(priority):
            return false
    if _active_particles + particles > max_particles and priority < 2:
        return false

    var effect := _get_effect()
    if effect == null:
        if not _make_room(priority):
            return false
        effect = _get_effect()
        if effect == null:
            return false

    effect.priority = priority
    effect.particle_budget = particles
    _active.append(effect)
    _active_particles += particles
    _last_played[id] = now
    var final_scale := scale_mult * float(preset.get("scale", 1.0))
    effect.play(preset, world_position, direction, tint, final_scale, quality)

    var shake := float(preset.get("shake", 0.0))
    if shake > 0.0 and _camera_shake != null:
        _camera_shake.add_trauma(shake)

    var screen_flash := float(preset.get("screen_flash", 0.0))
    if screen_flash > 0.0 and _screen_flash != null:
        _screen_flash.flash(tint, screen_flash, 0.22)

    var key: StringName = sound_key
    if key == &"":
        key = StringName(preset.get("sound", &""))
    if key != &"":
        AudioManager.play_2d(key, world_position, float(preset.get("sound_volume", 0.0)))

    return true


func _on_shot_requested(event: Dictionary) -> void:
    var context := event.get("context") as ShotContext
    if context == null:
        return
    play(&"muzzle", context.origin, context.direction, Color(1.0, 0.78, 0.4))


func _on_hit_resolved(event: Dictionary) -> void:
    if bool(event.get("lethal", false)):
        return

    var target: Area2D = event.get("target") as Area2D
    var position: Vector2 = event.get("position", Vector2.ZERO)
    var tint := ROCK_TINT
    var sound := &"hit_rock"
    var heavy := false

    if target is Asteroid:
        var asteroid := target as Asteroid
        if asteroid.type != null:
            var type_id := String(asteroid.type.id)
            if type_id == "ice":
                tint = ICE_TINT
                sound = &"hit_ice"
            elif type_id.begins_with("metal"):
                tint = METAL_TINT
                sound = &"hit_metal"
            if asteroid.type.collision_radius >= 35.0:
                heavy = true
    elif target is ShooterEnemy:
        tint = ENEMY_TINT
        sound = &"hit_metal"
        heavy = true

    play(&"hit_heavy" if heavy else &"hit", position, Vector2.ZERO, tint, 1.0, sound)


func _on_asteroid_destroyed(event: Dictionary) -> void:
    var type := event.get("type") as AsteroidType
    var type_id := String(event.get("type_id", ""))
    var position: Vector2 = event.get("position", Vector2.ZERO)
    var direction: Vector2 = event.get("direction", Vector2.ZERO)

    var id := &"break_rock"
    var tint := ROCK_TINT
    var sound := &"break_rock"
    var scale_mult := 1.0

    if type_id == "ice":
        id = &"break_ice"
        tint = ICE_TINT
        sound = &"break_ice"
    elif type_id.begins_with("metal"):
        id = &"break_metal"
        tint = METAL_TINT
        sound = &"break_metal"
    elif type != null and type.collision_radius >= 35.0:
        id = &"break_rock_large"

    play(id, position, direction, tint, scale_mult, sound)


func _on_asteroid_broken(event: Dictionary) -> void:
    var position: Vector2 = event.get("position", Vector2.ZERO)
    var direction: Vector2 = event.get("direction", Vector2.ZERO)
    play(&"break_ice", position, direction, ICE_TINT, 1.0, &"break_ice")


func _on_enemy_destroyed(event: Dictionary) -> void:
    var position: Vector2 = event.get("position", Vector2.ZERO)
    play(&"explosion_enemy", position, Vector2.ZERO, ENEMY_TINT, 1.0, &"explosion_enemy")


func _on_shard_collected(event: Dictionary) -> void:
    var position: Vector2 = event.get("position", Vector2.ZERO)
    play(&"pickup", position, Vector2.ZERO, GOLD_TINT, 1.0, &"pickup_shard")


func _on_comet_collected(event: Dictionary) -> void:
    var position: Vector2 = event.get("position", Vector2.ZERO)
    play(&"comet_pickup", position, Vector2.ZERO, COMET_TINT, 1.0, &"pickup_comet")


func _on_rocket_died() -> void:
    if not is_instance_valid(_rocket):
        _rocket = get_tree().get_first_node_in_group("player") as Rocket
    if not is_instance_valid(_rocket):
        return
    play(&"explosion_player", _rocket.global_position, Vector2.ZERO, PLAYER_TINT, 1.0)


func _estimate_particles(preset: Dictionary) -> int:
    return int(preset.get("sparks", 0)) \
        + int(preset.get("debris", 0)) \
        + int(preset.get("smoke", 0)) \
        + int(preset.get("flash", 0)) \
        + int(preset.get("ring", 0)) \
        + int(preset.get("sparkles", 0))


func _get_effect() -> VfxEffect:
    if not _available.is_empty():
        return _available.pop_back()
    if _total_created < max_instances:
        return _instantiate_effect()
    return null


func _instantiate_effect() -> VfxEffect:
    var effect := effect_scene.instantiate() as VfxEffect
    if effect == null:
        push_error("VfxManager: effect_scene не является VfxEffect")
        return null
    add_child(effect)
    effect.finished.connect(_on_effect_finished)
    effect.park()
    _total_created += 1
    return effect


func _on_effect_finished(effect: VfxEffect) -> void:
    _release(effect)


func _make_room(priority: int) -> bool:
    if priority < 2:
        return false
    var index := -1
    var lowest := 1000
    for i in _active.size():
        if _active[i].priority < lowest:
            lowest = _active[i].priority
            index = i
    if index < 0:
        return false
    _retire(_active[index])
    return true


func _retire(effect: VfxEffect) -> void:
    var index := _active.find(effect)
    if index < 0:
        return
    _active.remove_at(index)
    _active_particles = maxi(0, _active_particles - effect.particle_budget)
    effect.particle_budget = 0
    effect.fade_out(0.08)


func _release(effect: VfxEffect) -> void:
    if effect == null:
        return
    var index := _active.find(effect)
    if index >= 0:
        _active.remove_at(index)
        _active_particles = maxi(0, _active_particles - effect.particle_budget)
    effect.park()
    if not _available.has(effect):
        _available.append(effect)
