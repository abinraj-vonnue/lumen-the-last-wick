extends CharacterBody2D

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

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _facing: float = 1.0


func _ready() -> void:
	_setup_input()

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0

	queue_redraw()


func _physics_process(delta: float) -> void:
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


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)

		for keycode in keys:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)


# Temporary placeholder character; not the final art.
func _draw() -> void:
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
