
extends Area2D

var _completed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _completed or not body is CharacterBody2D:
		return

	if body.name != "Wick":
		return

	_completed = true
	_show_completion_message()


func _show_completion_message() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CompletionUI"
	get_tree().current_scene.add_child(layer)

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
	message.text = "LIGHT RESTORED\n\nLevel Complete"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 36)
	message.add_theme_color_override(
		"font_color",
		Color(1.0, 0.84, 0.55)
	)
	center.add_child(message)

	get_tree().paused = true
