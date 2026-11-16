extends Node2D
class_name Rocket

signal died

@export var pool: BulletPool
@export var hp: float = 1
@export var damage: float = 1
@export var shoot_cooldown: float = 0.5
@export var bullet_speed: float = 900.0
@export var auto_shoot: bool = true

@export_group("Danger")
@export var shake_strength_min: float = 0.35
@export var shake_strength_max: float = 3.0

@export_group("Death")
@export var break_sound_volume_db: float = -4.0
@export var break_cleanup_delay: float = 1.15

@onready var _shoot_point: Node2D = $ShootPoint
@onready var _sprite: SmoothShake2D = $Sprite
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _break_sound: AudioStreamPlayer = $BreakSound
@onready var _finger_follower: FollowFinger2D = $FingerFollower

var _shoot_timer: float = 0.0
var _dead: bool = false
var _death_pending: bool = false


func _ready() -> void:
	_hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	_sprite.strength = shake_strength_min
	_break_sound.volume_db = break_sound_volume_db


func _process(delta: float) -> void:
	if _dead or not auto_shoot or pool == null:
		return

	_shoot_timer -= delta
	if _shoot_timer > 0.0:
		return

	_shoot()
	_shoot_timer = shoot_cooldown


func is_dead() -> bool:
	return _dead


func set_danger(multiplier: float) -> void:
	if _dead:
		return
	var base := lerpf(shake_strength_min, shake_strength_max, 0.5)
	_sprite.strength = base * multiplier * 0.5


func _shoot() -> void:
	var bullet := pool.spawn(
		_shoot_point.global_position,
		-_shoot_point.global_transform.y.normalized()
	)
	if bullet == null:
		return

	bullet.speed = bullet_speed
	bullet.damage = damage
	GameState.shot_fired.emit({
		"rocket": self,
		"bullet": bullet,
		"position": _shoot_point.global_position,
		"direction": -_shoot_point.global_transform.y.normalized(),
		"damage": damage,
	})


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if _dead or _death_pending:
		return

	var asteroid := area as Asteroid
	var tid := "<none>"
	if asteroid != null and asteroid.type != null:
		tid = asteroid.type.id
	print("ROCKET AREA ENTER type=", tid,
		" type.collectible=", asteroid != null and asteroid.type != null and asteroid.type.collectible,
		" dead=", asteroid != null and asteroid._dead,
		" collectible()=", asteroid != null and asteroid.is_collectible(),
		" harmful=", asteroid != null and asteroid.is_harmful(),
		" groups=", area.get_groups())

	if asteroid != null and asteroid.is_collectible():
		asteroid.collect()
		return

	if area.is_in_group("collision_damage"):
		print("ROCKET HIT area=", area.name, " type=", tid, " groups=", area.get_groups(), " parent=", area.get_parent())
		var hit_damage := 1.0
		if asteroid != null and asteroid.type != null:
			hit_damage = asteroid.type.damage
		GameState.damage_taken.emit({
			"target": self,
			"source": area,
			"damage": hit_damage,
			"position": global_position,
		})
		if OS.has_environment("ROCKET_TEST_NODEATH"):
			return
		_death_pending = true
		_break_apart.call_deferred()


func _break_apart() -> void:
	if _dead:
		return
	_death_pending = false
	_dead = true
	died.emit()
	set_process(false)
	_hurtbox.set_deferred("monitoring", false)
	_finger_follower.set_process(false)
	_finger_follower.set_process_unhandled_input(false)
	_sprite.set_process(false)
	_break_sound.play()

	var host := get_tree().current_scene
	if host == null:
		host = get_parent()

	var parts: Array[Node] = []
	_collect_lego_parts(self, parts)

	for part in parts:
		if part is not Node2D:
			continue

		var node := part as Node2D
		var start_position := node.global_position
		var fly_direction := Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		if fly_direction == Vector2.ZERO:
			fly_direction = Vector2.UP

		var target_position := start_position + fly_direction * randf_range(90.0, 220.0)
		var duration := randf_range(0.55, 1.0)
		var target_rotation := node.rotation + randf_range(-TAU, TAU)
		var target_scale := node.scale * randf_range(0.4, 0.8)

		node.reparent(host, true)
		node.global_position = start_position

		var tween := node.create_tween().set_parallel(true)
		tween.tween_property(node, "global_position", target_position, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "rotation", target_rotation, duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "scale", target_scale, duration)
		tween.finished.connect(node.queue_free)

	_sprite.visible = false

	await get_tree().create_timer(break_cleanup_delay).timeout
	queue_free()


func _collect_lego_parts(node: Node, out: Array[Node]) -> void:
	for child in node.get_children():
		if child.is_in_group("lego-break"):
			out.append(child)
		_collect_lego_parts(child, out)
