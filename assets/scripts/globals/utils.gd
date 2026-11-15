extends Node2D

func get_visible_world_rect() -> Rect2:
    var inv_canvas_transform: Transform2D = get_viewport().canvas_transform.affine_inverse()
    var viewport_size: Vector2 = get_viewport_rect().size
    
    var top_left: Vector2 = inv_canvas_transform * Vector2.ZERO
    var bottom_right: Vector2 = inv_canvas_transform * viewport_size
    
    return Rect2(top_left, bottom_right - top_left)
