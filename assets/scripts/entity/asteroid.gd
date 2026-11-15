extends Area2D
class_name Asteroid

signal despawned(who: Area2D)

const GROUP_DAMAGEABLE := &"damageable"
const GROUP_COLLISION_DAMAGE := &"collision_damage"
const GROUP_ASTEROID := &"asteroid"
const GROUP_SHARD := &"shard"
const BOUNDS_CHECK_INTERVAL := 0.2

@export_group("Movement")
@export var despawn_margin: float = 0.15
@export var spin_speed: float = 0.9

@export_group("Magnet")
@export var magnet_radius: float = 210.0
@export var collect_radius: float = 40.0
@export var magnet_speed_min: float = 200.0
@export var magnet_speed_max: float = 1000.0

@export_group("Audio")
## Звук попадания пока не добавлен. Можно назначить позже в инспекторе.
@export var hit_sound: AudioStream
@export var hit_sound_volume_db: float = -6.0

var type: AsteroidType
var pool: AsteroidPool
var pool_scene: PackedScene

@onready var _sprite: Sprite2D = $Sprite
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _direction: Vector2 = Vector2.DOWN
var _speed: float = 100.0
var _hp: float = 1.0
var _spin: float = 0.0
var _sprite_base_scale: Vector2 = Vector2.ONE
var _player: Node2D
var _dead: bool = false
var _magnetized: bool = false
var _bounds_timer: float = 0.0
var _spawn_tween: Tween
var _flash_tween: Tween


func setup(
	new_type: AsteroidType,
	new_pool: AsteroidPool,
	scene: PackedScene,
	spawn_position: Vector2,
	spawn_direction: Vector2,
	spawn_speed: float
) -> void:
	_kill_tweens()

	type = new_type
	pool = new_pool
	pool_scene = scene
	_direction = spawn_direction.normalized()
	if _direction == Vector2.ZERO:
		_direction = Vector2.DOWN
	_speed = spawn_speed
	_hp = type.max_hp
	_dead = false
	_magnetized = false
	_bounds_timer = randf_range(0.0, BOUNDS_CHECK_INTERVAL)

	global_position = spawn_position
	rotation = randf_range(0.0, TAU)
	_spin = randf_range(-spin_speed, spin_speed)

	_sprite.texture = _pick_texture()
	_sprite.region_enabled = false
	_sprite.flip_h = randf() < 0.5
	_sprite.flip_v = randf() < 0.5
	_sprite_base_scale = Vector2.ONE * type.scale_multiplier
	_sprite.scale = _sprite_base_scale

	modulate = type.tint
	visible = true
	set_process(true)
	scale = Vector2.ZERO
	_spawn_tween = create_tween()
	_spawn_tween.tween_property(self, "scale", Vector2.ONE, randf_range(0.22, 0.32)) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var circle := _collision_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		_collision_shape.shape = circle
	circle.radius = type.collision_radius

	set_deferred("monitorable", true)
	_sync_groups()


func _sync_groups() -> void:
	if type == null:
		return

	var is_shard := type.collectible
	_set_group(GROUP_SHARD, is_shard)
	_set_group(GROUP_ASTEROID, not is_shard)
	_set_group(GROUP_DAMAGEABLE, type.damageable and not is_shard)
	_set_group(GROUP_COLLISION_DAMAGE, type.harmful and not is_shard)


func _set_group(group: StringName, enabled: bool) -> void:
	if enabled:
		add_to_group(group)
	else:
		remove_from_group(group)


func _process(delta: float) -> void:
	if _dead:
		return

	var speed_multiplier := 1.0
	if is_instance_valid(pool):
		speed_multiplier = pool.speed_multiplier

	global_position += _direction * _speed * speed_multiplier * delta
	rotation += _spin * delta

	if type.collectible:
		_update_magnet(delta)

	_bounds_timer -= delta
	if _bounds_timer <= 0.0:
		_bounds_timer = BOUNDS_CHECK_INTERVAL
		if _is_out_of_bounds():
			_dead = true
			despawned.emit(self)


func take_damage(amount: float) -> void:
	if not is_damageable():
		return

	_hp -= amount
	_play_hit_sound()
	if _hp <= 0.0:
		_shatter()
	else:
		_flash_hit()


func is_damageable() -> bool:
	return not _dead and type != null and type.damageable and not type.collectible



func is_harmful() -> bool:
	return not _dead and type != null and type.harmful and not type.collectible


func is_collectible() -> bool:
	return not _dead and type != null and type.collectible


## Принудительный сбор (например, при касании корпуса ракеты).
func collect() -> void:
	if not is_collectible():
		return
	_collect()


func park() -> void:
	_dead = true
	_kill_tweens()
	visible = false
	set_process(false)
	remove_from_group(GROUP_DAMAGEABLE)
	remove_from_group(GROUP_COLLISION_DAMAGE)
	remove_from_group(GROUP_ASTEROID)
	remove_from_group(GROUP_SHARD)
	set_deferred("monitorable", false)
	global_position = Vector2(0.0, 100000.0)


func _pick_texture() -> Texture2D:
	if type == null or type.textures.is_empty():
		return null
	return type.textures[randi_range(0, type.textures.size() - 1)]


func _kill_tweens() -> void:
	if _spawn_tween != null and _spawn_tween.is_valid():
		_spawn_tween.kill()
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()


func _flash_hit() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	modulate = Color(1.0, 0.18, 0.18, 1.0)
	_sprite.scale = _sprite_base_scale * 1.15
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(self, "modulate", type.tint, 0.18)
	_flash_tween.tween_property(_sprite, "scale", _sprite_base_scale, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shatter() -> void:
	_dead = true
	if type.child_type != null and is_instance_valid(pool) and type.child_max > 0:
		var count := randi_range(type.child_min, type.child_max)
		for i in count:
			var angle := TAU * (float(i) / float(count)) + randf_range(-0.35, 0.35)
			var offset := Vector2.from_angle(angle) * type.collision_radius * 0.5
			var child_direction := (_direction + Vector2.from_angle(angle) * 0.8).normalized()
			var child_speed := randf_range(type.child_type.min_speed, type.child_type.max_speed)
			pool.spawn(type.child_type, global_position + offset, child_direction, child_speed)
	despawned.emit(self)


func _update_magnet(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(_player):
		return

	var distance := global_position.distance_to(_player.global_position)
	if distance > magnet_radius:
		return

	if not _magnetized:
		_magnetized = true
		if _spawn_tween != null and _spawn_tween.is_valid():
			_spawn_tween.kill()
		_spawn_tween = create_tween()
		_spawn_tween.tween_property(self, "scale", Vector2.ONE * 0.55, 0.18) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	var pull := 1.0 - clampf(distance / magnet_radius, 0.0, 1.0)
	var pull_speed := lerpf(magnet_speed_min, magnet_speed_max, pull)
	global_position = global_position.move_toward(_player.global_position, pull_speed * delta)
	rotation += _spin * 4.0 * delta

	if distance <= collect_radius:
		_collect()


func _collect() -> void:
	if _dead:
		return
	_dead = true
	GameState.add_metal(type.metal_value)
	if _spawn_tween != null and _spawn_tween.is_valid():
		_spawn_tween.kill()
	_spawn_tween = create_tween().set_parallel(true)
	_spawn_tween.tween_property(self, "scale", Vector2.ZERO, 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_spawn_tween.tween_property(self, "rotation", rotation + 2.5, 0.12)
	_spawn_tween.finished.connect(_on_collect_finished)


func _on_collect_finished() -> void:
	despawned.emit(self)


func _is_out_of_bounds() -> bool:
	var rect := Utils.get_visible_world_rect()
	var margin := rect.size * despawn_margin
	var bounds := rect.grow_individual(margin.x, margin.y, margin.x, margin.y)
	return not bounds.has_point(global_position)


func _play_hit_sound() -> void:
	if hit_sound == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = hit_sound
	player.volume_db = hit_sound_volume_db
	player.global_position = global_position
	player.finished.connect(player.queue_free)
	get_tree().current_scene.add_child(player)
	player.play()
