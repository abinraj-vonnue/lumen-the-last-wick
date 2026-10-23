extends StaticBody2D

@export var light_source_path: NodePath
@export var required_light_distance: float = 300.0
@export var fade_speed: float = 5.0

@onready var visual: Polygon2D = $Visual
@onready var platform_collision: CollisionShape2D = $CollisionShape2D

var _is_active: bool = false
var _fade_target: float = 0.0


func _ready() -> void:
	_is_active = false
	visual.modulate.a = 0.0
	visual.visible = true
	platform_collision.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	var light_source := get_node_or_null(light_source_path) as Node2D

	if light_source == null:
		_set_active(false)
	else:
		var distance := global_position.distance_to(
			light_source.global_position
		)
		_set_active(distance <= required_light_distance)

	var target_alpha := 1.0 if _is_active else 0.0
	visual.modulate.a = move_toward(
		visual.modulate.a,
		target_alpha,
		fade_speed * delta
	)


func _set_active(active: bool) -> void:
	if _is_active == active:
		return

	_is_active = active
	platform_collision.set_deferred("disabled", not active)
