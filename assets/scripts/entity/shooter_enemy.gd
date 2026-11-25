extends Area2D
class_name ShooterEnemy

## Вражеский стрелок. Живёт в пуле, поэтому при смерти не удаляется,
## а проигрывает анимацию и возвращается в пул через сигнал despawned.
##
## Все характеристики берутся из EnemyType (tres), поэтому конкретный враг
## не хардкодится в скрипте — достаточно создать новый EnemyType.

signal despawned(who: Area2D)

const POOL_PATH: String = "Managers/AsteroidPool"
const BULLET_POOL_PATH: String = "Managers/EnemyBulletPool"
const DESPAWN_MARGIN: float = 0.15

const DEATH_DURATION: float = 0.35
const DEATH_SCALE: float = 1.6
const HIT_FLASH_DURATION: float = 0.18
const HIT_FLASH_COLOR: Color = Color(1.0, 0.18, 0.18, 1.0)

var type: EnemyType
var pool_scene: PackedScene

@onready var _sprite: Sprite2D = $Sprite2D
@onready var hp_bar: HPBar = $HPBar

var _hp: float = 1.0
var _shoot_timer: float = 0.0
var _dead: bool = false
var _pool: AsteroidPool
var _bullet_pool: EnemyBulletPool
var _bounds_timer: float = 0.0
var _sprite_base_scale: Vector2 = Vector2.ONE
var _flash_tween: Tween
var _death_tween: Tween


func _ready() -> void:
	_sprite_base_scale = _sprite.scale
	_resolve_pools()


## Готовит врага к выдаче из пула: применяет характеристики типа и ставит
## в указанную точку.
func setup(new_type: EnemyType, scene: PackedScene, spawn_position: Vector2) -> void:
	_resolve_pools()
	_kill_tweens()

	type = new_type
	pool_scene = scene
	_hp = type.max_hp
	_shoot_timer = type.shoot_interval
	_dead = false
	_bounds_timer = randf_range(0.0, 0.2)
	global_position = spawn_position
	rotation = 0.0
	scale = Vector2.ONE
	modulate = Color.WHITE
	_sprite.scale = _sprite_base_scale
	visible = true
	set_process(true)
	add_to_group("damageable")
	add_to_group("collision_damage")
	set_deferred("monitorable", true)
	hp_bar.reset(type.max_hp)


## Возвращает врага в неактивное состояние (вызывается пулом).
func park() -> void:
	_dead = true
	_kill_tweens()
	visible = false
	set_process(false)
	remove_from_group("damageable")
	remove_from_group("collision_damage")
	set_deferred("monitorable", false)
	scale = Vector2.ONE
	modulate = Color.WHITE
	_sprite.scale = _sprite_base_scale
	hp_bar.hide_bar()


func _process(delta: float) -> void:
	if _dead or type == null:
		return

	var mult := 1.0
	if is_instance_valid(_pool):
		mult = _pool.speed_multiplier

	global_position.y += type.base_drift * mult * delta

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = type.shoot_interval
		_shoot()

	_bounds_timer -= delta
	if _bounds_timer <= 0.0:
		_bounds_timer = 0.2
		if _is_out_of_bounds():
			_despawn_out_of_bounds()


func take_damage(amount: float) -> void:
	if _dead:
		return
	_hp -= amount
	hp_bar.set_health(_hp)
	hp_bar.show_bar()
	_flash_hit()
	if _hp <= 0.0:
		_die()


func _resolve_pools() -> void:
	var scene := Utils.get_game_root()
	if scene == null:
		return
	if not is_instance_valid(_pool):
		_pool = scene.get_node_or_null(POOL_PATH) as AsteroidPool
	if not is_instance_valid(_bullet_pool):
		_bullet_pool = scene.get_node_or_null(BULLET_POOL_PATH) as EnemyBulletPool


func _shoot() -> void:
	if _bullet_pool == null or _dead or type == null:
		return
	_bullet_pool.spawn(global_position + Vector2(0.0, type.bullet_offset))


func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("damageable")
	remove_from_group("collision_damage")
	set_deferred("monitorable", false)
	hp_bar.hide_bar()
	_drop_shards()
	_play_death_animation()


func _drop_shards() -> void:
	if type == null or type.shard_type == null or not is_instance_valid(_pool):
		return
	var count := randi_range(type.shard_min, type.shard_max)
	for i in count:
		var offset := Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
		var speed := randf_range(type.shard_type.min_speed, type.shard_type.max_speed)
		_pool.spawn(type.shard_type, global_position + offset, Vector2.DOWN, speed)


func _play_death_animation() -> void:
	set_process(false)
	_kill_tweens()
	modulate = Color.WHITE
	_death_tween = create_tween().set_parallel(true)
	_death_tween.tween_property(self, "modulate:a", 0.0, DEATH_DURATION) \
		.set_ease(Tween.EASE_OUT)
	_death_tween.tween_property(self, "scale", Vector2.ONE * DEATH_SCALE, DEATH_DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_death_tween.finished.connect(_on_death_finished)


func _on_death_finished() -> void:
	if not _dead:
		return
	despawned.emit(self)


func _despawn_out_of_bounds() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("damageable")
	remove_from_group("collision_damage")
	set_deferred("monitorable", false)
	despawned.emit(self)


func _flash_hit() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()

	modulate = HIT_FLASH_COLOR
	_sprite.scale = _sprite_base_scale * 1.15
	_flash_tween = create_tween().set_parallel(true)
	_flash_tween.tween_property(self, "modulate", Color.WHITE, HIT_FLASH_DURATION)
	_flash_tween.tween_property(_sprite, "scale", _sprite_base_scale, HIT_FLASH_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kill_tweens() -> void:
	for tween in [_flash_tween, _death_tween]:
		if tween != null and tween.is_valid():
			tween.kill()


func _is_out_of_bounds() -> bool:
	var rect := Utils.get_visible_world_rect()
	var margin := rect.size * DESPAWN_MARGIN
	var bounds := rect.grow_individual(margin.x, margin.y, margin.x, margin.y)
	return not bounds.has_point(global_position)