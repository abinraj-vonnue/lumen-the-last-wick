extends Node2D
## Shared runtime assembly for the five authored challenge layouts.

const WICK_SCENE := preload("res://scenes/player/wick.tscn")
const PLATFORM_SCENE := preload("res://scenes/objects/light_platform.tscn")
const HAZARD_SCENE := preload("res://scenes/objects/hazard.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/objects/checkpoint.tscn")
const EXIT_SCENE := preload("res://scenes/objects/level_exit.tscn")
const SWITCH_SCENE := preload("res://scenes/objects/flare_switch.tscn")
const GATE_SCENE := preload("res://scenes/objects/flare_gate.tscn")
const LEVEL_CONTROLLER_SCRIPT := preload("res://scripts/level_controller.gd")
const FORGOTTEN_KINGDOM_TEXTURE := preload("res://assets/backgrounds/forgotten_kingdom.png")
const LEVEL_ONE_FOREGROUND_TEXTURE := preload("res://forground_layer_source.png")
const STONE_FACE_TEXTURE := preload("res://assets/platforms/stone_face_overlay.png")
const TERRAIN_TEXTURES: Array[Texture2D] = [
	preload("res://assets/platforms/terrain_short.png"),
	preload("res://assets/platforms/terrain_medium.png"),
	preload("res://assets/platforms/terrain_midlong.png"),
	preload("res://assets/platforms/terrain_long.png"),
]

@export var stage_index: int = 0
@export var stage_title: String = "First Light"
@export var stage_subtitle: String = ""
@export var stage_hint: String = "Move, jump, and follow the light."

var _world: Node2D
var _scenery_back: Node2D
var _scenery_mid: Node2D
var _spawn_position := Vector2(150.0, 560.0)


func _ready() -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("set_stage_mood"):
		audio.call("set_stage_mood", stage_index, false)
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	var wick := WICK_SCENE.instantiate() as CharacterBody2D
	wick.name = "Wick"
	wick.position = _spawn_position
	_world.add_child(wick)
	_build_backdrop()

	_scenery_back = Node2D.new()
	_scenery_back.name = "SceneryBack"
	_scenery_back.z_index = -25
	_world.add_child(_scenery_back)

	_scenery_mid = Node2D.new()
	_scenery_mid.name = "SceneryMid"
	_scenery_mid.z_index = -8
	_world.add_child(_scenery_mid)

	_build_stage()
	_build_foreground()
	_add_level_controller()
	_add_hud()


func _build_stage() -> void:
	pass


func uses_game_flow() -> bool:
	return true


func _build_backdrop() -> void:
	# Keep the full-screen artwork aligned to the viewport while the camera moves in the world.
	var kingdom_layer := CanvasLayer.new()
	kingdom_layer.name = "ForgottenKingdomBackground"
	kingdom_layer.layer = -2
	add_child(kingdom_layer)

	var kingdom_artwork := TextureRect.new()
	kingdom_artwork.name = "KingdomArtwork"
	kingdom_artwork.texture = FORGOTTEN_KINGDOM_TEXTURE
	kingdom_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kingdom_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	kingdom_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kingdom_artwork.modulate = Color("#69708f")
	kingdom_artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kingdom_layer.add_child(kingdom_artwork)

	# Ambient floating dust motes across the stage
	var dust := CPUParticles2D.new()
	dust.name = "AmbientMotes"
	dust.position = Vector2(750, 380)
	dust.z_index = -20
	dust.amount = 36
	dust.lifetime = 5.5
	dust.preprocess = 2.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(950, 320)
	dust.direction = Vector2(0.25, -1.0)
	dust.spread = 45.0
	dust.gravity = Vector2(0, -3.5)
	dust.initial_velocity_min = 4.0
	dust.initial_velocity_max = 12.0
	dust.scale_amount_min = 1.2
	dust.scale_amount_max = 2.6
	dust.color = Color(0.95, 0.84, 0.58, 0.28)
	add_child(dust)

	var darkness := CanvasModulate.new()
	darkness.name = "WorldDarkness"
	darkness.color = Color("#69708f")
	add_child(darkness)


func _build_foreground() -> void:
	# The authored frame is intentionally limited to First Light so its dark
	# foliage adds depth without cluttering the later, more demanding stages.
	if stage_index != 0:
		return

	var foreground_artwork := Sprite2D.new()
	foreground_artwork.name = "ForegroundFrame"
	foreground_artwork.texture = LEVEL_ONE_FOREGROUND_TEXTURE
	# Center the 2172 px frame on the level, and lift its stone lip to the
	# playable floor height. It is world-space artwork so camera motion stays aligned.
	foreground_artwork.position = Vector2(715.0, _spawn_position.y + 5.0)
	foreground_artwork.z_index = 20
	# Cool, low-opacity tint keeps the source's warm lantern highlights from
	# competing with Wick and the light platforms.
	foreground_artwork.modulate = Color(0.48, 0.56, 0.72, 0.68)
	_world.add_child(foreground_artwork)

	# Make only the bottom stone contour solid. The foliage and hanging vines
	# remain decorative and do not trap or block Wick.
	var foreground_ground := StaticBody2D.new()
	foreground_ground.name = "ForegroundSlopeCollision"
	foreground_ground.position = foreground_artwork.position
	foreground_ground.collision_layer = 1
	foreground_ground.collision_mask = 1
	var slope_collision := CollisionPolygon2D.new()
	slope_collision.name = "WalkableStoneContour"
	slope_collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	var image_size := LEVEL_ONE_FOREGROUND_TEXTURE.get_size()
	var walkable_top := PackedVector2Array([
		Vector2(250.0, 475.0),
		Vector2(350.0, 485.0),
		Vector2(470.0, 525.0),
		Vector2(650.0, 535.0),
		Vector2(800.0, 558.0),
		Vector2(1000.0, 590.0),
		Vector2(1200.0, 615.0),
		Vector2(1400.0, 615.0),
		Vector2(1550.0, 590.0),
		Vector2(1700.0, 560.0),
		Vector2(1850.0, 525.0),
		Vector2(1950.0, 480.0),
		Vector2(2070.0, 455.0),
	])
	var slope_polygon := PackedVector2Array()
	for point in walkable_top:
		slope_polygon.append(point - image_size * 0.5)
	slope_polygon.append(Vector2(image_size.x * 0.5, image_size.y * 0.5))
	slope_polygon.append(Vector2(-image_size.x * 0.5, image_size.y * 0.5))
	slope_collision.polygon = slope_polygon
	foreground_ground.add_child(slope_collision)
	_world.add_child(foreground_ground)


func _add_level_controller() -> void:
	var controller := Node2D.new()
	controller.name = "LevelController"
	controller.set_script(LEVEL_CONTROLLER_SCRIPT)
	controller.set("initial_spawn_position", _spawn_position)
	controller.set("stage_index", stage_index)
	add_child(controller)


func _add_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StageHUD"
	layer.layer = 2
	add_child(layer)

	var banner := Polygon2D.new()
	banner.color = Color(0.05, 0.07, 0.15, 0.62)
	banner.polygon = PackedVector2Array([
		Vector2(16, 14), Vector2(620, 14), Vector2(595, 86), Vector2(16, 86),
	])
	layer.add_child(banner)

	var accent_line := Polygon2D.new()
	accent_line.color = Color(0.96, 0.80, 0.48, 0.75)
	accent_line.polygon = PackedVector2Array([
		Vector2(16, 14), Vector2(20, 14), Vector2(20, 86), Vector2(16, 86),
	])
	layer.add_child(accent_line)

	var title := Label.new()
	title.text = "%02d  ·  %s" % [stage_index + 1, stage_title]
	title.position = Vector2(28, 22)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f5d99b"))
	layer.add_child(title)
	var hint := Label.new()
	hint.text = stage_hint + "     Esc  ·  Pause"
	hint.position = Vector2(28, 56)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("#c6cde0"))
	layer.add_child(hint)


func _add_ground(from_x: float, to_x: float, floor_y: float = 620.0) -> void:
	var width := to_x - from_x
	if width <= 0.0:
		return
	var body := StaticBody2D.new()
	body.name = "Ground"
	body.position = Vector2((from_x + to_x) * 0.5, floor_y + 40.0)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 80.0)
	collision.shape = rectangle
	body.add_child(collision)

	# Use the closest source ledge size to keep the illustrated terrain close to
	# its authored proportions. Very wide floors use two mirrored sections.
	var terrain_texture := _closest_terrain_texture(width)
	var section_count := 2 if width >= 1200.0 else 1
	var section_width := width / float(section_count)
	for section_index in range(section_count):
		var stone_face := Sprite2D.new()
		stone_face.name = "StoneFace%d" % section_index
		stone_face.texture = STONE_FACE_TEXTURE
		stone_face.centered = false
		stone_face.position = Vector2(-width * 0.5 + section_width * section_index, -40.0)
		var face_scale := section_width / STONE_FACE_TEXTURE.get_width()
		stone_face.scale = Vector2(face_scale, face_scale * 0.36)
		body.add_child(stone_face)

		var terrain := Sprite2D.new()
		terrain.name = "TerrainArtwork%d" % section_index
		terrain.texture = terrain_texture
		terrain.centered = true
		terrain.flip_h = section_index % 2 == 1
		terrain.scale.x = section_width / terrain_texture.get_width()
		var stone_top := _terrain_stone_top(terrain_texture)
		terrain.position = Vector2(
			-width * 0.5 + section_width * (float(section_index) + 0.5),
			-40.0 - stone_top + terrain_texture.get_height() * 0.5
		)
		body.add_child(terrain)

	_world.add_child(body)


func _closest_terrain_texture(platform_width: float) -> Texture2D:
	var closest := TERRAIN_TEXTURES[0]
	var closest_distortion := INF
	for texture in TERRAIN_TEXTURES:
		var scale_ratio := platform_width / float(texture.get_width())
		var distortion := absf(log(scale_ratio))
		if distortion < closest_distortion:
			closest = texture
			closest_distortion = distortion
	return closest


func _terrain_stone_top(texture: Texture2D) -> float:
	# Distance from each crop's top edge to the flat stone lip.
	match texture.resource_path.get_file():
		"terrain_short.png": return 23.0
		"terrain_medium.png": return 24.0
		"terrain_midlong.png": return 25.0
		_: return 28.0


func _add_block(center: Vector2, size: Vector2, color: Color = Color("#34394f")) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = center
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.color = color
	visual.polygon = PackedVector2Array([
		-size * 0.5, Vector2(size.x * 0.5, -size.y * 0.5),
		size * 0.5, Vector2(-size.x * 0.5, size.y * 0.5),
	])
	body.add_child(visual)
	_world.add_child(body)
	return body


func _add_light_platform(at: Vector2) -> StaticBody2D:
	var platform := PLATFORM_SCENE.instantiate() as StaticBody2D
	platform.position = at
	platform.set("light_source_path", NodePath("../Wick/WickLight"))
	_world.add_child(platform)
	return platform


func _add_hazard(at: Vector2, size: Vector2) -> Area2D:
	var hazard := HAZARD_SCENE.instantiate() as Area2D
	hazard.position = at
	hazard.set("size", size)
	_world.add_child(hazard)
	return hazard


func _add_checkpoint(at: Vector2) -> Area2D:
	var checkpoint := CHECKPOINT_SCENE.instantiate() as Area2D
	checkpoint.position = at
	_world.add_child(checkpoint)
	return checkpoint


func _add_exit(at: Vector2) -> Area2D:
	var exit_node := EXIT_SCENE.instantiate() as Area2D
	exit_node.position = at
	_world.add_child(exit_node)
	return exit_node


func _add_flare_gate(at: Vector2, switch_at: Vector2, flare_distance: float = 400.0) -> StaticBody2D:
	var switch_node := SWITCH_SCENE.instantiate() as Node2D
	switch_node.position = switch_at
	switch_node.set("activation_distance", flare_distance)
	_world.add_child(switch_node)
	var gate := GATE_SCENE.instantiate() as StaticBody2D
	gate.position = at
	_world.add_child(gate)
	switch_node.activated.connect(gate.open)
	return gate


func _add_ruin_pillar(base_pos: Vector2, height: float = 160.0, width: float = 32.0, broken_top: bool = true) -> void:
	if _scenery_mid == null:
		return
	var pillar := Node2D.new()
	pillar.position = base_pos
	var hw := width * 0.5
	var shaft := Polygon2D.new()
	shaft.color = Color("#1e243b")
	if broken_top:
		shaft.polygon = PackedVector2Array([
			Vector2(-hw - 4, 0), Vector2(-hw, -height * 0.85),
			Vector2(-hw * 0.3, -height), Vector2(hw * 0.4, -height * 0.92),
			Vector2(hw, -height * 0.78), Vector2(hw + 4, 0),
		])
	else:
		shaft.polygon = PackedVector2Array([
			Vector2(-hw - 5, 0), Vector2(-hw, -height),
			Vector2(hw, -height), Vector2(hw + 5, 0),
		])
	pillar.add_child(shaft)

	var highlight := Polygon2D.new()
	highlight.color = Color("#2e3759")
	highlight.polygon = PackedVector2Array([
		Vector2(-hw, 0), Vector2(-hw + 5, -height * 0.82),
		Vector2(-hw + 10, -height * 0.82), Vector2(-hw + 6, 0),
	])
	pillar.add_child(highlight)
	_scenery_mid.add_child(pillar)


func _add_broken_arch(center_base: Vector2, span: float = 200.0, height: float = 160.0) -> void:
	if _scenery_back == null:
		return
	var arch := Polygon2D.new()
	arch.position = center_base
	arch.color = Color("#181e34")
	var hs := span * 0.5
	arch.polygon = PackedVector2Array([
		Vector2(-hs - 18, 0), Vector2(-hs - 14, -height * 0.75),
		Vector2(-hs * 0.65, -height), Vector2(0, -height * 1.08),
		Vector2(hs * 0.65, -height), Vector2(hs + 14, -height * 0.75),
		Vector2(hs + 18, 0), Vector2(hs - 8, 0),
		Vector2(hs - 10, -height * 0.65), Vector2(hs * 0.45, -height * 0.86),
		Vector2(0, -height * 0.92), Vector2(-hs * 0.45, -height * 0.86),
		Vector2(-hs + 10, -height * 0.65), Vector2(-hs + 8, 0),
	])
	_scenery_back.add_child(arch)


func _add_distant_monolith(base_pos: Vector2, height: float = 220.0, width: float = 44.0) -> void:
	if _scenery_back == null:
		return
	var mono := Polygon2D.new()
	mono.position = base_pos
	mono.color = Color("#161b30")
	var hw := width * 0.5
	mono.polygon = PackedVector2Array([
		Vector2(-hw, 0), Vector2(-hw * 0.75, -height * 0.88),
		Vector2(0, -height), Vector2(hw * 0.75, -height * 0.88), Vector2(hw, 0),
	])
	_scenery_back.add_child(mono)


func _add_finale_brazier(base_pos: Vector2) -> void:
	if _scenery_mid == null:
		return
	var brazier := Polygon2D.new()
	brazier.position = base_pos
	brazier.color = Color("#2c3452")
	brazier.polygon = PackedVector2Array([
		Vector2(-48, 0), Vector2(-34, -18), Vector2(-56, -42),
		Vector2(56, -42), Vector2(34, -18), Vector2(48, 0),
	])
	_scenery_mid.add_child(brazier)
