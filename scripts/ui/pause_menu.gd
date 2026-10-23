extends Control

const MenuLayout = preload("res://scripts/ui/menu_layout.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var menu := MenuLayout.create(self, "Paused")
	MenuLayout.add_button(menu, "Resume", _resume)
	MenuLayout.add_button(menu, "Restart Level", GameFlow.restart_stage)
	MenuLayout.add_button(menu, "Return to Title", GameFlow.return_to_title)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_resume()


func _resume() -> void:
	get_tree().paused = false
	queue_free()
