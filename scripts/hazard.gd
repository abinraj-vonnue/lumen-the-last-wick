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
	_build_crystal_briar_art()


func _build_crystal_briar_art() -> void:
	var half_w := size.x * 0.5
	var half_h := size.y * 0.5
	var spike_count := maxi(3, int(round(size.x / 22.0)))
	var step := size.x / float(spike_count)

	# Dark shadow bed at the base of the hazard trench
	var base_bed := Polygon2D.new()
	base_bed.name = "BriarBed"
	base_bed.color = Color(0.14, 0.08, 0.16, 0.95)
	base_bed.z_index = -1
	base_bed.polygon = PackedVector2Array([
		Vector2(-half_w, half_h - 4.0),
		Vector2(half_w, half_h - 4.0),
		Vector2(half_w + 4.0, half_h + 4.0),
		Vector2(-half_w - 4.0, half_h + 4.0),
	])
	add_child(base_bed)

	# Primary jagged crystal silhouette
	visual.color = Color(0.76, 0.22, 0.34, 1.0)
	var poly := PackedVector2Array()
	poly.append(Vector2(-half_w, half_h))
	for i in spike_count:
		var x0 := -half_w + float(i) * step
		var xm := x0 + step * (0.42 if (i % 2 == 0) else 0.58)
		var x1 := x0 + step
		var peak_y := -half_h * (1.05 if (i % 2 == 0) else 0.82)
		poly.append(Vector2(x0 + step * 0.18, -half_h * 0.15))
		poly.append(Vector2(xm, peak_y))
		poly.append(Vector2(x1 - step * 0.12, half_h * 0.35))
	poly.append(Vector2(half_w, half_h))
	visual.polygon = poly

	# Inner luminous crimson-violet core facets for readability in darkness
	for i in spike_count:
		var facet := Polygon2D.new()
		var x0 := -half_w + float(i) * step
		var xm := x0 + step * (0.42 if (i % 2 == 0) else 0.58)
		var peak_y := -half_h * (0.85 if (i % 2 == 0) else 0.65)
		facet.color = Color(1.0, 0.48, 0.58, 0.78)
		facet.polygon = PackedVector2Array([
			Vector2(xm - step * 0.14, half_h * 0.45),
			Vector2(xm, peak_y),
			Vector2(xm + step * 0.12, half_h * 0.45),
		])
		visual.add_child(facet)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("request_death"):
		body.call("request_death")
