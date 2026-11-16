extends Node2D

const STARFIELD_MARGIN: float = 64.0
const STARFIELD_RESIZE_THRESHOLD: float = 48.0
const META_SCENE: String = "res://assets/scenes/meta_progression.tscn"

@export var shake_strength_min: float = 0.35
@export var shake_strength_max: float = 3.0
@export var asteroid_speed_multiplier_max: float = 2.4
@export var rocket_screen_margin: float = 40.0

@onready var rocket: Rocket = $Rocket
@onready var asteroid_pool: AsteroidPool = $Managers/AsteroidPool
@onready var asteroid_spawner: AsteroidSpawner = $Managers/AsteroidSpawner
@onready var starfield: GPUParticles2D = $Starfield

var _starfield_applied_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	Music.play("fly")
	var visible := Utils.get_visible_world_rect()
	var rect := visible.grow(-rocket_screen_margin)
	var follower := rocket.get_node_or_null("FingerFollower") as FollowFinger2D
	if follower != null:
		follower.area = rect
	_apply_starfield(visible)
	rocket.died.connect(_on_rocket_died)


func _apply_starfield(rect: Rect2) -> void:
	starfield.position = rect.get_center()
	var mat := starfield.process_material as ParticleProcessMaterial
	if mat != null:
		mat.emission_box_extents = Vector3(rect.size.x * 0.5 + STARFIELD_MARGIN, rect.size.y * 0.5 + STARFIELD_MARGIN, 1.0)
	_starfield_applied_size = rect.size


func _sync_starfield_size() -> void:
	var rect := Utils.get_visible_world_rect()
	var size := rect.size
	var applied := _starfield_applied_size
	if applied == Vector2.ZERO:
		_apply_starfield(rect)
		return
	if absf(size.x - applied.x) <= STARFIELD_RESIZE_THRESHOLD and absf(size.y - applied.y) <= STARFIELD_RESIZE_THRESHOLD:
		return
	_apply_starfield(rect)


func _process(_delta: float) -> void:
	_sync_starfield_size()

	if not is_instance_valid(rocket) or rocket.is_dead():
		return

	var rect := Utils.get_visible_world_rect()
	var danger := clampf(
		inverse_lerp(rect.end.y, rect.position.y, rocket.global_position.y),
		0.0,
		1.0
	)

	rocket.set_danger(danger)
	asteroid_spawner.difficulty = danger
	asteroid_pool.speed_multiplier = lerpf(1.0, asteroid_speed_multiplier_max, danger)


func _on_rocket_died() -> void:
	asteroid_spawner.stop()
	_begin_meta_progression()


func _begin_meta_progression() -> void:
	var delay := rocket.break_cleanup_delay + 0.1
	await get_tree().create_timer(delay).timeout
	Transition.goto(META_SCENE, Transition.FADE_DURATION, Transition.FADE_DURATION, "progression")
