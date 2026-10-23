extends PointLight2D

@export var flare_range_bonus: float = 180.0
@export var flare_scale_multiplier: float = 1.65
@export var flare_energy_multiplier: float = 1.65

var _base_scale: float
var _base_energy: float
var _flare_active: bool = false


func _ready() -> void:
	_base_scale = texture_scale
	_base_energy = energy


func set_flare_active(active: bool) -> void:
	_flare_active = active
	var multiplier := flare_scale_multiplier if active else 1.0
	texture_scale = _base_scale * multiplier
	energy = _base_energy * (flare_energy_multiplier if active else 1.0)


func get_platform_range_bonus() -> float:
	return flare_range_bonus if _flare_active else 0.0
