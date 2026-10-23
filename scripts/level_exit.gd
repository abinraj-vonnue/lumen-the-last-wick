
extends Area2D

signal completed

var _completed: bool = false


func _ready() -> void:
	add_to_group("level_exit")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _completed or not body.is_in_group("player"):
		return
	if body.has_method("is_dying") and body.call("is_dying"):
		return
	_completed = true
	if body.has_method("complete"):
		body.call("complete")
	completed.emit()
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
