extends CharacterBody2D

signal died(player: CharacterBody2D)
signal respawned(player: CharacterBody2D)
signal flare_started(origin: Vector2)

# Temporary movement prototype.
# The placeholder appearance will be replaced with illustrated art later.

@export_group("Movement")
@export var move_speed: float = 260.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0

@export_group("Jump")
@export var gravity: float = 1600.0
@export var jump_velocity: float = -600.0
@export var fall_gravity_multiplier: float = 1.35
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12

@export_group("Dash")
@export var dash_speed: float = 620.0
@export var dash_duration: float = 0.22
@export var dash_cooldown: float = 0.45

@export_group("Flare")
@export var flare_duration: float = 0.55
@export var flare_cooldown: float = 2.5

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _facing: float = 1.0
var _dash_direction: Vector2 = Vector2.RIGHT
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _flare_timer: float = 0.0
var _flare_cooldown_timer: float = 0.0
var _dash_available: bool = true
var _is_dashing: bool = false
var _is_dying: bool = false
var _is_complete: bool = false
var _respawn_position: Vector2
var _saved_collision_layer: int
var _saved_collision_mask: int
var _respawn_protection_timer: float = 0.0
var _anim_time: float = 0.0
var _run_cycle: float = 0.0
var _step_timer: float = 0.0
var _was_on_floor: bool = false
var _dash_trail_points: Array[Vector2] = []
var _flare_wave_progress: float = 1.0


func _ready() -> void:
	add_to_group("player")
	_respawn_position = global_position
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	_setup_input()

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0

	queue_redraw()


func _physics_process(delta: float) -> void:
	if _is_dying or _is_complete:
		queue_redraw()
		return
	_anim_time += delta
	if _flare_wave_progress < 1.0:
		_flare_wave_progress = minf(_flare_wave_progress + delta / maxf(flare_duration, 0.01), 1.0)
	_respawn_protection_timer = maxf(_respawn_protection_timer - delta, 0.0)
	_dash_cooldown_timer = maxf(_dash_cooldown_timer - delta, 0.0)
	_flare_cooldown_timer = maxf(_flare_cooldown_timer - delta, 0.0)
	if _flare_timer > 0.0:
		_flare_timer = maxf(_flare_timer - delta, 0.0)
		if _flare_timer == 0.0:
			_set_light_flare(false)
	if is_on_floor() and not _is_dashing:
		_dash_available = true

	if Input.is_action_just_pressed("flare"):
		_try_flare()
	if Input.is_action_just_pressed("dash"):
		_try_dash()
	if _is_dashing:
		_process_dash(delta)
		_dash_trail_points.push_front(global_position)
		if _dash_trail_points.size() > 7:
			_dash_trail_points.pop_back()
		queue_redraw()
		return

	_update_jump_timers(delta)

	var input_x := Input.get_axis("move_left", "move_right")

	if input_x != 0.0:
		_facing = signf(input_x)
		velocity.x = move_toward(
			velocity.x,
			input_x * move_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)

	if not is_on_floor():
		var current_gravity := gravity
		if velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier
		velocity.y += current_gravity * delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_play_audio("jump")

	# Releasing jump early produces a shorter jump.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	move_and_slide()

	var on_floor_now := is_on_floor()
	if on_floor_now and not _was_on_floor:
		_play_audio("land")
	_was_on_floor = on_floor_now

	if on_floor_now and absf(velocity.x) > 22.0:
		_run_cycle += delta * (absf(velocity.x) / move_speed) * 11.5
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.28
			_play_audio("step", 0.7)
	else:
		_step_timer = 0.08
	if not _dash_trail_points.is_empty():
		_dash_trail_points.pop_back()
	queue_redraw()


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time


func _setup_input() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	# W and Up remain jump-only; I/K aim vertical dashes without changing jump behavior.
	_add_key_action("move_up", [KEY_I])
	_add_key_action("move_down", [KEY_K])
	_add_key_action("dash", [KEY_SHIFT, KEY_X])
	_add_key_action("flare", [KEY_E, KEY_F])
	_add_key_action("restart", [KEY_R])
	_add_key_action("pause", [KEY_ESCAPE])


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

		for keycode in keys:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)


func set_respawn_position(position: Vector2) -> void:
	_respawn_position = position


func _try_dash() -> void:
	if not _dash_available or _dash_cooldown_timer > 0.0 or _is_dashing:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		direction = Vector2(_facing, 0.0)
	_dash_direction = direction.normalized()
	_dash_available = false
	_dash_cooldown_timer = dash_cooldown
	_dash_timer = dash_duration
	_is_dashing = true
	velocity = _dash_direction * dash_speed
	_dash_trail_points.clear()
	_dash_trail_points.push_front(global_position)
	_play_audio("dash")


func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = _dash_direction * dash_speed
	move_and_slide()
	var blocked_in_dash_direction := false
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		if _dash_direction.dot(collision.get_normal()) < -0.01:
			blocked_in_dash_direction = true
			break
	if blocked_in_dash_direction or _dash_timer <= 0.0:
		_end_dash(blocked_in_dash_direction)


func _end_dash(collided: bool) -> void:
	_is_dashing = false
	_dash_timer = 0.0
	if collided:
		velocity = Vector2.ZERO
	else:
		velocity = _dash_direction * move_speed * 0.65
	queue_redraw()


func _try_flare() -> void:
	if _flare_cooldown_timer > 0.0 or _flare_timer > 0.0:
		return
	_flare_timer = flare_duration
	_flare_cooldown_timer = flare_cooldown
	_flare_wave_progress = 0.0
	_set_light_flare(true)
	_play_audio("flare")
	var light := get_node_or_null("WickLight") as Node2D
	flare_started.emit(light.global_position if light != null else global_position)


func _set_light_flare(active: bool) -> void:
	var light := get_node_or_null("WickLight")
	if light != null and light.has_method("set_flare_active"):
		light.call("set_flare_active", active)


func is_dashing() -> bool:
	return _is_dashing


func can_dash() -> bool:
	return _dash_available and _dash_cooldown_timer <= 0.0 and not _is_dying and not _is_complete


func is_flare_active() -> bool:
	return _flare_timer > 0.0


func refill_dash() -> void:
	_dash_available = true
	_dash_cooldown_timer = 0.0


func _reset_abilities() -> void:
	_is_dashing = false
	_dash_timer = 0.0
	_dash_cooldown_timer = 0.0
	_dash_available = true
	_flare_timer = 0.0
	_flare_cooldown_timer = 0.0
	_set_light_flare(false)


func request_death() -> void:
	if _is_dying or _is_complete or _respawn_protection_timer > 0.0:
		return
	_is_dying = true
	_reset_abilities()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	visible = false
	_play_audio("death")
	died.emit(self)


func respawn_at() -> void:
	if not _is_dying:
		return
	await get_tree().create_timer(0.35).timeout
	global_position = _respawn_position
	velocity = Vector2.ZERO
	_reset_abilities()
	_respawn_protection_timer = 0.25
	collision_layer = _saved_collision_layer
	collision_mask = _saved_collision_mask
	visible = true
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_is_dying = false
	_play_audio("respawn")
	respawned.emit(self)


func complete() -> void:
	_is_complete = true
	velocity = Vector2.ZERO


func is_dying() -> bool:
	return _is_dying


func _play_audio(event_name: String, volume_scale: float = 1.0) -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", event_name, volume_scale)


func _draw() -> void:
	var speed_ratio := clampf(absf(velocity.x) / maxf(move_speed, 1.0), 0.0, 1.0)
	var is_airborne := not is_on_floor()
	var breathe := sin(_anim_time * 3.4) * 1.1
	var stride := sin(_run_cycle) * speed_ratio
	var bob := absf(cos(_run_cycle)) * 2.2 * speed_ratio if not is_airborne else 0.0
	var tilt := _facing * speed_ratio * 2.5
	if is_airborne:
		tilt = _facing * clampf(-velocity.y * 0.005, -2.5, 3.0)

	# 1. Flare expanding solar resonance rings
	if _flare_timer > 0.0 or _flare_wave_progress < 1.0:
		var wave_t := clampf(_flare_wave_progress, 0.0, 1.0)
		var outer_r := lerpf(18.0, 155.0, 1.0 - pow(1.0 - wave_t, 2.2))
		var inner_r := lerpf(12.0, 95.0, wave_t)
		var alpha := (1.0 - wave_t) * 0.55
		draw_arc(Vector2(0, -2), outer_r, 0.0, TAU, 48, Color(1.0, 0.84, 0.44, alpha), 3.0, true)
		draw_arc(Vector2(0, -2), inner_r, 0.0, TAU, 36, Color(1.0, 0.95, 0.75, alpha * 0.8), 1.8, true)

	# 2. Dash luminous afterimage trail
	if _dash_trail_points.size() > 1:
		for idx in range(1, _dash_trail_points.size()):
			var local_pt := to_local(_dash_trail_points[idx])
			var trail_alpha := (1.0 - float(idx) / float(_dash_trail_points.size())) * 0.45
			draw_circle(local_pt + Vector2(0, 2), 8.0 - float(idx) * 0.8, Color(1.0, 0.78, 0.38, trail_alpha))
	if _is_dashing:
		draw_line(
			-_dash_direction * 34.0,
			-_dash_direction * 6.0,
			Color(1.0, 0.86, 0.52, 0.82),
			5.0,
			true
		)

	# 3. Soft warm ground pool / shadow beneath Wick
	draw_circle(Vector2(0, 12), 7.5, Color(1.0, 0.78, 0.38, 0.16))

	# 4. Striding feet silhouettes
	var left_foot := Vector2(-3.5 + stride * 4.5, 13.0 - maxf(0.0, stride) * 2.5)
	var right_foot := Vector2(3.5 - stride * 4.5, 13.0 - maxf(0.0, -stride) * 2.5)
	if is_airborne:
		left_foot = Vector2(-3.5, 12.0 + clampf(velocity.y * 0.004, -2.0, 2.5))
		right_foot = Vector2(3.0, 13.5 + clampf(velocity.y * 0.004, -2.0, 2.5))
	draw_circle(left_foot, 2.4, Color("#1c2038"))
	draw_circle(right_foot, 2.4, Color("#1c2038"))

	# 5. Fluttering twilight scarf tail trailing behind Wick
	var scarf_wave := sin(_anim_time * 7.5 - speed_ratio * 2.0) * (2.5 + speed_ratio * 3.5)
	var scarf_lift := clampf(velocity.y * 0.015, -6.0, 8.0) if is_airborne else 0.0
	var scarf_poly := PackedVector2Array([
		Vector2(-_facing * 2.0, -2.0 - bob),
		Vector2(-_facing * (11.0 + speed_ratio * 6.0), -1.0 + scarf_wave * 0.5 + scarf_lift),
		Vector2(-_facing * (16.0 + speed_ratio * 8.0), 3.5 + scarf_wave + scarf_lift),
		Vector2(-_facing * 8.0, 5.0 - bob),
	])
	draw_colored_polygon(scarf_poly, Color("#b86b35"))

	# 6. Layered traveler cloak silhouette (midnight indigo outer + warm rim)
	var cloak_billow := 2.0 + speed_ratio * 2.5 + (2.5 if (is_airborne and velocity.y > 0.0) else 0.0)
	var cloak_outer := PackedVector2Array([
		Vector2(tilt * 0.4, -10.0 - bob + breathe * 0.4),
		Vector2(7.5 + cloak_billow * 0.4, -1.0 - bob),
		Vector2(9.5 + cloak_billow, 10.5 - bob * 0.5),
		Vector2(3.0, 12.0 - bob * 0.3),
		Vector2(-2.5, 11.0 - bob * 0.3),
		Vector2(-9.5 - cloak_billow, 10.5 - bob * 0.5),
		Vector2(-7.5 - cloak_billow * 0.4, -1.0 - bob),
	])
	draw_colored_polygon(cloak_outer, Color("#252c4a"))

	var cloak_inner := PackedVector2Array([
		Vector2(tilt * 0.4, -9.0 - bob + breathe * 0.4),
		Vector2(5.5, 0.0 - bob),
		Vector2(6.5, 9.5 - bob * 0.4),
		Vector2(0.0, 10.8 - bob * 0.3),
		Vector2(-6.5, 9.5 - bob * 0.4),
		Vector2(-5.5, 0.0 - bob),
	])
	draw_colored_polygon(cloak_inner, Color("#3a456e"))

	# 7. Head & pointed lantern-keeper hood with living flame crest
	var head_center := Vector2(tilt * 0.35, -3.5 - bob + breathe * 0.5)
	draw_circle(head_center, 6.8, Color("#181b2e"))

	var hood_tip := Vector2(
		head_center.x - _facing * (2.5 + speed_ratio * 2.5) + sin(_anim_time * 5.0) * 0.8,
		head_center.y - 12.5 + breathe * 0.6
	)
	draw_colored_polygon(
		PackedVector2Array([
			head_center + Vector2(-6.5, -1.5),
			hood_tip,
			head_center + Vector2(6.5, -1.5),
		]),
		Color("#343f66")
	)

	# Warm golden wick-flame crest atop the hood
	var wick_flicker := sin(_anim_time * 11.0) * 1.2
	var flame_scale := 1.45 if _flare_timer > 0.0 else 1.0
	draw_colored_polygon(
		PackedVector2Array([
			hood_tip + Vector2(-3.2 * flame_scale, 2.0),
			hood_tip + Vector2(wick_flicker, -7.5 * flame_scale),
			hood_tip + Vector2(3.2 * flame_scale, 2.0),
		]),
		Color(1.0, 0.72, 0.28, 0.95)
	)
	draw_circle(hood_tip + Vector2(wick_flicker * 0.4, -2.2), 2.1 * flame_scale, Color(1.0, 0.96, 0.78))

	# 8. Luminous eyes looking in facing direction
	var eye_offset := Vector2(_facing * 2.2, -0.5)
	draw_circle(head_center + eye_offset + Vector2(-1.6, 0.0), 1.35, Color(1.0, 0.94, 0.76))
	draw_circle(head_center + eye_offset + Vector2(1.8, 0.0), 1.35, Color(1.0, 0.94, 0.76))

	# 9. Handheld brass lantern suspended in front of Wick
	var swing_angle := sin(_run_cycle) * 0.25 * speed_ratio + sin(_anim_time * 2.8) * 0.06
	var hand_pos := Vector2(_facing * 7.5 + tilt * 0.3, 1.5 - bob)
	var lantern_pos := hand_pos + Vector2(sin(swing_angle) * 5.0, 5.5)
	draw_line(hand_pos, lantern_pos + Vector2(0, -3.5), Color("#d9a75a"), 1.4, true)
	# Lantern outer warm halo
	var halo_r := 13.5 if _flare_timer <= 0.0 else 22.0
	draw_circle(lantern_pos, halo_r, Color(1.0, 0.80, 0.38, 0.22))
	# Lantern cage & glowing core
	draw_circle(lantern_pos, 3.8, Color("#2b2333"))
	draw_circle(lantern_pos, 2.6, Color(1.0, 0.86, 0.48))
	draw_circle(lantern_pos, 1.4, Color(1.0, 0.98, 0.88))
