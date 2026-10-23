extends SceneTree

const DASH_SCENE := "res://scenes/levels/dash_traversal.tscn"
const GATE_CASES := [
	{"scene": "res://scenes/levels/flare_puzzles.tscn", "gate_x": 1040.0, "stage_index": 3, "next": "res://scenes/ui/hub.tscn"},
	{"scene": "res://scenes/levels/finale.tscn", "gate_x": 1170.0, "stage_index": 4, "next": "res://scenes/ui/ending_screen.tscn"},
]


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var no_dash_level := load(DASH_SCENE).instantiate() as Node2D
	root.add_child(no_dash_level)
	var player := no_dash_level.get_node("World/Wick") as CharacterBody2D
	await _settle_at(player, Vector2(345.0, 560.0))
	Input.action_press("move_right")
	Input.action_press("jump")
	await create_timer(0.8).timeout
	Input.action_release("move_right")
	Input.action_release("jump")
	var no_dash_position := player.global_position
	if no_dash_position.x >= 571.0 and no_dash_position.y < 650.0:
		_fail("the dash stage gap should not be safely crossable without dashing")
		return
	no_dash_level.queue_free()
	await process_frame

	var dash_level := load(DASH_SCENE).instantiate() as Node2D
	root.add_child(dash_level)
	player = dash_level.get_node("World/Wick") as CharacterBody2D
	await _settle_at(player, Vector2(345.0, 560.0))
	Input.action_press("move_right")
	Input.action_press("jump")
	await create_timer(0.2).timeout
	Input.action_press("dash")
	await create_timer(player.dash_duration + 0.35).timeout
	Input.action_release("dash")
	Input.action_release("jump")
	Input.action_release("move_right")
	if player.global_position.x < 571.0 or player.global_position.y > 650.0:
		_fail("jump plus dash should land across the dash stage gap; Wick ended at %s" % player.global_position)
		return
	dash_level.queue_free()
	await process_frame

	for gate_case in GATE_CASES:
		if not await _check_gate_case(gate_case):
			return
	print("PASS: the dash stage requires and rewards a dash; flare puzzle and finale gates block jump/dash bypass and open from a clear flare")
	quit()


func _check_gate_case(gate_case: Dictionary) -> bool:
	if current_scene != null:
		current_scene.free()
	var level := load(gate_case["scene"]).instantiate() as Node2D
	root.add_child(level)
	current_scene = level
	var flow: Node = root.get_node("GameFlow")
	flow.set("current_stage", int(gate_case["stage_index"]))
	flow.set("unlocked_stage", int(gate_case["stage_index"]))
	flow.set("_transitioning", false)
	var player := level.get_node("World/Wick") as CharacterBody2D
	var gate := level.find_child("FlareGate", true, false) as StaticBody2D
	var switch_node := level.find_child("FlareSwitch", true, false)
	await _settle_at(player, Vector2(float(gate_case["gate_x"]) - 90.0, 560.0))
	Input.action_press("move_right")
	Input.action_press("jump")
	await create_timer(0.14).timeout
	Input.action_release("jump")
	Input.action_press("move_up")
	Input.action_press("dash")
	await create_timer(player.dash_duration + 0.45).timeout
	Input.action_release("move_up")
	Input.action_release("dash")
	Input.action_release("move_right")
	if gate.get("_opened") or player.global_position.x >= float(gate_case["gate_x"]) + 20.0:
		_fail("the closed gate in %s should block a jump and dash" % gate_case["scene"])
		level.queue_free()
		return false

	await _settle_at(player, Vector2(float(gate_case["gate_x"]) - 90.0, 560.0))
	Input.action_press("flare")
	await create_timer(0.08).timeout
	Input.action_release("flare")
	await create_timer(0.08).timeout
	if not gate.get("_opened") or bool(switch_node.get("_activated")) == false:
		_fail("a clear flare should activate the switch and open the gate in %s" % gate_case["scene"])
		level.queue_free()
		return false
	Input.action_press("move_right")
	await create_timer(0.65).timeout
	Input.action_release("move_right")
	if player.global_position.x <= float(gate_case["gate_x"]) + 25.0:
		_fail("Wick should pass through the opened gate in %s; opened=%s position=%s" % [gate_case["scene"], gate.get("_opened"), player.global_position])
		level.queue_free()
		return false
	Input.action_press("move_right")
	await create_timer(1.6).timeout
	Input.action_release("move_right")
	if current_scene == level or current_scene.scene_file_path != gate_case["next"]:
		_fail("the opened gate should leave a reachable exit in %s" % gate_case["scene"])
		return false
	return true


func _settle_at(player: CharacterBody2D, position: Vector2) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("jump")
	Input.action_release("dash")
	Input.action_release("flare")
	player.global_position = position
	player.velocity = Vector2.ZERO
	await create_timer(0.15).timeout


func _fail(message: String) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	Input.action_release("jump")
	Input.action_release("dash")
	Input.action_release("flare")
	push_error("FAIL: " + message)
	quit(1)
