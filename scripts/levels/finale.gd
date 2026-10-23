extends "res://scripts/levels/playable_level.gd"


func _ready() -> void:
	stage_index = 4
	stage_title = "The Last Wick"
	stage_subtitle = "Sanctum of the First Hearth — carry the final ember home"
	stage_hint = "Carry everything you have learned into the final crossing."
	super._ready()


func _build_stage() -> void:
	_add_ground(0.0, 350.0)
	_add_hazard(Vector2(300.0, 602.0), Vector2(90.0, 26.0))
	_add_light_platform(Vector2(430.0, 540.0))
	_add_ground(515.0, 790.0)
	_add_checkpoint(Vector2(680.0, 578.0))
	_add_hazard(Vector2(745.0, 602.0), Vector2(80.0, 26.0))
	_add_light_platform(Vector2(875.0, 525.0))
	_add_ground(960.0, 1510.0)
	_add_flare_gate(Vector2(1170.0, 490.0), Vector2(1010.0, 470.0), 400.0)
	_add_exit(Vector2(1430.0, 584.0))

	# Grand sanctuary colonnade and the Great Brazier at the finale threshold
	_add_ruin_pillar(Vector2(210.0, 620.0), 185.0, 34.0, false)
	_add_distant_monolith(Vector2(640.0, 620.0), 240.0, 48.0)
	_add_broken_arch(Vector2(875.0, 650.0), 210.0, 175.0)
	_add_ruin_pillar(Vector2(1290.0, 620.0), 220.0, 38.0, false)
	_add_finale_brazier(Vector2(1430.0, 620.0))
