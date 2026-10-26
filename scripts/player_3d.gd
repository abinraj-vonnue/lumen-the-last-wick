extends CharacterBody3D

signal died(player: CharacterBody3D)
signal respawned(player: CharacterBody3D)
signal flare_started(origin: Vector3)

const WICK_2D_SCENE := preload("res://scenes/player/wick.tscn")

@export_group("Movement")
@export var move_speed: float = 2.6
@export var acceleration: float = 18.0
@export var friction: float = 22.0

@export_group("Jump")
@export var gravity: float = 16.0
@export var jump_velocity: float = 6.8
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12

@export_group("Flare")
@export var flare_duration: float = 0.55
@export var flare_cooldown: float = 2.5

@export_group("Fall")
@export var fall_death_distance: float = 2.4

@onready var _wick_sprite: AnimatedSprite3D = $Visual
@onready var _wick_light: OmniLight3D = $WickLight
@onready var _ground_shadow: Sprite3D = $GroundShadow

var _respawn_position: Vector3
var _saved_collision_layer: int
var _saved_collision_mask: int
var _facing: float = 1.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _flare_timer: float = 0.0
var _flare_cooldown_timer: float = 0.0
var _is_dying: bool = false
var _is_complete: bool = false
var _was_airborne: bool = false


func _ready() -> void:
	add_to_group("player")
	_respawn_position = global_position
	_saved_collision_layer = collision_layer
	_saved_collision_mask = collision_mask
	_setup_input()
	_load_wick_sprite_frames()
	_create_ground_shadow()
	_wick_sprite.play(&"idle")


func _load_wick_sprite_frames() -> void:
	# Reuse the existing sprite animations without altering the 2D Wick scene.
	var wick_2d := WICK_2D_SCENE.instantiate()
	var source_sprite := wick_2d.get_node("Visual") as AnimatedSprite2D
	_wick_sprite.sprite_frames = source_sprite.sprite_frames
	wick_2d.free()


func _physics_process(delta: float) -> void:
	if _is_dying or _is_complete:
		return

	_flare_cooldown_timer = maxf(_flare_cooldown_timer - delta, 0.0)
	if _flare_timer > 0.0:
		_flare_timer = maxf(_flare_timer - delta, 0.0)
		if _flare_timer == 0.0:
			_wick_light.set_flare_active(false)

	if Input.is_action_just_pressed("flare"):
		_try_flare()

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	var input_x := Input.get_axis("move_left", "move_right")
	if input_x != 0.0:
		_facing = signf(input_x)
		velocity.x = move_toward(velocity.x, input_x * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_play_audio("jump")
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.55

	# This is a 3D body, but First Light remains a side-scroller.
	velocity.z = 0.0
	move_and_slide()
	_update_ground_shadow()
	if _check_fall_death():
		return
	_update_animation()


func _update_animation() -> void:
	_wick_sprite.flip_h = _facing < 0.0
	if not is_on_floor():
		_was_airborne = true
		var air_animation: StringName = &"jump" if velocity.y > 0.0 else &"fall"
		if _wick_sprite.animation != air_animation:
			_wick_sprite.play(air_animation)
		return
	if _was_airborne:
		_was_airborne = false
		_wick_sprite.play(&"land")
		return
	var target_animation: StringName = &"run" if absf(velocity.x) > 0.1 else &"idle"
	if _wick_sprite.animation != target_animation:
		_wick_sprite.play(target_animation)


func _create_ground_shadow() -> void:
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	for y in range(96):
		for x in range(96):
			var dx := (float(x) - 47.5) / 47.5
			var dy := (float(y) - 47.5) / 47.5
			var radius := sqrt(dx * dx + dy * dy * 1.8)
			var alpha := pow(maxf(1.0 - radius, 0.0), 2.8) * 0.55
			image.set_pixel(x, y, Color(0.012, 0.018, 0.04, alpha))
	_ground_shadow.texture = ImageTexture.create_from_image(image)
	_ground_shadow.pixel_size = 0.01
	_ground_shadow.shaded = false
	_ground_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _update_ground_shadow() -> void:
	var world := get_world_3d()
	if world == null:
		_ground_shadow.visible = false
		return
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0.0, 0.05, 0.0),
		global_position + Vector3(0.0, -4.0, 0.0)
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_ground_shadow.visible = false
		return
	_ground_shadow.visible = true
	var ground_position: Vector3 = hit.position
	_ground_shadow.global_position = Vector3(global_position.x, ground_position.y + 0.015, global_position.z - 0.06)
	var height := maxf(global_position.y - ground_position.y, 0.0)
	var fade := clampf(1.0 - height / 3.3, 0.12, 1.0)
	_ground_shadow.scale = Vector3(0.62 * lerpf(1.0, 0.45, 1.0 - fade), 0.22 * lerpf(1.0, 0.6, 1.0 - fade), 1.0)
	_ground_shadow.modulate = Color(1.0, 1.0, 1.0, fade)


func _try_flare() -> void:
	if _flare_cooldown_timer > 0.0 or _flare_timer > 0.0:
		return
	_flare_timer = flare_duration
	_flare_cooldown_timer = flare_cooldown
	_wick_light.set_flare_active(true)
	flare_started.emit(_wick_light.global_position)
	_play_audio("flare")


func _check_fall_death() -> bool:
	if is_on_floor() or global_position.y >= _respawn_position.y - fall_death_distance:
		return false
	request_death()
	return true


func request_death() -> void:
	if _is_dying or _is_complete:
		return
	_is_dying = true
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	visible = false
	_wick_light.set_flare_active(false)
	_play_audio("death")
	died.emit(self)


func respawn_at() -> void:
	if not _is_dying:
		return
	await get_tree().create_timer(0.35).timeout
	global_position = _respawn_position
	velocity = Vector3.ZERO
	_flare_timer = 0.0
	_flare_cooldown_timer = 0.0
	_wick_light.set_flare_active(false)
	collision_layer = _saved_collision_layer
	collision_mask = _saved_collision_mask
	visible = true
	_is_dying = false
	_play_audio("respawn")
	respawned.emit(self)


func set_respawn_position(respawn_location: Vector3) -> void:
	_respawn_position = respawn_location


func complete() -> void:
	_is_complete = true
	velocity = Vector3.ZERO


func is_dying() -> bool:
	return _is_dying


func _setup_input() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action("flare", [KEY_E, KEY_F])
	_add_key_action("pause", [KEY_ESCAPE])


func _add_key_action(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func _play_audio(event_name: String) -> void:
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", event_name)
