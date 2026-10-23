extends Control

const MenuLayout = preload("res://scripts/ui/menu_layout.gd")


func _ready() -> void:
	var menu := MenuLayout.create(self, "The Last Wick", "The final flame catches. For one quiet moment, the dark remembers the dawn.")
	MenuLayout.add_button(menu, "Return to Title", GameFlow.return_to_title)
	MenuLayout.add_button(menu, "Begin Again", GameFlow.start_new_game)
