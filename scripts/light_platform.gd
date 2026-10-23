
extends StaticBody2D

@export var light_source_path: NodePath
@export var required_light_distance: float = 300.0
@export var deactivation_distance: float = 330.0
@export var fade_speed: float = 5.0

@export var inactive_color: Color = Color("#7774B8")
@export var active_color: Color = Color("#D6C8FF")

@onready var visual: Polygon2D = $Visual
@onready var platform_collision: CollisionShape2D = $CollisionShape2D

var _is_active: bool = false
var _light_source: Node2D
var _ray_query: PhysicsRayQueryParameters2D
var _time: float = 0.0
var _dormant_outline: Polygon2D
var _rune_core: Polygon2D
var _aura_glow: Polygon2D


func _ready() -> void:
	_is_active = false
	visual.visible = true
	visual.modulate = inactive_color
	visual.modulate.a = 0.0
	_build_rune_slab_art()
	platform_collision.set_deferred("disabled", true)
	_light_source = get_node_or_null(light_source_path) as Node2D
	var excluded: Array[RID] = [get_rid()]
	var owner_node: Node = _light_source
	while owner_node != null:
		if owner_node is CollisionObject2D:
			excluded.append((owner_node as CollisionObject2D).get_rid())
		owner_node = owner_node.get_parent()
	_ray_query = PhysicsRayQueryParameters2D.create(global_position, global_position)
	_ray_query.exclude = excluded
	_ray_query.collide_with_bodies = true
	_ray_query.collide_with_areas = false


func _build_rune_slab_art() -> void:
	# Bevelled floating stone rune-slab silhouette inside the Visual node
	visual.color = Color("#9b92dc")
	visual.polygon = PackedVector2Array([
		Vector2(-90, -6), Vector2(-82, -10), Vector2(82, -10), Vector2(90, -6),
		Vector2(86, 6), Vector2(72, 11), Vector2(0, 13), Vector2(-72, 11), Vector2(-86, 6),
	])

	var top_trim := Polygon2D.new()
	top_trim.color = Color(1.0, 0.92, 0.76, 0.85)
	top_trim.polygon = PackedVector2Array([
		Vector2(-82, -10), Vector2(82, -10), Vector2(78, -6), Vector2(-78, -6),
	])
	visual.add_child(top_trim)

	_rune_core = Polygon2D.new()
	_rune_core.color = Color(1.0, 0.86, 0.52, 0.9)
	_rune_core.polygon = PackedVector2Array([
		Vector2(-52, -2), Vector2(0, -5), Vector2(52, -2),
		Vector2(36, 3), Vector2(0, 5), Vector2(-36, 3),
	])
	visual.add_child(_rune_core)

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_aura_glow = Polygon2D.new()
	_aura_glow.color = Color(0.95, 0.78, 0.45, 0.24)
	_aura_glow.material = add_mat
	_aura_glow.z_index = -1
	_aura_glow.polygon = PackedVector2Array([
		Vector2(-98, -14), Vector2(98, -14), Vector2(92, 18), Vector2(-92, 18),
	])
	visual.add_child(_aura_glow)

	# Subtle dormant astral trace so players can read unlit platform locations
	_dormant_outline = Polygon2D.new()
	_dormant_outline.name = "DormantTrace"
	_dormant_outline.color = Color(0.48, 0.52, 0.78, 0.22)
	_dormant_outline.z_index = -2
	_dormant_outline.polygon = PackedVector2Array([
		Vector2(-86, -8), Vector2(86, -8), Vector2(82, 8), Vector2(-82, 8),
	])
	add_child(_dormant_outline)


func _physics_process(delta: float) -> void:
	_time += delta
	var should_activate := false

	if is_instance_valid(_light_source):
		var distance := _light_source.global_position.distance_to(_closest_platform_point())
		var flare_bonus := 0.0
		if _light_source.has_method("get_platform_range_bonus"):
			flare_bonus = _light_source.call("get_platform_range_bonus")
		var limit := deactivation_distance if _is_active else required_light_distance
		limit += flare_bonus
		if distance <= limit:
			should_activate = _has_clear_line_of_sight(_light_source)

	_set_active(should_activate)

	var target_color := active_color if _is_active else inactive_color
	var target_alpha := 1.0 if _is_active else 0.0

	visual.modulate = visual.modulate.lerp(
		Color(target_color, target_alpha),
		minf(fade_speed * delta, 1.0)
	)
	if _dormant_outline != null:
		var dormant_pulse := 0.18 + sin(_time * 2.6 + global_position.x * 0.02) * 0.06
		_dormant_outline.color.a = lerpf(dormant_pulse, 0.0, visual.modulate.a)


func _closest_platform_point() -> Vector2:
	var rectangle := platform_collision.shape as RectangleShape2D
	if rectangle == null:
		return global_position
	var half_size := rectangle.size * 0.5
	var local_point := platform_collision.to_local(_light_source.global_position)
	local_point.x = clampf(local_point.x, -half_size.x, half_size.x)
	local_point.y = clampf(local_point.y, -half_size.y, half_size.y)
	return platform_collision.to_global(local_point)


func _has_clear_line_of_sight(light_source: Node2D) -> bool:
	var world := get_world_2d()
	if world == null:
		return false

	_ray_query.from = light_source.global_position
	_ray_query.to = _closest_platform_point()
	var hit := world.direct_space_state.intersect_ray(_ray_query)
	return hit.is_empty()

func _set_active(active: bool) -> void:
	if _is_active == active:
		return

	_is_active = active
	platform_collision.set_deferred("disabled", not active)
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "platform_on" if active else "platform_off", 0.65)
