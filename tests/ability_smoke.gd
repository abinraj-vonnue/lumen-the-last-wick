extends SceneTree

const LEVEL_PATH := "res://scenes/levels/test_level.tscn"


func _initialize() -> void:
	call_deferred("run_checks")


func run_checks() -> void:
	var level: Node = load(LEVEL_PATH).instantiate() as Node
	root.add_child(level)
	await create_timer(0.1).timeout
	var player: CharacterBody2D = level.get_node("World/Wick") as CharacterBody2D
	var platform: StaticBody2D = level.get_node("World/FlarePlatform") as StaticBody2D
	var light: PointLight2D = player.get_node("WickLight") as PointLight2D

	if not InputMap.has_action("dash") or not InputMap.has_action("flare"):
		_fail("dash and flare inputs must be configured")
		return

	# Base activation and deactivation have distinct limits (300 and 330 px).
	player.set_physics_process(false)
	await _place_player(player, Vector2(215, 340))
	if not platform._is_active:
		_fail("platform should activate inside its 300 px base radius")
		return
	await _place_player(player, Vector2(195, 340))
	if not platform._is_active:
		_fail("active platform should remain solid inside its 330 px deactivation radius")
		return
	await _place_player(player, Vector2(165, 340))
	if platform._is_active:
		_fail("platform should deactivate outside its 330 px base radius")
		return

	# Flare raises those limits to 480 and 510 px and then restores them.
	await _place_player(player, Vector2(130, 340))
	player.set_physics_process(true)
	Input.action_press("flare")
	await create_timer(0.04).timeout
	Input.action_release("flare")
	await create_timer(0.06).timeout
	if not player.is_flare_active() or not platform._is_active or light.texture_scale <= 3.0:
		_fail("flare should brighten the lantern and extend platform activation range")
		return
	player.set_physics_process(false)
	await _place_player(player, Vector2(20, 340))
	if not platform._is_active:
		_fail("flared platform should remain active inside its 510 px deactivation radius")
		return
	await _place_player(player, Vector2(-10, 340))
	if platform._is_active:
		_fail("flared platform should deactivate outside its 510 px deactivation radius")
		return
	await _place_player(player, Vector2(25, 340))
	if platform._is_active:
		_fail("inactive platform should stay off outside its 480 px activation radius")
		return
	await _place_player(player, Vector2(35, 340))
	if not platform._is_active:
		_fail("flare should activate a platform inside its 480 px activation radius")
		return
	player.set_physics_process(true)
	await create_timer(player.flare_duration + 0.1).timeout
	if player.is_flare_active() or platform._is_active:
		_fail("flare range and visuals should end with the flare duration")
		return
	Input.action_press("flare")
	await create_timer(0.04).timeout
	Input.action_release("flare")
	await create_timer(0.04).timeout
	if player.is_flare_active():
		_fail("flare cooldown should prevent immediate reactivation")
		return

	# Horizontal dash stops at a wall and leaves ordinary movement available.
	var world: Node = level.get_node("World")
	var wall := _make_block(Vector2(280, 535), Vector2(24, 100))
	world.add_child(wall)
	await _place_player(player, Vector2(200, 565))
	Input.action_press("move_right")
	Input.action_press("dash")
	await create_timer(0.04).timeout
	Input.action_release("move_right")
	Input.action_release("dash")
	if not player.is_dashing() or player._dash_direction.x < 0.9:
		_fail("horizontal dash should follow the held direction")
		return
	await create_timer(0.15).timeout
	if player.is_dashing() or player.global_position.x > 270.0:
		_fail("horizontal dash should stop at the wall")
		return
	wall.queue_free()
	await create_timer(0.5).timeout
	var before_move := player.global_position.x
	Input.action_press("move_right")
	await create_timer(0.1).timeout
	Input.action_release("move_right")
	if player.global_position.x <= before_move:
		_fail("normal movement should recover after a blocked dash")
		return

	# A ceiling contact must not cancel a horizontal dash moving along it.
	var ceiling := _make_block(Vector2(300, 540), Vector2(200, 20))
	world.add_child(ceiling)
	await _place_player(player, Vector2(300, 565))
	await create_timer(0.5).timeout
	Input.action_press("move_right")
	Input.action_press("dash")
	await create_timer(0.08).timeout
	Input.action_release("move_right")
	Input.action_release("dash")
	if not player.is_dashing():
		_fail("horizontal dash should continue when touching a ceiling tangentially")
		return
	await create_timer(player.dash_duration + 0.06).timeout
	if player.is_dashing():
		_fail("horizontal dash should end cleanly when its timer expires")
		return
	ceiling.queue_free()

	# Upward, downward and diagonal dashes must stop when moving into a surface.
	await create_timer(0.5).timeout
	var overhead := _make_block(Vector2(300, 430), Vector2(200, 20))
	world.add_child(overhead)
	await _place_player(player, Vector2(300, 500))
	Input.action_press("move_up")
	Input.action_press("dash")
	await create_timer(0.14).timeout
	Input.action_release("move_up")
	Input.action_release("dash")
	if player.is_dashing():
		_fail("upward dash should stop at the ceiling")
		return
	overhead.queue_free()

	await create_timer(0.5).timeout
	await _place_player(player, Vector2(200, 470))
	Input.action_press("move_down")
	Input.action_press("dash")
	await create_timer(0.17).timeout
	Input.action_release("move_down")
	Input.action_release("dash")
	if player.is_dashing():
		_fail("downward dash should stop at the floor")
		return

	await create_timer(0.5).timeout
	var diagonal_wall := _make_block(Vector2(350, 500), Vector2(20, 120))
	world.add_child(diagonal_wall)
	await _place_player(player, Vector2(300, 500))
	Input.action_press("move_right")
	Input.action_press("move_up")
	Input.action_press("dash")
	await create_timer(0.14).timeout
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("dash")
	if player.is_dashing() or player.global_position.x > 340.0:
		_fail("diagonal dash should stop when it hits a wall")
		return
	diagonal_wall.queue_free()

	# Dash cooldown, vertical aim, and death/respawn reset.
	await create_timer(0.5).timeout
	await _place_player(player, Vector2(200, 400))
	Input.action_press("move_up")
	Input.action_press("dash")
	await create_timer(0.04).timeout
	Input.action_release("move_up")
	Input.action_release("dash")
	if not player.is_dashing() or player.velocity.y >= 0.0:
		_fail("I should aim an upward dash without using the jump key")
		return
	if player.can_dash():
		_fail("dash cooldown should prevent an immediate second dash")
		return
	await create_timer(player.dash_duration + 0.08).timeout
	if player.is_dashing():
		_fail("dash should end after its configured duration")
		return
	player.request_death()
	await create_timer(0.5).timeout
	if player.is_dying() or not player.can_dash() or player.is_flare_active():
		_fail("death and respawn should reset temporary ability states")
		return

	# The closed gate cannot be jumped/dashed over; its one-shot switch needs a clear flare.
	var gate: StaticBody2D = level.get_node("World/FlareGate") as StaticBody2D
	var flare_switch: Node = level.get_node("World/FlareSwitch")
	var activations := [0]
	flare_switch.activated.connect(func() -> void: activations[0] += 1)
	await _place_player(player, Vector2(840, 565))
	Input.action_press("jump")
	await create_timer(0.16).timeout
	Input.action_release("jump")
	Input.action_press("move_right")
	Input.action_press("move_up")
	Input.action_press("dash")
	await create_timer(0.2).timeout
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("dash")
	if player.global_position.x >= 885.0 or gate._opened:
		_fail("closed gate should block a jump and diagonal dash toward the exit")
		return

	player.request_death()
	await create_timer(0.5).timeout
	await _place_player(player, Vector2(790, 545))
	await create_timer(0.08).timeout
	var blocker := _make_block(Vector2(810, 520), Vector2(16, 40))
	world.add_child(blocker)
	await create_timer(0.02).timeout
	Input.action_press("flare")
	await create_timer(0.04).timeout
	Input.action_release("flare")
	await create_timer(0.08).timeout
	if gate._opened or activations[0] != 0:
		_fail("obstruction should keep the one-shot flare switch inactive")
		return
	await create_timer(player._flare_cooldown_timer + 0.05).timeout
	blocker.queue_free()
	await create_timer(0.02).timeout
	Input.action_press("flare")
	await create_timer(0.04).timeout
	Input.action_release("flare")
	await create_timer(0.08).timeout
	if not gate._opened or activations[0] != 1:
		_fail("clear flare should permanently activate the switch and open the gate once")
		return
	await create_timer(player.flare_duration + 0.1).timeout
	await create_timer(player._flare_cooldown_timer + 0.05).timeout
	Input.action_press("flare")
	await create_timer(0.04).timeout
	Input.action_release("flare")
	await create_timer(0.08).timeout
	if not gate._opened or activations[0] != 1:
		_fail("one-shot switch should remain activated and emit only once")
		return

	print("PASS: dash direction, surface collisions, recovery, cooldown, and respawn; flare hysteresis, cooldown, switch LOS/latch, gate blocking and opening")
	quit()


func _place_player(player: CharacterBody2D, position: Vector2) -> void:
	player.global_position = position
	player.velocity = Vector2.ZERO
	await create_timer(0.06).timeout


func _make_block(position: Vector2, size: Vector2) -> StaticBody2D:
	var block := StaticBody2D.new()
	block.position = position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	block.add_child(shape)
	return block


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
