extends "res://scripts/levels/playable_level.gd"


func _ready() -> void:
	stage_index = 2
	stage_title = "Across the Dark"
	stage_subtitle = "The Shattered Viaduct — where the great bridge fell into the abyss"
	stage_hint = "Build a jump, then dash over the wide break."
	super._ready()


func _build_stage() -> void:
	_add_ground(0.0, 350.0)
	_add_ground(580.0, 1500.0)
	_add_checkpoint(Vector2(820.0, 578.0))
	_add_light_platform(Vector2(1030.0, 520.0))
	_add_hazard(Vector2(1190.0, 602.0), Vector2(120.0, 26.0))
	_add_exit(Vector2(1415.0, 584.0))

	# Narrative ruins framing the severed span without altering collision
	_add_ruin_pillar(Vector2(325.0, 620.0), 140.0, 32.0, true)
	_add_ruin_pillar(Vector2(605.0, 620.0), 155.0, 32.0, true)
	_add_broken_arch(Vector2(465.0, 660.0), 260.0, 190.0)
	_add_distant_monolith(Vector2(930.0, 620.0), 210.0, 44.0)
