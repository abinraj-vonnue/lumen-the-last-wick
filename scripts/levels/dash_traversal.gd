extends "res://scripts/levels/playable_level.gd"


func _ready() -> void:
	stage_index = 2
	stage_title = "Across the Dark"
	stage_hint = "Build a jump, then dash over the wide break."
	super._ready()


func _build_stage() -> void:
	_add_ground(0.0, 350.0)
	_add_ground(580.0, 1500.0)
	_add_checkpoint(Vector2(820.0, 578.0))
	_add_light_platform(Vector2(1030.0, 520.0))
	_add_hazard(Vector2(1190.0, 602.0), Vector2(120.0, 26.0))
	_add_exit(Vector2(1415.0, 584.0))
