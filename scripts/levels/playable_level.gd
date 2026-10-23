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

@export var stage_index: int = 0
@export var stage_title: String = "First Light"
@export var stage_subtitle: String = ""
@export var stage_hint: String = "Move, jump, and follow the light."

var _world: Node2D
var _scenery_back: Node2D
var _scenery_mid: Node2D
var _scenery_fore: Node2D
var _spawn_position := Vector2(150.0, 560.0)


func _ready() -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("set_stage_mood"):
		audio.call("set_stage_mood", stage_index, false)
	_build_backdrop()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	var wick := WICK_SCENE.instantiate() as CharacterBody2D
	wick.name = "Wick"
	wick.position = _spawn_position
	_world.add_child(wick)

	_scenery_back = Node2D.new()
	_scenery_back.name = "SceneryBack"
	_scenery_back.z_index = -25
	_world.add_child(_scenery_back)

	_scenery_mid = Node2D.new()
	_scenery_mid.name = "SceneryMid"
	_scenery_mid.z_index = -8
	_world.add_child(_scenery_mid)

	_build_stage()
	_build_foreground_silhouettes()
	_add_level_controller()
	_add_hud()


func _build_stage() -> void:
	pass


func uses_game_flow() -> bool:
	return true


func _build_backdrop() -> void:
	# Deep sky base
	var backdrop := Polygon2D.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("#0b0e1f")
	backdrop.polygon = PackedVector2Array([
		Vector2(-3000, -1500), Vector2(5000, -1500),
		Vector2(5000, 2200), Vector2(-3000, 2200),
	])
	backdrop.z_index = -100
	add_child(backdrop)

	# Upper twilight indigo band
	var upper_sky := Polygon2D.new()
	upper_sky.name = "UpperSkyBand"
	upper_sky.color = Color(0.08, 0.10, 0.22, 0.65)
	upper_sky.polygon = PackedVector2Array([
		Vector2(-3000, -1500), Vector2(5000, -1500),
		Vector2(5000, 260), Vector2(-3000, 260),
	])
	upper_sky.z_index = -98
	add_child(upper_sky)

	# Horizon violet glow band (warmer in later stages)
	var warmth := float(stage_index) * 0.035
	var horizon_glow := Polygon2D.new()
	horizon_glow.name = "HorizonGlow"
	horizon_glow.color = Color(0.18 + warmth, 0.14 + warmth * 0.6, 0.32, 0.45)
	horizon_glow.polygon = PackedVector2Array([
		Vector2(-3000, 180), Vector2(5000, 180),
		Vector2(5000, 680), Vector2(-3000, 680),
	])
	horizon_glow.z_index = -96
	add_child(horizon_glow)

	# Distant mountain range and ancient citadel silhouettes
	var far_range := Polygon2D.new()
	far_range.name = "FarMountainRange"
	far_range.color = Color("#121730")
	far_range.z_index = -90
	far_range.polygon = PackedVector2Array([
		Vector2(-1200, 900),
		Vector2(-1200, 420), Vector2(-750, 290), Vector2(-380, 390),
		Vector2(-60, 240), Vector2(210, 350), Vector2(490, 210),
		Vector2(780, 330), Vector2(1090, 195), Vector2(1380, 310),
		Vector2(1690, 225), Vector2(2050, 360), Vector2(2400, 280),
		Vector2(2800, 430), Vector2(2800, 900),
	])
	add_child(far_range)

	# Mid-distance sunken aqueduct & spire silhouettes
	var mid_ruins := Polygon2D.new()
	mid_ruins.name = "MidRuinSilhouettes"
	mid_ruins.color = Color("#171d38")
	mid_ruins.z_index = -82
	mid_ruins.polygon = PackedVector2Array([
		Vector2(-800, 900),
		Vector2(-800, 490), Vector2(-420, 470), Vector2(-410, 320),
		Vector2(-370, 310), Vector2(-360, 465), Vector2(-40, 480),
		Vector2(120, 440), Vector2(130, 290), Vector2(165, 275),
		Vector2(175, 440), Vector2(520, 465), Vector2(730, 430),
		Vector2(745, 260), Vector2(785, 250), Vector2(795, 430),
		Vector2(1150, 455), Vector2(1340, 420), Vector2(1355, 230),
		Vector2(1405, 215), Vector2(1420, 420), Vector2(1850, 470),
		Vector2(2200, 490), Vector2(2200, 900),
	])
	add_child(mid_ruins)

	# Atmospheric drifting mist ribbons
	for mist_idx in 3:
		var mist := Polygon2D.new()
		mist.name = "MistRibbon_%d" % mist_idx
		var y_base := 460.0 + float(mist_idx) * 75.0
		mist.color = Color(0.32, 0.38, 0.58, 0.08 + float(mist_idx) * 0.02)
		mist.z_index = -75 + mist_idx * 5
		mist.polygon = PackedVector2Array([
			Vector2(-900, y_base),
			Vector2(-200, y_base - 18.0),
			Vector2(500, y_base + 14.0),
			Vector2(1200, y_base - 12.0),
			Vector2(2100, y_base + 8.0),
			Vector2(2100, y_base + 55.0),
			Vector2(-900, y_base + 55.0),
		])
		add_child(mist)

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


func _build_foreground_silhouettes() -> void:
	_scenery_fore = Node2D.new()
	_scenery_fore.name = "SceneryFore"
	_scenery_fore.z_index = 20
	_world.add_child(_scenery_fore)

	# Lower abyssal foreground silhouettes below the camera floor for depth framing
	for fg_idx in 5:
		var x_pos := -100.0 + float(fg_idx) * 420.0
		var spire := Polygon2D.new()
		spire.color = Color(0.04, 0.05, 0.11, 0.88)
		spire.polygon = PackedVector2Array([
			Vector2(x_pos - 70.0, 760.0),
			Vector2(x_pos - 25.0, 665.0 + float(fg_idx % 2) * 18.0),
			Vector2(x_pos + 15.0, 680.0),
			Vector2(x_pos + 65.0, 760.0),
		])
		_scenery_fore.add_child(spire)


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

	var half_w := width * 0.5
	var segs := maxi(4, int(round(width / 90.0)))
	var step := width / float(segs)

	# Deep cliff under-hang silhouette extending into the abyss (purely decorative)
	var abyss_skirt := Polygon2D.new()
	abyss_skirt.name = "CliffUnderhang"
	abyss_skirt.color = Color("#14182b")
	var skirt_pts := PackedVector2Array()
	skirt_pts.append(Vector2(-half_w, -36.0))
	skirt_pts.append(Vector2(half_w, -36.0))
	for i in range(segs, -1, -1):
		var rx := -half_w + float(i) * step
		var depth := 125.0 + sin(float(i) * 1.9 + from_x * 0.02) * 28.0
		if i == 0 or i == segs:
			depth = 68.0
		skirt_pts.append(Vector2(rx, depth))
	abyss_skirt.polygon = skirt_pts
	body.add_child(abyss_skirt)

	# Main carved rock mass
	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = Color("#282e45")
	var rock_pts := PackedVector2Array()
	for i in range(segs + 1):
		var tx := -half_w + float(i) * step
		var ty := -40.0 + sin(float(i) * 2.1) * 1.5
		if i == 0 or i == segs:
			ty = -40.0
		rock_pts.append(Vector2(tx, ty))
	for i in range(segs, -1, -1):
		var bx := -half_w + float(i) * step
		var by := 46.0 + cos(float(i) * 1.7 + 0.5) * 12.0
		rock_pts.append(Vector2(bx, by))
	visual.polygon = rock_pts
	body.add_child(visual)

	# Upper weathered stone rim and moss overhang
	var rim := Polygon2D.new()
	rim.name = "StoneRim"
	rim.color = Color("#465173")
	var rim_pts := PackedVector2Array()
	for i in range(segs + 1):
		var tx := -half_w + float(i) * step
		rim_pts.append(Vector2(tx, -40.0))
	for i in range(segs, -1, -1):
		var bx := -half_w + float(i) * step
		var lip := -29.0 + sin(float(i) * 2.7 + from_x * 0.01) * 4.0
		rim_pts.append(Vector2(bx, lip))
	rim.polygon = rim_pts
	body.add_child(rim)

	# Warm top edge highlight line to catch lantern light
	var top_gleam := Polygon2D.new()
	top_gleam.name = "TopGleam"
	top_gleam.color = Color("#6c7aa6")
	top_gleam.polygon = PackedVector2Array([
		Vector2(-half_w + 4.0, -40.0),
		Vector2(half_w - 4.0, -40.0),
		Vector2(half_w - 8.0, -36.5),
		Vector2(-half_w + 8.0, -36.5),
	])
	body.add_child(top_gleam)

	_world.add_child(body)


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
