extends Node
## Session progression and scene transitions for the playable game.

const HUB_SCENE := "res://scenes/ui/hub.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const ENDING_SCENE := "res://scenes/ui/ending_screen.tscn"
const LEVEL_SCENES: Array[String] = [
	"res://scenes/levels/light_traversal.tscn",
	"res://scenes/levels/hazards_checkpoints.tscn",
	"res://scenes/levels/dash_traversal.tscn",
	"res://scenes/levels/flare_puzzles.tscn",
	"res://scenes/levels/finale.tscn",
]
const LEVEL_TITLES: Array[String] = [
	"First Light",
	"A Safe Place",
	"Across the Dark",
	"Borrowed Flame",
	"The Last Wick",
]

var unlocked_stage: int = 0
var current_stage: int = -1
var _transitioning: bool = false


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)


func start_new_game() -> void:
	get_tree().paused = false
	unlocked_stage = 0
	current_stage = -1
	_transitioning = false
	_change_scene(HUB_SCENE)


func return_to_title() -> void:
	get_tree().paused = false
	current_stage = -1
	_transitioning = false
	_change_scene(TITLE_SCENE)


func enter_stage(stage_index: int) -> void:
	if _transitioning or stage_index < 0 or stage_index >= LEVEL_SCENES.size():
		return
	if stage_index > unlocked_stage:
		return
	get_tree().paused = false
	current_stage = stage_index
	_transitioning = true
	_change_scene(LEVEL_SCENES[stage_index])


func restart_stage() -> void:
	if current_stage < 0 or current_stage >= LEVEL_SCENES.size():
		return
	get_tree().paused = false
	_transitioning = true
	_change_scene(LEVEL_SCENES[current_stage])


func complete_stage(stage_index: int) -> void:
	if _transitioning or stage_index != current_stage:
		return
	_transitioning = true
	get_tree().paused = false
	if stage_index == LEVEL_SCENES.size() - 1:
		current_stage = -1
		_change_scene(ENDING_SCENE)
		return
	unlocked_stage = maxi(unlocked_stage, stage_index + 1)
	current_stage = -1
	_change_scene(HUB_SCENE)


func _change_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_transitioning = false
		push_error("Could not open scene %s (error %d)." % [scene_path, error])


func _on_scene_changed() -> void:
	_transitioning = false
