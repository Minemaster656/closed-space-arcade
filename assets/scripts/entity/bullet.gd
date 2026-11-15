extends Area2D


@export var speed:float = 10

@export var direction: Vector2 = Vector2.UP

signal disposed(who: Area2D)

func _process(delta: float) -> void:
    global_position += direction * delta * speed

func _check_out_of_screen():
    var positions = Utils.et_visible_world_rect()
    # out of 1.25 screen
    disposed.emit(self)
