extends "res://scripts/levels/playable_level.gd"


func _ready() -> void:
	stage_index = 1
	stage_title = "A Safe Place"
	stage_hint = "Read the spike rhythm and touch each lamp to secure a return point."
	super._ready()


func _build_stage() -> void:
	_add_ground(0.0, 1420.0)
	_add_hazard(Vector2(405.0, 602.0), Vector2(100.0, 26.0))
	_add_checkpoint(Vector2(625.0, 578.0))
	_add_hazard(Vector2(810.0, 602.0), Vector2(150.0, 26.0))
	_add_checkpoint(Vector2(1050.0, 578.0))
	_add_hazard(Vector2(1190.0, 602.0), Vector2(80.0, 26.0))
	_add_exit(Vector2(1345.0, 584.0))
