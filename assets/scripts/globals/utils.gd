extends Node2D

var _cached_rect: Rect2
var _cached_frame: int = -1


func get_visible_world_rect() -> Rect2:
	var frame := Engine.get_process_frames()
	if frame == _cached_frame:
		return _cached_rect

	var viewport := _game_viewport()
	var inv_canvas_transform: Transform2D = viewport.canvas_transform.affine_inverse()
	var viewport_size: Vector2 = viewport.get_visible_rect().size

	var top_left: Vector2 = inv_canvas_transform * Vector2.ZERO
	var bottom_right: Vector2 = inv_canvas_transform * viewport_size

	_cached_rect = Rect2(top_left, bottom_right - top_left)
	_cached_frame = frame
	return _cached_rect


## Игровая сцена живёт в SubViewport оболочки, а этот автолоад — в корневом
## viewport. Поэтому размеры мира нужно брать у игрового viewport'а.
func _game_viewport() -> Viewport:
	var viewport := get_tree().get_first_node_in_group(&"game_viewport") as Viewport
	return viewport if viewport != null else get_viewport()
