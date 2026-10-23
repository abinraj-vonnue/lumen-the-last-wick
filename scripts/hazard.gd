extends Area2D

@export var size: Vector2 = Vector2(120.0, 28.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var rectangle := collision_shape.shape as RectangleShape2D
	if rectangle != null:
		rectangle = rectangle.duplicate() as RectangleShape2D
		collision_shape.shape = rectangle
		rectangle.size = size
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.25, -size.y * 0.5),
		Vector2(0.0, size.y * 0.5),
		Vector2(size.x * 0.25, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
	])


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("request_death"):
		body.call("request_death")
