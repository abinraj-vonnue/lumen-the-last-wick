extends Control

const MenuLayout = preload("res://scripts/ui/menu_layout.gd")


func _ready() -> void:
	var menu := MenuLayout.create(self, "Lumen: The Last Wick", "A light-puzzle platformer")
	MenuLayout.add_button(menu, "New Game", GameFlow.start_new_game)
	MenuLayout.add_button(menu, "Quit", _quit_game)


func _quit_game() -> void:
	get_tree().quit()
