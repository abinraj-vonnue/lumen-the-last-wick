extends Node3D

@export var stage_index: int = 0
@export var stage_title: String = "First Light"
@export var stage_hint: String = "Jump onto the amber paths while your lantern reaches them."
@export_range(0.1, 20.0, 0.1) var camera_follow_speed: float = 5.0
@export_range(0.0, 1.0, 0.01) var background_camera_follow: float = 0.88
@export_range(0.0, 1.0, 0.01) var bottom_grass_camera_follow: float = 1.0

var _player: CharacterBody3D
var _camera: Camera3D
var _camera_anchor_y: float
var _camera_depth: float
var _camera_initial_x: float
var _background_layer: Node3D
var _bottom_grass_layer: Node3D
var _background_start_x: float
var _bottom_grass_start_x: float
var _completion_started: bool = false
var _pause_menu_open: bool = false


func _ready() -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("set_stage_mood"):
		audio.call("set_stage_mood", stage_index, false)

	_player = get_node_or_null("Gameplay/Wick3D") as CharacterBody3D
	if _player == null:
		push_error("LevelController3D requires a Wick3D child.")
		return
	_player.set_respawn_position(_player.global_position)
	_player.died.connect(_on_player_died)

	var exit_node := get_node_or_null("Gameplay/LevelExit") as Area3D
	if exit_node != null and exit_node.has_signal("completed"):
		exit_node.completed.connect(_on_level_completed)

	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera != null:
		_camera_anchor_y = _camera.global_position.y
		_camera_depth = _camera.global_position.z
		_camera_initial_x = _camera.global_position.x
		_camera.make_current()
	_background_layer = get_node_or_null("BackgroundLayer") as Node3D
	_bottom_grass_layer = get_node_or_null("BottomGrassLayer") as Node3D
	if _background_layer != null:
		_background_start_x = _background_layer.position.x
	if _bottom_grass_layer != null:
		_bottom_grass_start_x = _bottom_grass_layer.position.x



func _process(delta: float) -> void:
	if _camera == null or _player == null:
		return
	var camera_position := _camera.global_position
	camera_position.x = lerpf(camera_position.x, _player.global_position.x, minf(delta * camera_follow_speed, 1.0))
	camera_position.y = _camera_anchor_y
	camera_position.z = _camera_depth
	_camera.global_position = camera_position
	_camera.look_at(Vector3(camera_position.x, _camera_anchor_y, 0.0), Vector3.UP)
	var camera_shift := camera_position.x - _camera_initial_x
	if _background_layer != null:
		_background_layer.position.x = _background_start_x + camera_shift * background_camera_follow
	if _bottom_grass_layer != null:
		_bottom_grass_layer.position.x = _bottom_grass_start_x + camera_shift * bottom_grass_camera_follow


func uses_game_flow() -> bool:
	return true


func _on_player_died(player: CharacterBody3D) -> void:
	await player.respawn_at()


func _on_level_completed() -> void:
	if _completion_started:
		return
	_completion_started = true
	if _player != null:
		_player.complete()
	if stage_index >= 0:
		GameFlow.complete_stage(stage_index)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or stage_index < 0:
		return
	if _pause_menu_open or get_tree().paused:
		return
	get_viewport().set_input_as_handled()
	var pause_menu: Node = load("res://scenes/ui/pause_menu.tscn").instantiate()
	pause_menu.name = "PauseMenu"
	pause_menu.tree_exited.connect(_on_pause_menu_closed, CONNECT_ONE_SHOT)
	_pause_menu_open = true
	get_tree().current_scene.add_child(pause_menu)
	get_tree().paused = true


func _on_pause_menu_closed() -> void:
	_pause_menu_open = false
