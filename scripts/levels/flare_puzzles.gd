extends "res://scripts/levels/playable_level.gd"


func _ready() -> void:
	stage_index = 3
	stage_title = "Borrowed Flame"
	stage_subtitle = "The Astrolabe Gate — ancient seals answer only to a sudden burst of light"
	stage_hint = "A clear flare can wake a switch beyond the light platforms."
	super._ready()


func _build_stage() -> void:
	_add_ground(0.0, 430.0)
	_add_light_platform(Vector2(500.0, 545.0))
	_add_light_platform(Vector2(680.0, 500.0))
	_add_ground(765.0, 1480.0)
	_add_flare_gate(Vector2(1040.0, 490.0), Vector2(850.0, 475.0), 400.0)
	_add_checkpoint(Vector2(900.0, 578.0))
	_add_exit(Vector2(1390.0, 584.0))

	# Observatory pillars and sun-catcher framing around the astrolabe switch
	_add_ruin_pillar(Vector2(390.0, 620.0), 160.0, 30.0, true)
	_add_distant_monolith(Vector2(850.0, 620.0), 215.0, 40.0)
	_add_ruin_pillar(Vector2(1220.0, 620.0), 190.0, 34.0, false)
