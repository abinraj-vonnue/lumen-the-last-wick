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
@export var stage_hint: String = "Move, jump, and follow the light."

var _world: Node2D
var _spawn_position := Vector2(150.0, 560.0)


func _ready() -> void:
	_build_backdrop()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)
	var wick := WICK_SCENE.instantiate() as CharacterBody2D
	wick.name = "Wick"
	wick.position = _spawn_position
	_world.add_child(wick)
	_build_stage()
	_add_level_controller()
	_add_hud()


func _build_stage() -> void:
	pass


func uses_game_flow() -> bool:
	return true


func _build_backdrop() -> void:
	var backdrop := Polygon2D.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("#101429")
	backdrop.polygon = PackedVector2Array([
		Vector2(-3000, -1500), Vector2(5000, -1500),
		Vector2(5000, 2200), Vector2(-3000, 2200),
	])
	backdrop.z_index = -100
	add_child(backdrop)
	var darkness := CanvasModulate.new()
	darkness.color = Color("#69708f")
	add_child(darkness)


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
	var visual := Polygon2D.new()
	visual.color = Color("#34394f")
	visual.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -40), Vector2(width * 0.5, -40),
		Vector2(width * 0.5, 40), Vector2(-width * 0.5, 40),
	])
	body.add_child(visual)
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
