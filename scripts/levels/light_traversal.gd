extends "res://scripts/levels/playable_level.gd"


func _ready() -> void:
	stage_index = 0
	stage_title = "First Light"
	stage_subtitle = "The Sunken Causeway — dormant rune-stones wake when touched by lantern light"
	stage_hint = "Jump onto the amber paths while your lantern reaches them."
	super._ready()


func _build_stage() -> void:
	_add_ground(0.0, 350.0)
	_add_light_platform(Vector2(445.0, 535.0))
	_add_light_platform(Vector2(625.0, 475.0))
	_add_light_platform(Vector2(760.0, 540.0))
	_add_ground(825.0, 1430.0)
	_add_exit(Vector2(1320.0, 584.0))

	# Ancient watchtower silhouettes framing the sunken gap
	_add_ruin_pillar(Vector2(315.0, 620.0), 150.0, 30.0, true)
	_add_ruin_pillar(Vector2(860.0, 620.0), 165.0, 32.0, true)
	_add_distant_monolith(Vector2(600.0, 650.0), 220.0, 50.0)
