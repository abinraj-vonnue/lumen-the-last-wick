extends Control

const MenuLayout = preload("res://scripts/ui/menu_layout.gd")


func _ready() -> void:
	var menu := MenuLayout.create(self, "The Last Candle", "Choose a lit path. New places appear as you restore the light.")
	for index in GameFlow.LEVEL_TITLES.size():
		var stage_index := index
		var title: String = GameFlow.LEVEL_TITLES[index]
		var is_open: bool = stage_index <= GameFlow.unlocked_stage
		var label := "%d  ·  %s" % [stage_index + 1, title]
		if not is_open:
			label += "  ·  Sealed"
		MenuLayout.add_button(menu, label, func() -> void: GameFlow.enter_stage(stage_index), not is_open)
	MenuLayout.add_button(menu, "Return to Title", GameFlow.return_to_title)
