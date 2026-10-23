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
		return
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

	# Releasing jump early produces a shorter jump.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.45

	move_and_slide()


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
	_set_light_flare(true)
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
	respawned.emit(self)


func complete() -> void:
	_is_complete = true
	velocity = Vector2.ZERO


func is_dying() -> bool:
	return _is_dying


# Temporary placeholder character; not the final art.
func _draw() -> void:
	if _is_dashing:
		draw_line(
			-_dash_direction * 28.0,
			-_dash_direction * 8.0,
			Color(1.0, 0.82, 0.5, 0.75),
			4.0,
			true
		)
	draw_circle(Vector2(0, 5), 9.0, Color(1.0, 0.88, 0.62))

	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-6, 1),
			Vector2(0, -15),
			Vector2(6, 1)
		]),
		Color(1.0, 0.65, 0.28)
	)

	draw_circle(
		Vector2(-3.0 + _facing * 2.0, 5),
		1.5,
		Color(0.12, 0.10, 0.16)
	)
	draw_circle(
		Vector2(3.0 + _facing * 2.0, 5),
		1.5,
		Color(0.12, 0.10, 0.16)
	)
