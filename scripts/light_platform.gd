
extends StaticBody2D

const PLATFORM_ART := preload("res://assets/platforms/terrain_short.png")
const STONE_FACE_ART := preload("res://assets/platforms/stone_face_overlay.png")

@export var light_source_path: NodePath
@export var required_light_distance: float = 300.0
@export var deactivation_distance: float = 330.0
@export var fade_speed: float = 5.0

@export var inactive_color: Color = Color("#7774B8")
@export var active_color: Color = Color("#D6C8FF")

@onready var visual: Node2D = $Visual
@onready var platform_collision: CollisionShape2D = $CollisionShape2D

var _is_active: bool = false
var _light_source: Node2D
var _ray_query: PhysicsRayQueryParameters2D


func _ready() -> void:
	_is_active = false
	visual.visible = true
	visual.modulate = Color(inactive_color, 0.18)
	_build_platform_art()
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


func _build_platform_art() -> void:
	var platform_art := Sprite2D.new()
	platform_art.name = "PlatformArtwork"
	platform_art.texture = PLATFORM_ART
	platform_art.scale = Vector2(180.0 / PLATFORM_ART.get_width(), 180.0 / PLATFORM_ART.get_width())
	platform_art.position.y = -10.0 - (22.0 - PLATFORM_ART.get_height() * 0.5) * platform_art.scale.y
	visual.add_child(platform_art)

	var stone_face := Sprite2D.new()
	stone_face.name = "StoneFace"
	stone_face.texture = STONE_FACE_ART
	stone_face.centered = false
	stone_face.position = Vector2(-90.0, -9.0)
	stone_face.scale = Vector2(180.0 / STONE_FACE_ART.get_width(), 0.06)
	visual.add_child(stone_face)


func _physics_process(delta: float) -> void:
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
	var target_alpha := 1.0 if _is_active else 0.18

	visual.modulate = visual.modulate.lerp(
		Color(target_color, target_alpha),
		minf(fade_speed * delta, 1.0)
	)


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
