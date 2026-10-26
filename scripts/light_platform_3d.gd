extends AnimatableBody3D

@export var light_source_path: NodePath
@export var art_texture: Texture2D
@export var art_region: Rect2 = Rect2(0.0, 0.0, 0.0, 0.0)
@export_range(0.0, 1.0, 0.01) var art_surface_ratio: float = 0.0
@export_range(0.3, 1.0, 0.01) var art_vertical_scale: float = 1.0
@export_range(1.2, 4.0, 0.1) var platform_width: float = 1.8
@export_range(0.1, 0.6, 0.02) var platform_thickness: float = 0.22
@export var required_light_distance: float = 3.0
@export var deactivation_distance: float = 3.3
@export var fade_speed: float = 5.0
@export_range(0.0, 0.4, 0.01) var rise_height: float = 0.12
@export_range(0.1, 2.0, 0.1) var rise_speed: float = 0.65

@onready var _platform_collision: CollisionShape3D = $CollisionShape3D
@onready var _platform_sprite: Sprite3D = $Visual
@onready var _shadow_sprite: Sprite3D = $Shadow

var _is_active: bool = false
var _light_source: OmniLight3D
var _light_owner: CollisionObject3D
var _ray_query: PhysicsRayQueryParameters3D
var _base_position: Vector3
var _rise_offset: float = 0.0
var _inactive_color := Color(0.76, 0.80, 0.90, 1.0)
var _active_color := Color(1.0, 0.91, 0.68, 1.0)


func _ready() -> void:
	_base_position = position
	sync_to_physics = true
	_sync_dimensions_and_art()
	_platform_collision.set_deferred("disabled", true)
	_light_source = get_node_or_null(light_source_path) as OmniLight3D
	if _light_source == null:
		push_warning("LightPlatform3D has no valid light_source_path: %s" % light_source_path)
		return
	_light_owner = _find_light_owner(_light_source)
	var excluded: Array[RID] = [get_rid()]
	if _light_owner != null:
		excluded.append(_light_owner.get_rid())
	_ray_query = PhysicsRayQueryParameters3D.create(global_position, global_position)
	_ray_query.exclude = excluded
	_ray_query.collide_with_bodies = true
	_ray_query.collide_with_areas = false
	_platform_sprite.modulate = _inactive_color
	_create_soft_shadow()


func _physics_process(delta: float) -> void:
	if _light_source == null or not is_instance_valid(_light_source) or _ray_query == null:
		return
	var distance := _light_source.global_position.distance_to(_closest_platform_point())
	var flare_bonus := 0.0
	if _light_source.has_method("get_platform_range_bonus"):
		flare_bonus = _light_source.call("get_platform_range_bonus")
	var limit := deactivation_distance if _is_active else required_light_distance
	var should_activate := distance <= limit + flare_bonus
	if should_activate:
		should_activate = _has_clear_line_of_sight()
	_set_active(should_activate)

	var target_offset := rise_height if _is_active else 0.0
	_rise_offset = move_toward(_rise_offset, target_offset, rise_speed * delta)
	position = _base_position + Vector3(0.0, _rise_offset, 0.0)
	var target_color := _active_color if _is_active else _inactive_color
	_platform_sprite.modulate = _platform_sprite.modulate.lerp(target_color, minf(fade_speed * delta, 1.0))


func _sync_dimensions_and_art() -> void:
	var box := _platform_collision.shape as BoxShape3D
	if box == null:
		box = BoxShape3D.new()
		_platform_collision.shape = box
	box.size = Vector3(platform_width, platform_thickness, 0.72)
	if art_texture == null:
		art_texture = _platform_sprite.texture
	if art_texture != null:
		_platform_sprite.texture = art_texture
		_platform_sprite.region_enabled = art_region.size.x > 0.0 and art_region.size.y > 0.0
		if _platform_sprite.region_enabled:
			_platform_sprite.region_rect = art_region
		var art_size := art_region.size if _platform_sprite.region_enabled else Vector2(art_texture.get_width(), art_texture.get_height())
		_platform_sprite.pixel_size = 0.01
		var uniform_scale := platform_width / (art_size.x * _platform_sprite.pixel_size)
		_platform_sprite.scale = Vector3(uniform_scale, uniform_scale * art_vertical_scale, 1.0)
		var art_height := art_size.y * _platform_sprite.pixel_size * uniform_scale * art_vertical_scale
		var surface_ratio := art_surface_ratio if art_surface_ratio > 0.0 else 0.0
		var surface_offset := (0.5 - surface_ratio) * art_height
		_platform_sprite.position = Vector3(0.0, platform_thickness * 0.5 - surface_offset, -0.04)
	for index in range(3):
		var grass := get_node_or_null("Grass%d" % index) as Node3D
		if grass == null:
			continue
		var sprite := grass.get_node_or_null("Sprite3D") as Sprite3D
		if sprite == null:
			continue
		var region_height: float = sprite.region_rect.size.y if sprite.region_enabled else float(sprite.texture.get_height())
		var grass_height: float = region_height * sprite.pixel_size * sprite.scale.y
		grass.position = Vector3((float(index) - 1.0) * platform_width * 0.30, platform_thickness * 0.5 + grass_height * 0.5, 0.04)


func _create_soft_shadow() -> void:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(128):
			var dx := (float(x) - 63.5) / 63.5
			var dy := (float(y) - 63.5) / 63.5
			var radius := sqrt(dx * dx + dy * dy * 1.7)
			var alpha := pow(maxf(1.0 - radius, 0.0), 2.4) * 0.56
			image.set_pixel(x, y, Color(0.018, 0.026, 0.065, alpha))
	_shadow_sprite.texture = ImageTexture.create_from_image(image)
	_shadow_sprite.pixel_size = 0.01
	_shadow_sprite.scale = Vector3(platform_width * 1.12 / 1.28, 0.42 / 1.28, 1.0)
	_shadow_sprite.position = Vector3(0.0, -0.42, -0.12)
	_shadow_sprite.modulate = Color(0.82, 0.88, 1.0, 0.82)


func _find_light_owner(light: Node) -> CollisionObject3D:
	var current := light.get_parent()
	while current != null:
		if current is CollisionObject3D:
			return current as CollisionObject3D
		current = current.get_parent()
	return null


func _closest_platform_point() -> Vector3:
	var box := _platform_collision.shape as BoxShape3D
	if box == null:
		return global_position
	var half_size := box.size * 0.5
	var local_point := _platform_collision.to_local(_light_source.global_position)
	local_point.x = clampf(local_point.x, -half_size.x, half_size.x)
	local_point.y = clampf(local_point.y, -half_size.y, half_size.y)
	local_point.z = clampf(local_point.z, -half_size.z, half_size.z)
	return _platform_collision.to_global(local_point)


func _has_clear_line_of_sight() -> bool:
	var world := get_world_3d()
	if world == null:
		return false
	_ray_query.from = _light_source.global_position
	_ray_query.to = _closest_platform_point()
	return world.direct_space_state.intersect_ray(_ray_query).is_empty()


func _set_active(active: bool) -> void:
	if _is_active == active:
		return
	_is_active = active
	_platform_collision.set_deferred("disabled", not active)
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "platform_on" if active else "platform_off", 0.65)
