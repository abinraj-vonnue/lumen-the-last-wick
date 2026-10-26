extends CharacterBody2D

signal died(player: CharacterBody2D)
signal respawned(player: CharacterBody2D)
signal flare_started(origin: Vector2)

const IDLE_SPRITE_SCALE := Vector2(0.35, 0.35)
const IDLE_SPRITE_X := 0.0
const IDLE_SPRITE_Y := -46.05
const DEFAULT_SPRITE_X := -1.0
const RUN_SPRITE_SCALE := Vector2(0.388, 0.388)
const RUN_SPRITE_Y := -45.15
const JUMP_SPRITE_SCALE := Vector2(0.35, 0.35)
const JUMP_SPRITE_Y := -45.15
const DASH_SPRITE_SCALE := Vector2(0.403, 0.403)
const DASH_SPRITE_Y := -52.5

# Character appearance is provided by the AnimatedSprite2D in wick.tscn.

@export_group("Movement")
@export var move_speed: float = 260.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0

@export_group("Jump")
@export var gravity: float = 1600.0
@export var jump_velocity: float = -680.0
@export var fall_gravity_multiplier: float = 1.35
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12

@export_group("Fall")
@export var fall_death_distance: float = 240.0

@export_group("Dash")
@export var dash_speed: float = 680.0
@export var dash_duration: float = 0.24
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
var _camera_anchor_y: float
var _saved_collision_layer: int
var _saved_collision_mask: int
var _respawn_protection_timer: float = 0.0
var _step_timer: float = 0.0
var _was_on_floor: bool = false
var _was_airborne: bool = false
var _dash_trail_points: Array[Vector2] = []
var _flare_wave_progress: float = 1.0

@onready var _wick_sprite: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group("player")
	_respawn_position = global_position
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	_setup_input()
	_wick_sprite.play("idle")

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		# Keep jumps from panning the view vertically. This keeps the foreground
		# terrain aligned with its world-space collision and avoids exposing its edge.
		_camera_anchor_y = global_position.y
		camera.top_level = true
		camera.global_position = global_position
		camera.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0

	queue_redraw()


func _process(_delta: float) -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera and camera.top_level:
		camera.global_position = Vector2(global_position.x, _camera_anchor_y)


func _physics_process(delta: float) -> void:
	if _is_dying or _is_complete:
		queue_redraw()
		return
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
		if _check_fall_death():
			queue_redraw()
			return
		_wick_sprite.scale = DASH_SPRITE_SCALE
		_wick_sprite.position.x = DEFAULT_SPRITE_X
		_wick_sprite.position.y = DASH_SPRITE_Y
		_wick_sprite.flip_h = _facing < 0.0
		if _wick_sprite.animation != &"dash":
			var dash_frames := _wick_sprite.sprite_frames
			dash_frames.set_animation_speed(&"dash", dash_frames.get_frame_count(&"dash") / maxf(dash_duration, 0.01))
			_wick_sprite.play(&"dash")
		if not is_on_floor():
			_was_airborne = true
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
		velocity.y *= 0.55

	move_and_slide()
	if _check_fall_death():
		queue_redraw()
		return

	var on_floor_now := is_on_floor()
	_update_locomotion_animation(on_floor_now)
	if on_floor_now and not _was_on_floor:
		_play_audio("land")
	_was_on_floor = on_floor_now

	if on_floor_now and absf(velocity.x) > 22.0:
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.28
			_play_audio("step", 0.7)
	else:
		_step_timer = 0.08
	if not _dash_trail_points.is_empty():
		_dash_trail_points.pop_back()
	queue_redraw()


func _update_locomotion_animation(on_floor_now: bool) -> void:
	_wick_sprite.flip_h = _facing < 0.0
	if _is_dashing:
		return
	if not on_floor_now:
		_was_airborne = true
		_wick_sprite.scale = JUMP_SPRITE_SCALE
		_wick_sprite.position.x = DEFAULT_SPRITE_X
		_wick_sprite.position.y = JUMP_SPRITE_Y
		var air_animation: StringName = &"jump" if velocity.y < 0.0 else &"fall"
		if _wick_sprite.animation != air_animation:
			_wick_sprite.play(air_animation)
		return
	if _was_airborne:
		_was_airborne = false
		_wick_sprite.play("land")
		return
	if _wick_sprite.animation == &"land" and _wick_sprite.is_playing():
		return
	var target_animation: StringName = &"run" if absf(velocity.x) > 1.0 else &"idle"
	var target_scale := RUN_SPRITE_SCALE if target_animation == &"run" else IDLE_SPRITE_SCALE
	var target_x := DEFAULT_SPRITE_X if target_animation == &"run" else IDLE_SPRITE_X * _facing
	var target_y := RUN_SPRITE_Y if target_animation == &"run" else IDLE_SPRITE_Y
	if _wick_sprite.scale != target_scale:
		_wick_sprite.scale = target_scale
	if not is_equal_approx(_wick_sprite.position.x, target_x):
		_wick_sprite.position.x = target_x
	if not is_equal_approx(_wick_sprite.position.y, target_y):
		_wick_sprite.position.y = target_y
	if _wick_sprite.animation != target_animation:
		_wick_sprite.play(target_animation)
	elif target_animation in [&"idle", &"run"] and not _wick_sprite.is_playing():
		_wick_sprite.play(target_animation)


func _check_fall_death() -> bool:
	if is_on_floor() or global_position.y < _respawn_position.y + fall_death_distance:
		return false
	request_death()
	return true


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


func set_respawn_position(respawn_location: Vector2) -> void:
	_respawn_position = respawn_location


func _try_dash() -> void:
	if not _dash_available or _dash_cooldown_timer > 0.0 or _is_dashing:
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.is_zero_approx():
		direction = Vector2(_facing, 0.0)
	_dash_direction = direction.normalized()
	if absf(_dash_direction.x) > 0.01:
		_facing = signf(_dash_direction.x)
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
	_was_airborne = false
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
	# Flare expanding solar resonance rings.
	if _flare_timer > 0.0 or _flare_wave_progress < 1.0:
		var wave_t := clampf(_flare_wave_progress, 0.0, 1.0)
		var outer_r := lerpf(18.0, 155.0, 1.0 - pow(1.0 - wave_t, 2.2))
		var inner_r := lerpf(12.0, 95.0, wave_t)
		var alpha := (1.0 - wave_t) * 0.55
		draw_arc(Vector2(0, -2), outer_r, 0.0, TAU, 48, Color(1.0, 0.84, 0.44, alpha), 3.0, true)
		draw_arc(Vector2(0, -2), inner_r, 0.0, TAU, 36, Color(1.0, 0.95, 0.75, alpha * 0.8), 1.8, true)

	# Dash luminous afterimage trail.
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

	# Soft warm ground pool beneath Wick.
	draw_circle(Vector2(0, 12), 7.5, Color(1.0, 0.78, 0.38, 0.16))
