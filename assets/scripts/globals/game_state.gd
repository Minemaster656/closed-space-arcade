extends Node

signal metal_changed(total: int)

var metal: int = 0


func add_metal(amount: int = 1) -> void:
	if amount == 0:
		return
	metal += amount
	metal_changed.emit(metal)


func reset_metal() -> void:
	metal = 0
	metal_changed.emit(metal)
