
extends Area2D

signal completed

var _completed: bool = false
var _time: float = 0.0
var _portal_veil: Polygon2D
var _inner_beacon: Polygon2D


func _ready() -> void:
	add_to_group("level_exit")
	body_entered.connect(_on_body_entered)
	_build_sanctuary_arch()


func _process(delta: float) -> void:
	_time += delta
	if _portal_veil != null:
		_portal_veil.color.a = 0.38 + sin(_time * 3.0) * 0.10
	if _inner_beacon != null:
		_inner_beacon.scale = Vector2(1.0 + sin(_time * 4.5) * 0.08, 1.0 + cos(_time * 3.6) * 0.08)


func _build_sanctuary_arch() -> void:
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		# Sculpted stone archway frame
		visual.color = Color(0.32, 0.36, 0.52, 1.0)
		visual.polygon = PackedVector2Array([
			Vector2(-28, 36), Vector2(-26, -24), Vector2(-18, -38),
			Vector2(0, -44), Vector2(18, -38), Vector2(26, -24),
			Vector2(28, 36), Vector2(18, 36), Vector2(17, -20),
			Vector2(10, -31), Vector2(0, -35), Vector2(-10, -31),
			Vector2(-17, -20), Vector2(-18, 36),
		])

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_portal_veil = Polygon2D.new()
	_portal_veil.name = "PortalVeil"
	_portal_veil.color = Color(0.95, 0.78, 0.42, 0.42)
	_portal_veil.material = add_mat
	_portal_veil.z_index = -1
	_portal_veil.polygon = PackedVector2Array([
		Vector2(-17, 36), Vector2(-16, -20), Vector2(-10, -31),
		Vector2(0, -35), Vector2(10, -31), Vector2(16, -20), Vector2(17, 36),
	])
	add_child(_portal_veil)

	_inner_beacon = Polygon2D.new()
	_inner_beacon.name = "InnerBeacon"
	_inner_beacon.position = Vector2(0, -4)
	_inner_beacon.color = Color(1.0, 0.92, 0.68, 0.85)
	_inner_beacon.material = add_mat
	_inner_beacon.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(9, 0), Vector2(0, 18), Vector2(-9, 0),
	])
	add_child(_inner_beacon)

	var motes := CPUParticles2D.new()
	motes.name = "ArchwayMotes"
	motes.position = Vector2(0, 20)
	motes.amount = 16
	motes.lifetime = 1.6
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(14, 10)
	motes.direction = Vector2(0, -1)
	motes.spread = 20.0
	motes.gravity = Vector2(0, -18)
	motes.initial_velocity_min = 6.0
	motes.initial_velocity_max = 16.0
	motes.scale_amount_min = 1.5
	motes.scale_amount_max = 3.2
	motes.color = Color(1.0, 0.86, 0.52, 0.75)
	add_child(motes)


func _on_body_entered(body: Node2D) -> void:
	if _completed or not body.is_in_group("player"):
		return
	if body.has_method("is_dying") and body.call("is_dying"):
		return
	var level := get_tree().current_scene
	var is_flow_level: bool = level != null and level.has_method("uses_game_flow") and level.call("uses_game_flow")
	_completed = true
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "complete")
	if body.has_method("complete"):
		body.call("complete")
	completed.emit()
	if not is_flow_level:
		_show_completion_message()


func _show_completion_message() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CompletionUI"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var ui_parent: Node = get_tree().current_scene
	if ui_parent == null:
		ui_parent = get_parent()
	ui_parent.add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.025, 0.09, 0.88)
	backdrop.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	backdrop.add_child(center)

	var message := Label.new()
	message.text = "LIGHT RESTORED\n\nLevel Complete\n\nPress R to restart"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 36)
	message.add_theme_color_override(
		"font_color",
		Color(1.0, 0.84, 0.55)
	)
	center.add_child(message)

	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if _completed and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()
