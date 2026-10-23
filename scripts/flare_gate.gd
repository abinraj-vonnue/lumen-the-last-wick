extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

var _opened: bool = false


func open() -> void:
	if _opened:
		return
	_opened = true
	collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.25)
	tween.tween_callback(visual.hide)
