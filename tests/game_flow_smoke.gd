extends SceneTree

const EXPECTED_MAIN_SCENE := "res://scenes/ui/title_screen.tscn"
const REQUIRED_SCENES := [
	"res://scenes/ui/title_screen.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/hub.tscn",
	"res://scenes/ui/ending_screen.tscn",
	"res://scenes/levels/light_traversal.tscn",
	"res://scenes/levels/hazards_checkpoints.tscn",
	"res://scenes/levels/dash_traversal.tscn",
	"res://scenes/levels/flare_puzzles.tscn",
	"res://scenes/levels/finale.tscn",
]


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var config := ConfigFile.new()
	if config.load("res://project.godot") != OK:
		_fail("project.godot should load")
		return
	if config.get_value("application", "run/main_scene", "") != EXPECTED_MAIN_SCENE:
		_fail("the title screen should be the project entry point")
		return
	if config.get_value("autoload", "GameFlow", "") != "*res://scripts/game_flow.gd":
		_fail("GameFlow should be registered as an autoload")
		return
	for scene_path in REQUIRED_SCENES:
		if not ResourceLoader.exists(scene_path):
			_fail("required game-flow scene is missing: %s" % scene_path)
			return
	var flow := root.get_node_or_null("GameFlow")
	if flow == null:
		_fail("GameFlow autoload should be active")
		return
	flow.call("start_new_game")
	await create_timer(0.1).timeout
	if current_scene.scene_file_path != "res://scenes/ui/hub.tscn":
		_fail("New Game should open the hub")
		return
	flow.call("return_to_title")
	await create_timer(0.1).timeout
	var title_buttons := current_scene.find_children("*", "Button", true, false)
	if title_buttons.size() < 2:
		_fail("the title should expose New Game and Quit buttons")
		return
	title_buttons[0].emit_signal("pressed")
	await create_timer(0.1).timeout
	if current_scene.scene_file_path != "res://scenes/ui/hub.tscn":
		_fail("the title New Game button should open the hub")
		return
	var hub_buttons := current_scene.find_children("*", "Button", true, false)
	if hub_buttons.size() < 6:
		_fail("the hub should show five stages and a title option")
		return
	hub_buttons[0].emit_signal("pressed")
	await create_timer(0.1).timeout
	if current_scene.scene_file_path != "res://scenes/levels/light_traversal.tscn":
		_fail("the first hub stage should open the light traversal level")
		return
	var first_level := current_scene
	if first_level.get_node_or_null("World/Wick") == null or first_level.get_node_or_null("LevelController") == null:
		_fail("playable stages should include Wick and the shared level controller")
		return
	var controller: Node = first_level.get_node("LevelController")
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	controller.call("_unhandled_input", pause_event)
	var pause_menu := first_level.get_node_or_null("PauseMenu") as Control
	if pause_menu == null or not paused:
		_fail("the pause action should open a menu and pause gameplay")
		return
	controller.call("_unhandled_input", pause_event)
	var pause_menu_count := 0
	for child in first_level.get_children():
		if child is Control and child.has_method("_resume"):
			pause_menu_count += 1
	if pause_menu_count != 1:
		_fail("repeated pause input should not create duplicate menus")
		return
	if pause_menu.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail("the pause menu should process while gameplay is paused")
		return
	pause_menu.call("_unhandled_input", pause_event)
	await process_frame
	if paused:
		_fail("the pause action should resume gameplay from the pause menu")
		return
	controller.call("_unhandled_input", pause_event)
	await process_frame
	pause_menu = first_level.get_node_or_null("PauseMenu") as Control
	var pause_buttons := pause_menu.find_children("*", "Button", true, false)
	pause_buttons[2].emit_signal("pressed")
	await create_timer(0.1).timeout
	if current_scene.scene_file_path != "res://scenes/ui/title_screen.tscn" or paused:
		_fail("Return to Title from pause should unpause and open the title screen")
		return
	title_buttons = current_scene.find_children("*", "Button", true, false)
	title_buttons[0].emit_signal("pressed")
	await create_timer(0.1).timeout
	hub_buttons = current_scene.find_children("*", "Button", true, false)
	hub_buttons[0].emit_signal("pressed")
	await create_timer(0.1).timeout
	first_level = current_scene
	var first_exit: Area2D = first_level.find_child("LevelExit", true, false) as Area2D
	first_exit.call("_on_body_entered", first_level.get_node("World/Wick"))
	await create_timer(0.1).timeout
	if current_scene.scene_file_path != "res://scenes/ui/hub.tscn" or int(flow.get("unlocked_stage")) != 1:
		_fail("completing a stage should unlock the next stage and return to the hub")
		return
	flow.call("enter_stage", 4)
	await create_timer(0.05).timeout
	if current_scene.scene_file_path != "res://scenes/ui/hub.tscn":
		_fail("locked stages should not be enterable")
		return
	for stage_index in range(1, 5):
		var stage_buttons := current_scene.find_children("*", "Button", true, false)
		stage_buttons[stage_index].emit_signal("pressed")
		await create_timer(0.1).timeout
		if current_scene.scene_file_path != flow.get("LEVEL_SCENES")[stage_index]:
			_fail("unlocked stage %d should load its own scene" % (stage_index + 1))
			return
		if current_scene.get_node_or_null("World/Wick") == null:
			_fail("stage %d should instantiate Wick" % (stage_index + 1))
			return
		if stage_index == 1:
			var checkpoints := get_nodes_in_group("checkpoint")
			if checkpoints.is_empty():
				_fail("the danger stage should include a checkpoint")
				return
			checkpoints[0].call("_on_body_entered", current_scene.get_node("World/Wick"))
			if not bool(checkpoints[0].get("_activated")):
				_fail("touching the checkpoint should activate it")
				return
			var unlocked_before_restart := int(flow.get("unlocked_stage"))
			flow.call("restart_stage")
			await create_timer(0.1).timeout
			if current_scene.scene_file_path != flow.get("LEVEL_SCENES")[stage_index]:
				_fail("restarting should reload the current level without changing progression")
				return
			if int(flow.get("unlocked_stage")) != unlocked_before_restart:
				_fail("restarting a level should not advance progression")
				return
			var fresh_checkpoints := get_nodes_in_group("checkpoint")
			if fresh_checkpoints.is_empty() or bool(fresh_checkpoints[0].get("_activated")):
				_fail("restarting should reset level-local checkpoint state")
				return
		var exit_node: Area2D = current_scene.find_child("LevelExit", true, false) as Area2D
		exit_node.call("_on_body_entered", current_scene.get_node("World/Wick"))
		await create_timer(0.1).timeout
		if stage_index < 4 and current_scene.scene_file_path != "res://scenes/ui/hub.tscn":
			_fail("non-final stages should return to the hub")
			return
	if current_scene.scene_file_path != "res://scenes/ui/ending_screen.tscn":
		_fail("the final stage should lead to the ending screen")
		return
	flow.call("return_to_title")
	await create_timer(0.1).timeout
	flow.call("start_new_game")
	await create_timer(0.1).timeout
	if current_scene.scene_file_path != "res://scenes/ui/hub.tscn" or int(flow.get("unlocked_stage")) != 0:
		_fail("starting a new game should reset progression to the first stage")
		return
	print("PASS: title entry, new game reset, hub unlocks, all five stage loads/completions, locked-stage guard, and ending flow")
	current_scene.free()
	quit()


func _fail(message: String) -> void:
	push_error("FAIL: " + message)
	quit(1)
